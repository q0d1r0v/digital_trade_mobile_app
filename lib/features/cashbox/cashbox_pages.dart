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
import '../onboarding/presentation/providers/onboarding_providers.dart';
import '../reference/reference_providers.dart';

class CashboxListPage extends ConsumerWidget {
  const CashboxListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResourceListScaffold(
      title: ref.t('onboarding.checklist.tasks.firstCashbox'),
      icon: Icons.point_of_sale_outlined,
      listProvider: cashboxListProvider,
      drawer: const AppDrawer(),
      emptyMessage: ref.t('onboarding.checklist.tasks.firstCashbox'),
      onCreate: () => context.push(AppRoutes.cashboxNew),
      onItemTap: (item) =>
          context.push('${AppRoutes.cashboxes}/${item.id}/edit'),
      onItemDelete: (item) => _delete(context, ref, item),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    NamedRef item,
  ) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Delete ${item.name}?',
    );
    if (!confirmed) return;
    final result =
        await ref.read(catalogServiceProvider).softDelete(ApiEndpoints.cashbox, item.id);
    if (!context.mounted) return;
    result.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(cashboxListProvider);
        ref.invalidate(cashboxesRefProvider);
        ref.invalidate(onboardingProgressProvider);
        ref.invalidate(currentUserProvider);
        context.showSnack(ref.t('common.done'));
      },
    );
  }
}

/// Dual-mode page — `id` null → create, id set → edit + delete.
class CashboxFormPage extends ConsumerStatefulWidget {
  const CashboxFormPage({super.key, this.id});
  final int? id;

  @override
  ConsumerState<CashboxFormPage> createState() => _CashboxFormPageState();
}

class _CashboxFormPageState extends ConsumerState<CashboxFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  // `main` cashboxes are created once per company at registration; only
  // `sale` cashboxes are user-creatable. Keeping the field private (not
  // a picker) removes an entire class of backend errors
  // (`cashbox.errors.main_cashbox_exists`) and matches how the web UI
  // treats this screen.
  static const String _type = 'sale';
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
    final result =
        await ref.read(catalogServiceProvider).detail(ApiEndpoints.cashbox, widget.id!);
    if (!mounted) return;
    result.fold(
      (f) {
        context.showSnack(f.message, error: true);
        setState(() => _loading = false);
      },
      (data) {
        _nameCtrl.text = (data['name'] ?? '').toString();
        // Type is fixed to `sale` for user-created cashboxes (main is
        // created once per company at registration), so we don't reflect
        // the loaded type into state.
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
      'type': _type,
      'status': 'active',
    };
    final catalog = ref.read(catalogServiceProvider);
    final result = _isEdit
        ? await catalog.update(ApiEndpoints.cashbox, widget.id!, body)
        : await catalog.create(ApiEndpoints.cashbox, body);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(cashboxListProvider);
        ref.invalidate(cashboxesRefProvider);
        ref.invalidate(onboardingProgressProvider);
        ref.invalidate(currentUserProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }

  Future<void> _delete() async {
    if (!_isEdit) return;
    final confirmed = await confirmDialog(
      context,
      title: 'Delete?',
    );
    if (!confirmed) return;
    setState(() => _deleting = true);
    final result =
        await ref.read(catalogServiceProvider).softDelete(ApiEndpoints.cashbox, widget.id!);
    if (!mounted) return;
    setState(() => _deleting = false);
    result.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(cashboxListProvider);
        ref.invalidate(cashboxesRefProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return FormScaffold(
      formKey: _formKey,
      title: ref.t('onboarding.checklist.tasks.firstCashbox'),
      saving: _saving,
      deleting: _deleting,
      onSubmit: _save,
      onDelete: _isEdit ? _delete : null,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: ref.t('catalog.name'),
          prefixIcon: const Icon(Icons.label_outline),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? ref.t('validation.required')
              : null,
        ),
      ],
    );
  }
}
