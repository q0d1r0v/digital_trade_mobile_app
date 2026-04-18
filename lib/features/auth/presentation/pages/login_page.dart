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
import '../providers/login_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginControllerProvider.notifier).submit(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
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
    ref.listen(loginControllerProvider, (_, next) {
      if (next is LoginError) {
        context.showSnack(next.failure.message, error: true);
      }
    });

    final state = ref.watch(loginControllerProvider);
    final isLoading = state is LoginLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Brand(),
                  const SizedBox(height: AppSpacing.huge),
                  Text(
                    ref.t('login.title'),
                    style: context.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    ref.t('login.subtitle'),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppTextField(
                    controller: _emailCtrl,
                    label: ref.t('login.email'),
                    hint: ref.t('login.emailHint'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(Icons.mail_outline),
                    validator: (v) => _mapValidation(Validators.email(v)),
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: _passwordCtrl,
                    label: ref.t('login.password'),
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    onSubmitted: (_) => _submit(),
                    validator: (v) => _mapValidation(Validators.password(v)),
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  AppButton(
                    label: ref.t('login.submit'),
                    onPressed: _submit,
                    loading: isLoading,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(ref.t('login.noAccount')),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: Text(ref.t('login.register')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: const Icon(
            Icons.storefront_outlined,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Digital Trade',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}
