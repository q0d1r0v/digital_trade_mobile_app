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
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/form_scaffold.dart';
import '../auth/presentation/providers/current_user_provider.dart';
import '../catalog/catalog_providers.dart';
import '../catalog/widgets/resource_list_scaffold.dart';
import '../invoices/presentation/widgets/ref_dropdown.dart';
import '../onboarding/presentation/providers/onboarding_providers.dart';
import '../reference/reference_providers.dart';

class TeamListPage extends ConsumerWidget {
  const TeamListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResourceListScaffold(
      title: ref.t('onboarding.checklist.tasks.inviteTeam'),
      icon: Icons.group_outlined,
      listProvider: userListProvider,
      drawer: const AppDrawer(),
      emptyMessage: ref.t('onboarding.checklist.tasks.inviteTeam'),
      onCreate: () => context.push(AppRoutes.teamInvite),
      onItemTap: (i) => context.push('${AppRoutes.teamMembers}/${i.id}/edit'),
      onItemDelete: (i) => _delete(context, ref, i),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, NamedRef item) async {
    final ok = await confirmDialog(context, title: 'Delete ${item.name}?');
    if (!ok) return;
    final r = await ref.read(catalogServiceProvider).softDelete(ApiEndpoints.companyUser, item.id);
    if (!context.mounted) return;
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(userListProvider);
        context.showSnack(ref.t('common.done'));
      },
    );
  }
}

class TeamFormPage extends ConsumerStatefulWidget {
  const TeamFormPage({super.key, this.id});
  final int? id;

  @override
  ConsumerState<TeamFormPage> createState() => _TeamFormPageState();
}

class _TeamFormPageState extends ConsumerState<TeamFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'male';
  NamedRef? _role;
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final r = await ref
        .read(catalogServiceProvider)
        .detail(ApiEndpoints.companyUser, widget.id!);
    if (!mounted) return;
    r.fold(
      (f) {
        context.showSnack(f.message, error: true);
        setState(() => _loading = false);
      },
      (data) {
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        _emailCtrl.text = (data['email'] ?? '').toString();
        _fullNameCtrl.text = (profile['full_name'] ?? '').toString();
        _phoneCtrl.text = (profile['phone'] ?? '').toString();
        _gender = (profile['gender'] ?? 'male').toString();
        final roleId = (data['role_id'] ?? data['role']?['id']) as num?;
        final roleName = (data['role']?['name'] ?? '').toString();
        if (roleId != null) {
          _role = NamedRef(id: roleId.toInt(), name: roleName);
        }
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_role == null) {
      context.showSnack(ref.t('validation.required'), error: true);
      return;
    }
    final user = ref.read(currentUserProvider).value;
    final companyId = int.tryParse(user?.companyId ?? '');
    if (companyId == null) return;

    setState(() => _saving = true);
    final body = <String, dynamic>{
      'email': _emailCtrl.text.trim(),
      if (!_isEdit || _passwordCtrl.text.isNotEmpty)
        'password': _passwordCtrl.text,
      'role_id': _role!.id,
      'company_id': companyId,
      'type': 'employee',
      'profile': {
        'full_name': _fullNameCtrl.text.trim(),
        'gender': _gender,
        if (_phoneCtrl.text.trim().isNotEmpty)
          'phone': _phoneCtrl.text.replaceAll(RegExp(r'\D'), ''),
      },
    };
    final catalog = ref.read(catalogServiceProvider);
    final r = _isEdit
        ? await catalog.update(ApiEndpoints.companyUser, widget.id!, body)
        : await catalog.create(ApiEndpoints.companyUser, body);
    if (!mounted) return;
    setState(() => _saving = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(userListProvider);
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
        .softDelete(ApiEndpoints.companyUser, widget.id!);
    if (!mounted) return;
    setState(() => _deleting = false);
    r.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(userListProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }

  String? _mapValidation(String? code) {
    if (code == null) return null;
    final mapping = <String, String>{
      'required': 'validation.required',
      'invalid_email': 'validation.invalidEmail',
      'min_length_6': 'validation.minLength6',
    };
    return ref.t(mapping[code] ?? 'validation.required');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final rolesAsync = ref.watch(rolesProvider);
    return FormScaffold(
      formKey: _formKey,
      title: ref.t('onboarding.checklist.tasks.inviteTeam'),
      saving: _saving,
      deleting: _deleting,
      onSubmit: _save,
      onDelete: _isEdit ? _delete : null,
      children: [
        AppTextField(
          controller: _fullNameCtrl,
          label: ref.t('register.fullName'),
          prefixIcon: const Icon(Icons.person_outline),
          validator: (v) => _mapValidation(Validators.required(v)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _emailCtrl,
          label: ref.t('register.email'),
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline),
          validator: (v) => _mapValidation(Validators.email(v)),
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _passwordCtrl,
          label: _isEdit
              ? '${ref.t('register.password')} (empty = unchanged)'
              : ref.t('register.password'),
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
          validator: (v) {
            if (_isEdit && (v == null || v.isEmpty)) return null;
            return _mapValidation(Validators.password(v));
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phoneCtrl,
          label: ref.t('register.phone'),
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.phone_outlined),
        ),
        const SizedBox(height: AppSpacing.md),
        FormSection(label: ref.t('catalog.gender')),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'male',
              label: Text(ref.t('register.male')),
            ),
            ButtonSegment(
              value: 'female',
              label: Text(ref.t('register.female')),
            ),
          ],
          selected: {_gender},
          onSelectionChanged: (s) => setState(() => _gender = s.first),
        ),
        const SizedBox(height: AppSpacing.md),
        RefDropdown(
          label: ref.t('catalog.role'),
          value: _role,
          icon: Icons.shield_outlined,
          async: rolesAsync,
          onChanged: (v) => setState(() => _role = v),
        ),
      ],
    );
  }
}
