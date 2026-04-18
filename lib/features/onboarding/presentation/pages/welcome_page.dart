import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/onboarding_task.dart';
import '../providers/onboarding_providers.dart';

/// Full-screen welcome shown right after registration. Previews the setup
/// steps so the user understands what's ahead, then sends them either to
/// the guided tour or straight to the dashboard.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xl),
              _HeaderIllustration(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                ref.t('onboarding.welcome.title'),
                style: context.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ref.t('onboarding.welcome.subtitle'),
                style: context.textTheme.titleSmall
                    ?.copyWith(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                ref.t('onboarding.welcome.description'),
                style: context.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: _StepsPreview(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: ref.t('onboarding.welcome.takeTour'),
                icon: Icons.auto_awesome,
                onPressed: () async {
                  await ref.read(welcomeSeenProvider.notifier).markSeen();
                  if (!context.mounted) return;
                  context.go(AppRoutes.help);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: ref.t('onboarding.welcome.exploreMyself'),
                variant: AppButtonVariant.outlined,
                onPressed: () async {
                  await ref.read(welcomeSeenProvider.notifier).markSeen();
                  if (!context.mounted) return;
                  context.go(AppRoutes.home);
                },
              ),
              TextButton(
                onPressed: () async {
                  await ref.read(welcomeSeenProvider.notifier).markSeen();
                  await ref
                      .read(onboardingDismissedProvider.notifier)
                      .setDismissed(true);
                  if (!context.mounted) return;
                  context.go(AppRoutes.home);
                },
                child: Text(ref.t('onboarding.welcome.skip')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 88,
        width: 88,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.rocket_launch_outlined,
          color: AppColors.primary,
          size: 44,
        ),
      ),
    );
  }
}

class _StepsPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      itemCount: kOnboardingTasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final task = kOnboardingTasks[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.colors.surface,
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  ref.t(task.translationKey),
                  style: context.textTheme.bodyMedium,
                ),
              ),
              Icon(task.icon, color: AppColors.gray400, size: 20),
            ],
          ),
        );
      },
    );
  }
}
