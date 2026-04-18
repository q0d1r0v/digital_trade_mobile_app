import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../data/dashboard_service.dart';

/// Horizontal strip of currency cards (base → target rate).
/// Matches the web dashboard's "Currencies" section one-to-one, minus
/// the main currency itself (nothing useful to show for "UZS = 1 UZS").
class CurrencyRatesSection extends ConsumerWidget {
  const CurrencyRatesSection({super.key, required this.rates});
  final List<CurrencyRate> rates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rates.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.currency_exchange,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              ref.t('catalog.currency'),
              style: context.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: rates.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => _RateCard(rate: rates[i]),
          ),
        ),
      ],
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.rate});
  final CurrencyRate rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _CurrencyChip(
                label: rate.mainCode,
                accent: AppColors.gray500,
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, size: 14),
              const SizedBox(width: 6),
              _CurrencyChip(
                label: rate.targetCode,
                accent: AppColors.primary,
              ),
            ],
          ),
          Text(
            '1 ${rate.mainCode} = ${_formatRate(rate.rate)} ${rate.targetCode}',
            style: context.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (rate.countryName.isNotEmpty || rate.symbol.isNotEmpty)
            Text(
              '${rate.countryName}${rate.symbol.isEmpty ? '' : ' · ${rate.symbol}'}',
              style: context.textTheme.bodySmall
                  ?.copyWith(color: AppColors.gray500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  String _formatRate(double v) {
    if (v == 0) return '0';
    if (v == v.truncate()) {
      final s = v.toInt().toString();
      final b = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
        b.write(s[i]);
      }
      return b.toString();
    }
    return v.toStringAsFixed(2);
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
