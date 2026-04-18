import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../data/dashboard_service.dart';

/// Monthly sales bar chart. Built on `fl_chart`'s BarChart because it
/// renders cleanly at the narrow widths phones have, handles empty data
/// gracefully, and costs almost no runtime at the data volumes we deal
/// with (12 bars max per view).
class SalesBarChart extends ConsumerWidget {
  const SalesBarChart({super.key, required this.points});
  final List<MonthlyPoint> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.colors.surface,
          border: Border.all(color: AppColors.gray200),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        alignment: Alignment.center,
        child: Text(
          ref.t('dashboard.monthlySalesEmpty'),
          style: context.textTheme.bodyMedium
              ?.copyWith(color: AppColors.gray500),
        ),
      );
    }

    final maxValue = points
        .map((p) => p.value)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final chartMax = maxValue <= 0 ? 1.0 : maxValue * 1.2;

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
            ref.t('dashboard.monthlySalesTitle'),
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
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
                        if (idx < 0 || idx >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final label = _shortLabel(points[idx].label);
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: TextStyle(
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
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].value,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.6),
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

  /// `2026-04` → `Apr`. Backend hands us ISO-style month labels.
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _shortLabel(String raw) {
    final parts = raw.split('-');
    if (parts.length >= 2) {
      final idx = int.tryParse(parts.last);
      if (idx != null && idx >= 1 && idx <= 12) return _months[idx - 1];
    }
    return raw;
  }
}
