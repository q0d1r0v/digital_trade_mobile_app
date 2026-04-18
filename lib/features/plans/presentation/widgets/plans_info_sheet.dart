import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/entities/plan_entity.dart';
import '../providers/plans_providers.dart';

/// Bottom-sheet with every plan the backend offers. Tapping any card
/// shows a short description + a clear "contact admin to upgrade"
/// message — switching plans from the mobile client is intentionally
/// not a self-service flow.
///
/// Launched from [PlanBadgeCard] so users can quickly see what the next
/// tier unlocks without leaving the home screen.
class PlansInfoSheet extends ConsumerWidget {
  const PlansInfoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlansInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(plansListProvider);
    final currentType =
        ref.watch(currentUserProvider).value?.planLimits?.planType;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium,
                        color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      ref.t('register.selectPlanTitle'),
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: plansAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(e.toString()),
                    ),
                  ),
                  data: (plans) => _PlansList(
                    plans: plans,
                    currentType: currentType,
                    scrollController: scroll,
                  ),
                ),
              ),
              const _ContactAdminBanner(),
            ],
          ),
        );
      },
    );
  }
}

class _PlansList extends ConsumerWidget {
  const _PlansList({
    required this.plans,
    required this.currentType,
    required this.scrollController,
  });

  final List<PlanEntity> plans;
  final String? currentType;
  final ScrollController scrollController;

  /// Canonical display order: cheapest / entry-level first, flagship
  /// second, negotiated tier last. The backend doesn't guarantee a
  /// stable ordering, so we sort client-side.
  static const _typeOrder = {
    PlanType.starter: 0,
    PlanType.business: 1,
    PlanType.enterprise: 2,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (plans.isEmpty) {
      return Center(
        child: Text(
          ref.t('common.loading'),
          style: const TextStyle(color: AppColors.gray500),
        ),
      );
    }
    final sorted = [...plans]..sort(
        (a, b) => (_typeOrder[a.type] ?? 99)
            .compareTo(_typeOrder[b.type] ?? 99),
      );
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _PlanCard(
        plan: sorted[i],
        isCurrent: sorted[i].type.apiValue == currentType,
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan, required this.isCurrent});
  final PlanEntity plan;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _accentFor(plan.type);
    final limitsEntries = plan.limits.entries.toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isCurrent
            ? accent.withValues(alpha: 0.06)
            : context.colors.surface,
        border: Border.all(
          color: isCurrent
              ? accent
              : AppColors.gray200,
          width: isCurrent ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      plan.name,
                      style: context.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                _priceLabel(plan, ref),
                style: context.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (plan.description != null &&
              plan.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.description!,
              style: context.textTheme.bodySmall
                  ?.copyWith(color: AppColors.gray500),
            ),
          ],
          if (limitsEntries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in limitsEntries)
              _LimitLine(feature: entry.key, value: entry.value),
          ],
        ],
      ),
    );
  }

  Color _accentFor(PlanType type) => switch (type) {
        PlanType.starter => AppColors.gray600,
        PlanType.business => AppColors.primary,
        PlanType.enterprise => AppColors.warning,
      };

  /// Picks the right headline for the price slot:
  ///   - Enterprise → "Kelishiladi" (price on Enterprise is not zero;
  ///     the backend stores 0 because it's a negotiated contract).
  ///   - Starter (or any other free tier) → localised "Free".
  ///   - Everything else → formatted amount + currency suffix.
  String _priceLabel(PlanEntity plan, WidgetRef ref) {
    if (plan.type == PlanType.enterprise) {
      return ref.t('plans.enterprise.negotiated');
    }
    if (plan.isFree) return ref.t('register.free');
    return '${_formatPrice(plan.price)} ${ref.t('pricing.currency')}';
  }

  String _formatPrice(double v) {
    if (v == 0) return '0';
    final s = v.toStringAsFixed(0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _LimitLine extends StatelessWidget {
  const _LimitLine({required this.feature, required this.value});
  final String feature;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isBool = value == 'true' || value == 'false';
    final enabled = value == 'true';
    final display = isBool ? '' : (value == 'unlimited' ? '∞' : value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isBool
                ? (enabled ? Icons.check_circle : Icons.cancel_outlined)
                : Icons.check_circle_outline,
            size: 16,
            color: isBool
                ? (enabled ? AppColors.success : AppColors.gray300)
                : AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _prettyFeature(feature),
              style: TextStyle(
                fontSize: 13,
                color: isBool && !enabled ? AppColors.gray400 : null,
              ),
            ),
          ),
          if (display.isNotEmpty)
            Text(
              display,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  /// `max_cashboxes` → "Max cashboxes". Good enough for a mobile
  /// quick-glance view; we don't need a full feature translation table.
  String _prettyFeature(String raw) {
    final words = raw.replaceAll('_', ' ').split(' ');
    if (words.isEmpty) return raw;
    words[0] = '${words[0][0].toUpperCase()}${words[0].substring(1)}';
    return words.join(' ');
  }
}

class _ContactAdminBanner extends ConsumerWidget {
  const _ContactAdminBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          border: const Border(
            top: BorderSide(color: AppColors.gray200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  ref.t('planGate.contactAdmin'),
                  style: context.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tarifni o\'zgartirish uchun administrator bilan bog\'laning. '
              'Yangi tarifga o\'tish faqat admin tomonidan amalga oshiriladi.',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: AppColors.gray700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 14, color: AppColors.gray500),
                const SizedBox(width: 4),
                Text(
                  ref.t('planGate.phone'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.mail_outline,
                    size: 14, color: AppColors.gray500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ref.t('planGate.email'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
