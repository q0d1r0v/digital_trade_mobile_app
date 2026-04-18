import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/constants/api_endpoints.dart';
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
import '../../../reference/reference_providers.dart';

class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResourceListScaffold(
      title: ref.t('nav.clients'),
      icon: Icons.people_outline,
      listProvider: clientListProvider,
      drawer: const AppDrawer(),
      emptyMessage: ref.t('nav.clients'),
      onCreate: () => context.push(AppRoutes.clientNew),
      onItemTap: (i) => context.push('${AppRoutes.clients}/${i.id}/edit'),
      onItemDelete: (i) => _delete(context, ref, i),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, NamedRef item) async {
    final ok = await confirmDialog(context, title: 'Delete ${item.name}?');
    if (!ok) return;
    final r = await ref.read(catalogServiceProvider).softDelete(ApiEndpoints.client, item.id);
    if (!context.mounted) return;
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(clientListProvider);
        ref.invalidate(clientsRefProvider);
        context.showSnack(ref.t('common.done'));
      },
    );
  }
}

class ClientFormPage extends ConsumerStatefulWidget {
  const ClientFormPage({super.key, this.id});
  final int? id;

  @override
  ConsumerState<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends ConsumerState<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
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
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final r = await ref
        .read(catalogServiceProvider)
        .detail(ApiEndpoints.client, widget.id!);
    if (!mounted) return;
    r.fold(
      (f) {
        context.showSnack(f.message, error: true);
        setState(() => _loading = false);
      },
      (data) {
        _nameCtrl.text = (data['name'] ?? '').toString();
        _phoneCtrl.text = (data['phone'] ?? '').toString();
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
      if (_phoneCtrl.text.trim().isNotEmpty)
        'phone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
    };
    final catalog = ref.read(catalogServiceProvider);
    final r = _isEdit
        ? await catalog.update(ApiEndpoints.client, widget.id!, body)
        : await catalog.create(ApiEndpoints.client, body);
    if (!mounted) return;
    setState(() => _saving = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(clientListProvider);
        ref.invalidate(clientsRefProvider);
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
        .softDelete(ApiEndpoints.client, widget.id!);
    if (!mounted) return;
    setState(() => _deleting = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(clientListProvider);
        ref.invalidate(clientsRefProvider);
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
      title: ref.t('nav.clients'),
      saving: _saving,
      deleting: _deleting,
      onSubmit: _save,
      onDelete: _isEdit ? _delete : null,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: ref.t('register.fullName'),
          prefixIcon: const Icon(Icons.person_outline),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? ref.t('validation.required')
              : null,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phoneCtrl,
          label: ref.t('register.phone'),
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
      ],
    );
  }
}
