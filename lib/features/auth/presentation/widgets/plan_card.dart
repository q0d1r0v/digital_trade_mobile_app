import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../plans/domain/entities/plan_entity.dart';

/// Selectable plan card used on the register screen. Content is driven by
/// i18n keys (`plans.<type>.*`) so prices/features stay in sync with the
/// web frontend without duplicating copy across clients.
class PlanCard extends ConsumerWidget {
  const PlanCard({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final PlanType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = switch (type) {
      PlanType.starter => 'starter',
      PlanType.business => 'business',
      PlanType.enterprise => 'enterprise',
    };
    final name = ref.t('plans.$key.name');
    final tagline = ref.t('plans.$key.tagline');
    final features = [
      ref.t('plans.$key.feature1'),
      ref.t('plans.$key.feature2'),
      ref.t('plans.$key.feature3'),
    ];
    final priceLabel = switch (type) {
      PlanType.starter => ref.t('register.free'),
      PlanType.business =>
        ref.t('pricing.perMonth', params: const {'amount': '290 000'}),
      PlanType.enterprise => ref.t('plans.enterprise.contact'),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : context.colors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: context.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (type == PlanType.business) ...[
                            const SizedBox(width: AppSpacing.sm),
                            _Chip(label: 'PRO'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tagline,
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: AppColors.gray500),
                      ),
                    ],
                  ),
                ),
                _SelectIndicator(selected: selected),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              priceLabel,
              style: context.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final f in features)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        f,
                        style: context.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SelectIndicator extends StatelessWidget {
  const _SelectIndicator({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.gray300,
          width: 2,
        ),
        color: selected ? AppColors.primary : Colors.transparent,
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
