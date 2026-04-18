import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../data/dashboard_service.dart';

/// Side-by-side monthly comparison — two bars per month. The web
/// dashboard uses this for Sales vs Profit and for Total-Bonus vs
/// Total-Quantity; we render whatever pair the caller hands in.
class MonthlyDualChart extends ConsumerWidget {
  const MonthlyDualChart({
    super.key,
    required this.title,
    required this.primary,
    required this.secondary,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String title;
  final List<MonthlyPoint> primary;
  final List<MonthlyPoint> secondary;
  final String primaryLabel;
  final String secondaryLabel;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empty = primary.every((p) => p.value == 0) &&
        secondary.every((p) => p.value == 0);
    if (empty) {
      return _emptyCard(context, ref);
    }

    final maxValue = [
      ...primary.map((p) => p.value),
      ...secondary.map((p) => p.value),
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

    final labels = primary
        .asMap()
        .entries
        .map((e) => e.value.label.isNotEmpty
            ? e.value.label
            : secondary.length > e.key
                ? secondary[e.key].label
                : '')
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              _LegendDot(color: primaryColor, label: primaryLabel),
              _LegendDot(color: secondaryColor, label: secondaryLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMax / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.gray200,
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _shortMonth(labels[idx]),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.gray500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < primary.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: primary[i].value,
                          width: 10,
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              primaryColor,
                              primaryColor.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        if (i < secondary.length)
                          BarChartRodData(
                            toY: secondary[i].value,
                            width: 10,
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                secondaryColor,
                                secondaryColor.withValues(alpha: 0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                      ],
                    ),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      rod.toY.toStringAsFixed(0),
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context, WidgetRef ref) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                ref.t('dashboard.monthlySalesEmpty'),
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.gray500),
              ),
            ),
          ],
        ),
      );

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _shortMonth(String raw) {
    final parts = raw.split('-');
    if (parts.length >= 2) {
      final idx = int.tryParse(parts.last);
      if (idx != null && idx >= 1 && idx <= 12) return _months[idx - 1];
    }
    return raw;
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.gray500),
        ),
      ],
    );
  }
}
