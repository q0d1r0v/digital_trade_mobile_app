import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/shell_back_handler.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/guided_tour_sheet.dart';

/// Help & how-to screen. Groups:
/// 1. Guided tour (re-runnable, 4 steps that mirror the web SpotlightTour)
/// 2. Setup checklist shortcut
/// 3. Static docs / contact card
class HelpPage extends ConsumerWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShellBackHandler(
      child: Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(ref.t('onboarding.help.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Text(
            ref.t('onboarding.help.subtitle'),
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.lg),
          _HelpCard(
            icon: Icons.auto_awesome,
            title: ref.t('onboarding.help.restartTour'),
            onTap: () => _openTour(context),
          ),
          _HelpCard(
            icon: Icons.checklist,
            title: ref.t('onboarding.help.showChecklist'),
            onTap: () async {
              await ref
                  .read(onboardingDismissedProvider.notifier)
                  .setDismissed(false);
              if (!context.mounted) return;
              context.go(AppRoutes.home);
            },
          ),
          _HelpCard(
            icon: Icons.menu_book_outlined,
            title: ref.t('onboarding.help.docs'),
            onTap: () {}, // Deep-links to docs can be wired once URL is public.
          ),
          _HelpCard(
            icon: Icons.support_agent_outlined,
            title: ref.t('onboarding.help.contact'),
            subtitle: ref.t('onboarding.help.contactEmail'),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: ref.t('onboarding.welcome.takeTour'),
            icon: Icons.play_arrow,
            onPressed: () => _openTour(context),
          ),
        ],
      ),
      ),
    );
  }

  void _openTour(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GuidedTourSheet(),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray200),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: context.textTheme.bodySmall
                              ?.copyWith(color: AppColors.gray500),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.gray400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
