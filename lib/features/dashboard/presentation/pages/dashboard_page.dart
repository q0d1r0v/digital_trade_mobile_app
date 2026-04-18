import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/shell_back_handler.dart';
import '../../../auth/domain/entities/plan_limits.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../auth/presentation/widgets/plan_badge_card.dart';
import '../../../onboarding/presentation/widgets/setup_checklist_card.dart';
import '../../data/dashboard_service.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/currency_rates_section.dart';
import '../widgets/date_range_bar.dart';
import '../widgets/kpi_card.dart';
import '../widgets/monthly_dual_chart.dart';
import '../widgets/quantity_area_chart.dart';
import '../widgets/stock_card.dart';

/// Home dashboard — mirrors the web "Boshqaruv paneli" so users get the
/// same numbers on mobile.
///
/// Layout top-to-bottom:
///   1. Greeting + plan badge + setup checklist
///   2. Date range filter
///   3. Stock card (total value, by unit, by currency)
///   4. 3-card summary KPI grid (sales, profit, quantity)
///   5. Currency rates
///   6. Monthly sales vs profit (dual bar chart)
///   7. Monthly quantity (area chart)
///   8. Given bonuses (dual bar chart — bonus vs quantity)
///   9. Quick actions
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final name = userAsync.value?.fullName.split(' ').first ?? '';
    final plan = userAsync.value?.planLimits;
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    return ShellBackHandler(
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(ref.t('nav.home')),
          actions: [
            IconButton(
              tooltip: ref.t('common.refresh'),
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.invalidate(dashboardSnapshotProvider),
            ),
            IconButton(
              tooltip: ref.t('onboarding.help.title'),
              icon: const Icon(Icons.help_outline),
              onPressed: () => context.push(AppRoutes.help),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(dashboardSnapshotProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _Greeting(name: name, company: userAsync.value?.companyName),
              const SizedBox(height: AppSpacing.lg),
              const PlanBadgeCard(),
              const SizedBox(height: AppSpacing.lg),
              const SetupChecklistCard(),
              const SizedBox(height: AppSpacing.lg),
              const DateRangeBar(),
              const SizedBox(height: AppSpacing.lg),
              _Sections(snapshotAsync: snapshotAsync),
              const SizedBox(height: AppSpacing.xl),
              _QuickActions(plan: plan),
            ],
          ),
        ),
      ),
    );
  }
}

class _Greeting extends ConsumerWidget {
  const _Greeting({required this.name, required this.company});
  final String name;
  final String? company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.t('home.welcome', params: {'name': name}),
          style: context.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (company != null) ...[
          const SizedBox(height: 2),
          Text(
            company!,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.gray500),
          ),
        ],
      ],
    );
  }
}

/// Renders every data-driven section in sequence. Wrapped so the outer
/// ListView can pass a single widget and let this class own the async
/// state handling.
class _Sections extends ConsumerWidget {
  const _Sections({required this.snapshotAsync});
  final AsyncValue<DashboardSnapshot> snapshotAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return snapshotAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Text(e.toString()),
      ),
      data: (s) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StockCard(
            totalValue: s.stockTotalValue,
            currencyLabel: s.stockCurrencyLabel,
            byUnit: s.stockByUnit,
            byCurrency: s.stockByCurrency,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SummaryKpis(snapshot: s),
          if (s.currencyRates.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            CurrencyRatesSection(rates: s.currencyRates),
          ],
          const SizedBox(height: AppSpacing.lg),
          MonthlyDualChart(
            title: ref.t('dashboard.monthlySalesTitle'),
            primary: s.monthlySales,
            secondary: s.monthlyProfit,
            primaryLabel: ref.t('dashboard.sales'),
            secondaryLabel: ref.t('dashboard.profit'),
            primaryColor: AppColors.primary,
            secondaryColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.lg),
          QuantityAreaChart(
            title: '${ref.t('dashboard.quantity')}: ${_amount(s.monthlyQuantityTotal)}',
            points: s.monthlyQuantity,
          ),
          if (s.monthlyBonuses.isNotEmpty &&
              s.monthlyBonuses.any((p) => p.value > 0)) ...[
            const SizedBox(height: AppSpacing.lg),
            MonthlyDualChart(
              title: ref.t('dashboard.givenBonus'),
              primary: s.monthlyBonuses,
              secondary: const [],
              primaryLabel: ref.t('dashboard.givenBonus'),
              secondaryLabel: '',
              primaryColor: AppColors.warning,
              secondaryColor: AppColors.info,
            ),
          ],
        ],
      ),
    );
  }
}

/// 3-card row: total sales, profit, quantity — exactly like the web
/// dashboard's summary cards.
class _SummaryKpis extends ConsumerWidget {
  const _SummaryKpis({required this.snapshot});
  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.95,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      children: [
        KpiCard(
          label: ref.t('dashboard.sales'),
          value: _amount(snapshot.monthlySalesTotal),
          icon: Icons.shopping_cart_checkout,
          accent: AppColors.success,
        ),
        KpiCard(
          label: ref.t('dashboard.profit'),
          value: _amount(snapshot.profit),
          icon: Icons.trending_up,
          accent: snapshot.profit >= 0
              ? AppColors.primary
              : AppColors.danger,
        ),
        KpiCard(
          label: ref.t('dashboard.quantity'),
          value: _amount(snapshot.monthlyQuantityTotal),
          icon: Icons.inventory_2_outlined,
          accent: AppColors.warning,
        ),
      ],
    );
  }
}

String _amount(double v) {
  if (v == 0) return '0';
  final str = v.abs().toStringAsFixed(0);
  final buf = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buf.write(' ');
    buf.write(str[i]);
  }
  return v < 0 ? '-$buf' : buf.toString();
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.plan});
  final PlanLimits? plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPos = plan?.hasPos ?? true;
    final canInviteTeam =
        plan == null ? true : (plan!.maxUsers > 1 || plan!.maxUsers == -1);

    final actions = <_ActionSpec>[
      _ActionSpec(
        icon: Icons.inventory_2_outlined,
        label: ref.t('onboarding.checklist.tasks.firstProduct'),
        route: AppRoutes.productNew,
        color: AppColors.primary,
      ),
      _ActionSpec(
        icon: Icons.move_to_inbox,
        label: ref.t('onboarding.checklist.tasks.firstInputInvoice'),
        route: AppRoutes.inputInvoiceNew,
        color: AppColors.info,
      ),
      if (hasPos)
        _ActionSpec(
          icon: Icons.shopping_cart_checkout,
          label: ref.t('onboarding.checklist.tasks.firstSale'),
          route: AppRoutes.saleNew,
          color: AppColors.success,
        ),
      _ActionSpec(
        icon: Icons.history,
        label: ref.t('nav.salesHistory'),
        route: AppRoutes.salesHistory,
        color: AppColors.warning,
      ),
      if (canInviteTeam)
        _ActionSpec(
          icon: Icons.group_add_outlined,
          label: ref.t('onboarding.checklist.tasks.inviteTeam'),
          route: AppRoutes.teamInvite,
          color: AppColors.secondary,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.t('home.quickActions'),
          style: context.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.55,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          children: [for (final a in actions) _ActionTile(spec: a)],
        ),
      ],
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String route;
  final Color color;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.spec});
  final _ActionSpec spec;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: () => context.push(spec.route),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray200),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: spec.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(spec.icon, color: spec.color, size: 20),
              ),
              Text(
                spec.label,
                style: context.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
