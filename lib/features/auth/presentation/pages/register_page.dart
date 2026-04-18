import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../plans/domain/entities/plan_entity.dart';
import '../../../plans/presentation/providers/plans_providers.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/register_controller.dart';
import '../widgets/plan_card.dart';

/// Registration screen — single page with an inline plan picker so mobile
/// matches the web UX. Plan selection is sent with the POST /register call
/// as `plan_type`, after which the backend auto-logs-in the user.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _companyUniqueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _gender = 'male';
  String _companyType = 'physical';
  PlanType _plan = PlanType.starter;
  bool _obscure = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _companyNameCtrl.dispose();
    _companyUniqueCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(registerControllerProvider.notifier).submit(
          RegisterParams(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            fullName: _fullNameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            gender: _gender,
            companyName: _companyNameCtrl.text.trim(),
            companyUniqueName: _companyUniqueCtrl.text.trim().toLowerCase(),
            companyType: _companyType,
            address: _addressCtrl.text.trim(),
            planType: _plan.apiValue,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registerControllerProvider, (_, next) {
      if (next is RegisterError) {
        context.showSnack(next.failure.message, error: true);
      }
      if (next is RegisterSuccess) {
        // Reset onboarding so the welcome modal shows for the new user.
        context.goNamed(AppRoutes.nameWelcome);
      }
    });

    final state = ref.watch(registerControllerProvider);
    final isLoading = state is RegisterLoading;
    final plansAsync = ref.watch(plansListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.t('register.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.safePop()
              : context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            children: [
              Text(
                ref.t('register.subtitle'),
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.gray500),
              ),
              const SizedBox(height: AppSpacing.xl),
              _PlanPickerSection(
                selected: _plan,
                plansAsync: plansAsync,
                onChanged: (p) => setState(() => _plan = p),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppTextField(
                controller: _fullNameCtrl,
                label: ref.t('register.fullName'),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline),
                validator: _requiredValidator,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _emailCtrl,
                label: ref.t('register.email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.mail_outline),
                validator: (v) => _mapValidation(Validators.email(v)),
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _phoneCtrl,
                label: ref.t('register.phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: (v) => _mapValidation(Validators.phone(v)),
                autofillHints: const [AutofillHints.telephoneNumber],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passwordCtrl,
                label: ref.t('register.password'),
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                validator: (v) => _mapValidation(Validators.password(v)),
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: AppSpacing.md),
              _GenderSelector(
                value: _gender,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SectionHeader(label: ref.t('register.companyInfo')),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _companyNameCtrl,
                label: ref.t('register.companyName'),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.apartment_outlined),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _companyUniqueCtrl,
                label: ref.t('register.companyUniqueName'),
                hint: ref.t('register.uniqueNameHint'),
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.tag),
                validator: _requiredValidator,
              ),
              const SizedBox(height: AppSpacing.md),
              _CompanyTypeSelector(
                value: _companyType,
                onChanged: (v) => setState(() => _companyType = v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _addressCtrl,
                label: ref.t('register.address'),
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.place_outlined),
                validator: _requiredValidator,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AppButton(
                label: ref.t('register.submit'),
                onPressed: _submit,
                loading: isLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              _LoginCta(),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? v) => _mapValidation(Validators.required(v));

  String? _mapValidation(String? code) {
    if (code == null) return null;
    final mapping = <String, String>{
      'required': 'validation.required',
      'invalid_email': 'validation.invalidEmail',
      'invalid_phone': 'validation.invalidPhone',
      'min_length_6': 'validation.minLength6',
    };
    return ref.t(mapping[code] ?? 'validation.required');
  }
}

class _PlanPickerSection extends ConsumerWidget {
  const _PlanPickerSection({
    required this.selected,
    required this.plansAsync,
    required this.onChanged,
  });

  final PlanType selected;
  final AsyncValue<List<PlanEntity>> plansAsync;
  final ValueChanged<PlanType> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.t('register.selectPlanTitle'),
          style: context.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          ref.t('register.selectPlanSubtitle'),
          style: context.textTheme.bodySmall
              ?.copyWith(color: AppColors.gray500),
        ),
        const SizedBox(height: AppSpacing.md),
        plansAsync.when(
          data: (_) => _cards(ref),
          loading: () => _cards(ref),
          error: (_, _) => _cards(ref),
        ),
      ],
    );
  }

  Widget _cards(WidgetRef ref) {
    return Column(
      children: [
        PlanCard(
          type: PlanType.starter,
          selected: selected == PlanType.starter,
          onTap: () => onChanged(PlanType.starter),
        ),
        const SizedBox(height: AppSpacing.sm),
        PlanCard(
          type: PlanType.business,
          selected: selected == PlanType.business,
          onTap: () => onChanged(PlanType.business),
        ),
      ],
    );
  }
}

class _GenderSelector extends ConsumerWidget {
  const _GenderSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _SegmentButton(
            label: ref.t('register.male'),
            selected: value == 'male',
            onTap: () => onChanged('male'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SegmentButton(
            label: ref.t('register.female'),
            selected: value == 'female',
            onTap: () => onChanged('female'),
          ),
        ),
      ],
    );
  }
}

class _CompanyTypeSelector extends ConsumerWidget {
  const _CompanyTypeSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _SegmentButton(
            label: ref.t('register.physical'),
            selected: value == 'physical',
            onTap: () => onChanged('physical'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SegmentButton(
            label: ref.t('register.entity'),
            selected: value == 'legal',
            onTap: () => onChanged('legal'),
          ),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray300,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : context.colors.onSurface,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 3,
          width: 24,
          color: AppColors.primary,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
        ),
        Text(
          label,
          style: context.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _LoginCta extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          ref.t('register.haveAccount'),
          style: context.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: Text(ref.t('register.login')),
        ),
      ],
    );
  }
}
