import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/injection.dart';
import '../../core/i18n/translations_extension.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions/context_extensions.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/form_scaffold.dart';
import '../auth/presentation/providers/current_user_provider.dart';
import '../onboarding/presentation/providers/onboarding_providers.dart';
import 'company_service.dart';

final companyServiceProvider = Provider<CompanyService>((ref) => sl());

class CompanyEditPage extends ConsumerStatefulWidget {
  const CompanyEditPage({super.key});

  @override
  ConsumerState<CompanyEditPage> createState() => _CompanyEditPageState();
}

class _CompanyEditPageState extends ConsumerState<CompanyEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _nameCtrl = TextEditingController(text: user?.companyName ?? '');
    _companyNameCtrl = TextEditingController(text: user?.companyName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _addressCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    final companyId = int.tryParse(user?.companyId ?? '');
    if (companyId == null) {
      context.showSnack(ref.t('common.error'), error: true);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(companyServiceProvider).updateCompany(
          id: companyId,
          name: _nameCtrl.text.trim(),
          companyName: _companyNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => context.showSnack(failure.message, error: true),
      (_) {
        ref.invalidate(currentUserProvider);
        ref.invalidate(onboardingProgressProvider);
        ref.invalidate(currentUserProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? ref.t('validation.required') : null;

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      formKey: _formKey,
      title: ref.t('register.companyInfo'),
      saving: _saving,
      onSubmit: _save,
      children: [
        AppTextField(
          controller: _nameCtrl,
          label: ref.t('register.companyName'),
          prefixIcon: const Icon(Icons.apartment_outlined),
          textInputAction: TextInputAction.next,
          validator: _required,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _companyNameCtrl,
          label: ref.t('register.companyUniqueName'),
          prefixIcon: const Icon(Icons.tag),
          textInputAction: TextInputAction.next,
          validator: _required,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _phoneCtrl,
          label: ref.t('register.phone'),
          prefixIcon: const Icon(Icons.phone_outlined),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: _required,
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          controller: _addressCtrl,
          label: ref.t('register.address'),
          prefixIcon: const Icon(Icons.place_outlined),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          validator: _required,
        ),
      ],
    );
  }
}
