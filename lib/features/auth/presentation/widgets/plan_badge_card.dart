import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../plans/presentation/widgets/plans_info_sheet.dart';
import '../providers/current_user_provider.dart';

/// Compact card that surfaces the active plan + the limits that matter
/// on mobile (products / users / cashboxes). Renders nothing while the
/// user is still loading so the dashboard stays clean on first paint.
class PlanBadgeCard extends ConsumerWidget {
  const PlanBadgeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final plan = user?.planLimits;
    if (plan == null) return const SizedBox.shrink();

    final accent = _accentForTier(plan.planType);

    return InkWell(
      onTap: () => PlansInfoSheet.show(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withValues(alpha: 0.12),
              accent.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  plan.planName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                _iconForTier(plan.planType),
                color: accent,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Backend usage keys are the bare resource names
          // (`products`, `cashboxes`, `users` — no `max_` prefix). See
          // `auth-user.service.ts:205`. Previously we queried
          // `max_products` etc. which always resolved to 0, making the
          // limit card look frozen at "0 / N" even after the user
          // created resources.
          _LimitRow(
            icon: Icons.inventory_2_outlined,
            label: ref.t('nav.products'),
            used: plan.usage['products'] ?? 0,
            limit: plan.maxProducts,
          ),
          const SizedBox(height: 6),
          _LimitRow(
            icon: Icons.point_of_sale_outlined,
            label: ref.t('nav.cashboxes'),
            used: plan.usage['cashboxes'] ?? 0,
            limit: plan.maxCashboxes,
          ),
          const SizedBox(height: 6),
          _LimitRow(
            icon: Icons.group_outlined,
            label: ref.t('nav.team'),
            used: plan.usage['users'] ?? 1,
            limit: plan.maxUsers,
          ),
        ],
      ),
      ),
    );
  }

  Color _accentForTier(String tier) => switch (tier) {
        'business' => AppColors.primary,
        'enterprise' => AppColors.warning,
        _ => AppColors.gray600,
      };

  IconData _iconForTier(String tier) => switch (tier) {
        'business' => Icons.workspace_premium,
        'enterprise' => Icons.diamond_outlined,
        _ => Icons.spa_outlined,
      };
}

class _LimitRow extends StatelessWidget {
  const _LimitRow({
    required this.icon,
    required this.label,
    required this.used,
    required this.limit,
  });

  final IconData icon;
  final String label;
  final int used;

  /// `-1` → unlimited.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final unlimited = limit == -1;
    final displayLimit = unlimited ? '∞' : '$limit';
    final ratio = unlimited || limit == 0 ? 0.0 : (used / limit).clamp(0, 1);
    final nearLimit = !unlimited && ratio >= 0.8;

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodySmall,
          ),
        ),
        Text(
          '$used / $displayLimit',
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: nearLimit ? AppColors.warning : null,
          ),
        ),
      ],
    );
  }
}
