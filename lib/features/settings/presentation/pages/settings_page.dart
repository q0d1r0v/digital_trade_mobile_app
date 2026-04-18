import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/widgets/shell_back_handler.dart';
import '../../../../core/i18n/app_locale.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/usecase.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final locale = ref.watch(localeControllerProvider);

    return ShellBackHandler(
      child: Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: Text(ref.t('settings.title'))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (user != null) ...[
            _AccountCard(
              name: user.fullName,
              email: user.email,
              company: user.companyName,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _SectionLabel(text: ref.t('settings.language')),
          const SizedBox(height: AppSpacing.sm),
          RadioGroup<AppLocale>(
            groupValue: locale,
            onChanged: (v) {
              if (v != null) {
                ref.read(localeControllerProvider.notifier).set(v);
              }
            },
            child: Column(
              children: [
                for (final l in AppLocale.values)
                  RadioListTile<AppLocale>(
                    value: l,
                    title: Text('${l.flag}  ${l.displayName}'),
                    dense: true,
                  ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.xxl),
          _SectionLabel(text: ref.t('settings.help')),
          ListTile(
            leading: const Icon(Icons.help_outline, color: AppColors.primary),
            title: Text(ref.t('onboarding.help.title')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.help),
          ),
          const Divider(height: AppSpacing.xxl),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.danger),
            title: Text(
              ref.t('settings.logout'),
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        content: Text(ref.t('auth.logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(ref.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(ref.t('settings.logout')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Reset onboarding first so next account sees the welcome flow.
    await ref.read(welcomeSeenProvider.notifier).reset();
    await ref.read(logoutUseCaseProvider)(const NoParams());
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.email,
    this.company,
  });
  final String name;
  final String email;
  final String? company;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  email,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: AppColors.gray500),
                ),
                if (company != null)
                  Text(
                    company!,
                    style: context.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: context.textTheme.labelMedium?.copyWith(
          color: AppColors.gray500,
          letterSpacing: 0.5,
          fontWeight: FontWeight.w600,
        ),
      );
}
