import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/models/named_ref.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/form_scaffold.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../catalog/widgets/resource_list_scaffold.dart';
import '../../../invoices/presentation/widgets/ref_dropdown.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../reference/reference_providers.dart';
import '../../data/product_service.dart';
import '../widgets/product_image_picker.dart';

final productServiceProvider = Provider<ProductService>((ref) => sl());

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResourceListScaffold(
      title: ref.t('nav.products'),
      icon: Icons.inventory_2_outlined,
      listProvider: productListProvider,
      drawer: const AppDrawer(),
      emptyMessage: ref.t('onboarding.checklist.tasks.firstProduct'),
      onCreate: () => context.push(AppRoutes.productNew),
      onItemTap: (i) => context.push('${AppRoutes.products}/${i.id}/edit'),
      onItemDelete: (i) => _delete(context, ref, i),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, NamedRef item) async {
    final ok = await confirmDialog(context, title: 'Delete ${item.name}?');
    if (!ok) return;
    final r = await ref
        .read(catalogServiceProvider)
        .softDelete(ApiEndpoints.product, item.id);
    if (!context.mounted) return;
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(productListProvider);
        ref.invalidate(productsRefProvider);
        context.showSnack(ref.t('common.done'));
      },
    );
  }
}

/// Full-parity product form — matches the web version:
///   - name, code, category, brand, unit, description
///   - image gallery (multipart)
///
/// Variations are created on the web via a separate screen; here we
/// only expose a notice that directs users to the web for that path.
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.id});
  final int? id;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  NamedRef? _category;
  NamedRef? _brand;
  NamedRef? _unit;
  final List<XFile> _localImages = [];
  final List<RemoteProductImage> _remoteImages = [];

  bool _saving = false;
  bool _deleting = false;
  bool _loading = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadDetail();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final r = await ref
        .read(catalogServiceProvider)
        .detail(ApiEndpoints.product, widget.id!);
    if (!mounted) return;
    r.fold(
      (f) {
        context.showSnack(f.message, error: true);
        setState(() => _loading = false);
      },
      (data) {
        _nameCtrl.text = (data['name'] ?? '').toString();
        _codeCtrl.text = (data['code'] ?? '').toString();
        _descCtrl.text = (data['description'] ?? '').toString();

        final category = data['category'] as Map<String, dynamic>?;
        final unit = data['unit'] as Map<String, dynamic>?;
        final brand = data['brand'] as Map<String, dynamic>?;
        final categoryId = (data['category_id'] ?? category?['id']) as num?;
        final unitId = (data['unit_id'] ?? unit?['id']) as num?;
        final brandId = (data['brand_id'] ?? brand?['id']) as num?;
        if (categoryId != null) {
          _category = NamedRef(
            id: categoryId.toInt(),
            name: (category?['name'] ?? '').toString(),
          );
        }
        if (unitId != null) {
          _unit = NamedRef(
            id: unitId.toInt(),
            name: (unit?['name'] ?? '').toString(),
          );
        }
        if (brandId != null) {
          _brand = NamedRef(
            id: brandId.toInt(),
            name: (brand?['name'] ?? '').toString(),
          );
        }

        // Existing images — backend exposes `images: [{id, path}]`. Any
        // other shape is ignored rather than crashing the screen.
        final images = data['images'];
        if (images is List) {
          for (final img in images) {
            if (img is! Map<String, dynamic>) continue;
            final idV = img['id'];
            final path = (img['path'] ?? img['url'] ?? '').toString();
            if (idV is num && path.isNotEmpty) {
              _remoteImages.add(
                RemoteProductImage(
                  id: idV.toInt(),
                  url: path.startsWith('http')
                      ? path
                      : '${FlavorConfig.instance.apiFileUrl}/$path',
                ),
              );
            }
          }
        }
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _unit == null) {
      context.showSnack(ref.t('validation.required'), error: true);
      return;
    }
    final user = ref.read(currentUserProvider).value;
    final companyId = int.tryParse(user?.companyId ?? '');
    if (companyId == null) return;

    setState(() => _saving = true);
    final product = ref.read(productServiceProvider);
    final r = _isEdit
        ? await product.update(
            id: widget.id!,
            companyId: companyId,
            name: _nameCtrl.text.trim(),
            categoryId: _category!.id,
            unitId: _unit!.id,
            code: _codeCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            brandId: _brand?.id,
            newImages: _localImages,
          )
        : await product.create(
            companyId: companyId,
            name: _nameCtrl.text.trim(),
            categoryId: _category!.id,
            unitId: _unit!.id,
            code: _codeCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            brandId: _brand?.id,
            images: _localImages,
          );
    if (!mounted) return;
    setState(() => _saving = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(productListProvider);
        ref.invalidate(productsRefProvider);
        ref.invalidate(onboardingProgressProvider);
        ref.invalidate(currentUserProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }

  Future<void> _delete() async {
    if (!_isEdit) return;
    final ok = await confirmDialog(context, title: 'Delete?');
    if (!ok) return;
    setState(() => _deleting = true);
    final r = await ref
        .read(catalogServiceProvider)
        .softDelete(ApiEndpoints.product, widget.id!);
    if (!mounted) return;
    setState(() => _deleting = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(productListProvider);
        ref.invalidate(productsRefProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final categoriesAsync = ref.watch(categoriesRefProvider);
    final brandsAsync = ref.watch(brandsRefProvider);
    final unitsAsync = ref.watch(productUnitsProvider);

    return FormScaffold(
      formKey: _formKey,
      title: ref.t('onboarding.checklist.tasks.firstProduct'),
      saving: _saving,
      deleting: _deleting,
      onSubmit: _save,
      onDelete: _isEdit ? _delete : null,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: ref.t('catalog.productName'),
          prefixIcon: const Icon(Icons.inventory_2_outlined),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? ref.t('validation.required')
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _codeCtrl,
          label: ref.t('catalog.code'),
          prefixIcon: const Icon(Icons.qr_code),
        ),
        const SizedBox(height: AppSpacing.md),
        RefDropdown(
          label: ref.t('catalog.category'),
          value: _category,
          icon: Icons.category_outlined,
          async: categoriesAsync,
          onCreateRoute: AppRoutes.categoryNew,
          onChanged: (v) => setState(() => _category = v),
        ),
        const SizedBox(height: AppSpacing.md),
        RefDropdown(
          label: ref.t('catalog.brand'),
          value: _brand,
          icon: Icons.branding_watermark_outlined,
          async: brandsAsync,
          onCreateRoute: AppRoutes.brandNew,
          optional: true,
          onChanged: (v) => setState(() => _brand = v),
        ),
        const SizedBox(height: AppSpacing.md),
        RefDropdown(
          label: ref.t('catalog.unit'),
          value: _unit,
          icon: Icons.straighten,
          async: unitsAsync,
          onChanged: (v) => setState(() => _unit = v),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _descCtrl,
          label: ref.t('catalog.description'),
          prefixIcon: const Icon(Icons.notes),
          maxLines: 4,
        ),
        const SizedBox(height: AppSpacing.md),
        FormSection(
          label: ref.t('catalog.productImages'),
          icon: Icons.image_outlined,
        ),
        ProductImagePicker(
          localImages: _localImages,
          remoteImages: _remoteImages,
          onChanged: (list) => setState(() {
            _localImages
              ..clear()
              ..addAll(list);
          }),
          onRemoveRemote: (removedId) => setState(() {
            _remoteImages.removeWhere((img) => img.id == removedId);
          }),
        ),
      ],
    );
  }
}
