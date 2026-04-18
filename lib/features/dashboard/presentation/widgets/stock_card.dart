import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../data/dashboard_service.dart';

/// Hero KPI card showing total stock value + breakdowns by unit and
/// currency. Mirrors the web frontend's prominent top-of-dashboard
/// stock summary card.
class StockCard extends ConsumerWidget {
  const StockCard({
    super.key,
    required this.totalValue,
    required this.currencyLabel,
    required this.byUnit,
    required this.byCurrency,
  });

  final double totalValue;
  final String currencyLabel;
  final List<StockBucket> byUnit;
  final List<StockBucket> byCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.02),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  ref.t('dashboard.stockValue'),
                  style: context.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _format(totalValue),
                style: context.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (currencyLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  currencyLabel,
                  style: context.textTheme.titleSmall
                      ?.copyWith(color: AppColors.gray500),
                ),
              ],
            ],
          ),
          if (byUnit.isNotEmpty || byCurrency.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            if (byUnit.isNotEmpty)
              _BreakdownRow(
                icon: Icons.straighten,
                items: byUnit,
                formatValue: _format,
              ),
            if (byUnit.isNotEmpty && byCurrency.isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
            if (byCurrency.isNotEmpty)
              _BreakdownRow(
                icon: Icons.currency_exchange,
                items: byCurrency,
                formatValue: (v) => _format(v),
              ),
          ],
        ],
      ),
    );
  }

  static String _format(double v) {
    if (v == 0) return '0';
    final str = v.abs().toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
      buf.write(str[i]);
    }
    return v < 0 ? '-$buf' : buf.toString();
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.icon,
    required this.items,
    required this.formatValue,
  });

  final IconData icon;
  final List<StockBucket> items;
  final String Function(double) formatValue;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${formatValue(it.value)} ${it.label}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
