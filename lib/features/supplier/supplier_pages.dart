import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_routes.dart';
import '../../app/shell/app_drawer.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/i18n/translations_extension.dart';
import '../../core/models/named_ref.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions/context_extensions.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_scaffold.dart';
import '../auth/presentation/providers/current_user_provider.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/resource_list_scaffold.dart';
import '../onboarding/presentation/providers/onboarding_providers.dart';
import '../reference/reference_providers.dart';

class SupplierListPage extends ConsumerWidget {
  const SupplierListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResourceListScaffold(
      title: ref.t('onboarding.checklist.tasks.firstSupplier'),
      icon: Icons.local_shipping_outlined,
      listProvider: supplierListProvider,
      drawer: const AppDrawer(),
      emptyMessage: ref.t('onboarding.checklist.tasks.firstSupplier'),
      onCreate: () => context.push(AppRoutes.supplierNew),
      onItemTap: (i) => context.push('${AppRoutes.suppliers}/${i.id}/edit'),
      onItemDelete: (i) => _delete(context, ref, i),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, NamedRef item) async {
    final ok = await confirmDialog(context, title: 'Delete ${item.name}?');
    if (!ok) return;
    final r = await ref.read(catalogServiceProvider).softDelete(ApiEndpoints.supplier, item.id);
    if (!context.mounted) return;
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(supplierListProvider);
        ref.invalidate(suppliersRefProvider);
        context.showSnack(ref.t('common.done'));
      },
    );
  }
}

class SupplierFormPage extends ConsumerStatefulWidget {
  const SupplierFormPage({super.key, this.id});
  final int? id;

  @override
  ConsumerState<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends ConsumerState<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _innCtrl = TextEditingController();
  String _type = 'physical';
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
    _phoneCtrl.dispose();
    _innCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final r = await ref
        .read(catalogServiceProvider)
        .detail(ApiEndpoints.supplier, widget.id!);
    if (!mounted) return;
    r.fold(
      (f) {
        context.showSnack(f.message, error: true);
        setState(() => _loading = false);
      },
      (data) {
        _nameCtrl.text = (data['name'] ?? '').toString();
        _phoneCtrl.text = (data['phone'] ?? '').toString();
        _innCtrl.text = (data['inn'] ?? '').toString();
        _type = (data['type'] ?? 'physical').toString();
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
    final body = {
      'name': _nameCtrl.text.trim(),
      'company_id': companyId,
      'phone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      'type': _type,
      'inn': _innCtrl.text.trim(),
    };
    final catalog = ref.read(catalogServiceProvider);
    final r = _isEdit
        ? await catalog.update(ApiEndpoints.supplier, widget.id!, body)
        : await catalog.create(ApiEndpoints.supplier, body);
    if (!mounted) return;
    setState(() => _saving = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(supplierListProvider);
        ref.invalidate(suppliersRefProvider);
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
        .softDelete(ApiEndpoints.supplier, widget.id!);
    if (!mounted) return;
    setState(() => _deleting = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(supplierListProvider);
        ref.invalidate(suppliersRefProvider);
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
      title: ref.t('onboarding.checklist.tasks.firstSupplier'),
      saving: _saving,
      deleting: _deleting,
      onSubmit: _save,
      onDelete: _isEdit ? _delete : null,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: ref.t('catalog.name'),
          prefixIcon: const Icon(Icons.local_shipping_outlined),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? ref.t('validation.required')
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phoneCtrl,
          label: ref.t('register.phone'),
          hint: '998901234567',
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
          validator: (v) {
            final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
            if (digits.length != 12) return ref.t('validation.invalidPhone');
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _innCtrl,
          label: 'INN',
          prefixIcon: const Icon(Icons.numbers),
          keyboardType: TextInputType.number,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? ref.t('validation.required')
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        FormSection(label: ref.t('catalog.type'), icon: Icons.business),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'physical',
              label: Text(ref.t('register.physical')),
            ),
            ButtonSegment(
              value: 'entity',
              label: Text(ref.t('register.entity')),
            ),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
      ],
    );
  }
}
