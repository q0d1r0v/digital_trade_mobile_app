import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../providers/dashboard_providers.dart';

/// Compact bar showing the current dashboard date range with tap-to-edit
/// chips. Dates are stored in `dashboardRangeProvider`; editing them via
/// the platform date picker invalidates every dashboard query.
class DateRangeBar extends ConsumerWidget {
  const DateRangeBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashboardRangeProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.date_range,
              size: 18, color: AppColors.gray500),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _Chip(
              label: _formatDate(range.from),
              onTap: () => _pickDate(
                context: context,
                ref: ref,
                initial: range.from,
                apply: (d) => ref.read(dashboardRangeProvider.notifier).state =
                    range.copyWith(from: d),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 14),
          ),
          Expanded(
            child: _Chip(
              label: _formatDate(range.to),
              onTap: () => _pickDate(
                context: context,
                ref: ref,
                initial: range.to,
                apply: (d) => ref.read(dashboardRangeProvider.notifier).state =
                    range.copyWith(to: d),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime initial,
    required void Function(DateTime) apply,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) apply(picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
