import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/shell/app_drawer.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/i18n/translations_extension.dart';
import '../../core/models/named_ref.dart';
import '../../core/utils/extensions/context_extensions.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_scaffold.dart';
import '../auth/presentation/providers/current_user_provider.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/resource_list_scaffold.dart';
import '../reference/reference_providers.dart';

class BrandListPage extends ConsumerWidget {
  const BrandListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResourceListScaffold(
      title: 'Brands',
      icon: Icons.branding_watermark_outlined,
      listProvider: brandListProvider,
      drawer: const AppDrawer(),
      emptyMessage: 'Brands',
      onCreate: () => context.push(AppRoutes.brandNew),
      onItemTap: (i) => context.push('${AppRoutes.brands}/${i.id}/edit'),
      onItemDelete: (i) => _delete(context, ref, i),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, NamedRef item) async {
    final ok = await confirmDialog(context, title: 'Delete ${item.name}?');
    if (!ok) return;
    final r = await ref.read(catalogServiceProvider).softDelete(ApiEndpoints.brand, item.id);
    if (!context.mounted) return;
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(brandListProvider);
        ref.invalidate(brandsRefProvider);
        context.showSnack(ref.t('common.done'));
      },
    );
  }
}

class BrandFormPage extends ConsumerStatefulWidget {
  const BrandFormPage({super.key, this.id});
  final int? id;

  @override
  ConsumerState<BrandFormPage> createState() => _BrandFormPageState();
}

class _BrandFormPageState extends ConsumerState<BrandFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
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
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final r = await ref
        .read(catalogServiceProvider)
        .detail(ApiEndpoints.brand, widget.id!);
    if (!mounted) return;
    r.fold(
      (f) {
        context.showSnack(f.message, error: true);
        setState(() => _loading = false);
      },
      (data) {
        _nameCtrl.text = (data['name'] ?? '').toString();
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    final companyId = int.tryParse(user?.companyId ?? '');
    if (companyId == null) return;

    setState(() => _saving = true);
    final body = {'name': _nameCtrl.text.trim(), 'company_id': companyId};
    final catalog = ref.read(catalogServiceProvider);
    final r = _isEdit
        ? await catalog.update(ApiEndpoints.brand, widget.id!, body)
        : await catalog.create(ApiEndpoints.brand, body);
    if (!mounted) return;
    setState(() => _saving = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(brandListProvider);
        ref.invalidate(brandsRefProvider);
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
        .softDelete(ApiEndpoints.brand, widget.id!);
    if (!mounted) return;
    setState(() => _deleting = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(brandListProvider);
        ref.invalidate(brandsRefProvider);
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
    return FormScaffold(
      formKey: _formKey,
      title: 'Brand',
      saving: _saving,
      deleting: _deleting,
      onSubmit: _save,
      onDelete: _isEdit ? _delete : null,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: ref.t('catalog.name'),
          prefixIcon: const Icon(Icons.branding_watermark_outlined),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? ref.t('validation.required')
              : null,
        ),
      ],
    );
  }
}
