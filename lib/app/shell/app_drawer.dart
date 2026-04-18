import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/translations_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/extensions/context_extensions.dart';
import '../../core/utils/usecase.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/current_user_provider.dart';
import '../../features/onboarding/presentation/providers/onboarding_providers.dart';
import '../router/app_routes.dart';

/// Left-side navigation drawer. Ordered to match the **Setup checklist**
/// on the dashboard: one-to-one mapping between the checklist tasks and
/// the main drawer rows, so users follow the same mental model no matter
/// which entry point they pick.
///
/// Plan-sensitive: POS, team, and other paid-tier surfaces hide
/// themselves on plans that don't support them.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final plan = user?.planLimits;
    final hasPos = plan?.hasPos ?? true;
    final canInviteTeam =
        plan == null ? true : (plan.maxUsers > 1 || plan.maxUsers == -1);
    final currentLocation =
        GoRouter.of(context).state.matchedLocation;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _Header(user: user),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                children: [
                  // ─── 0. Home (always first, not a checklist step) ──
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: ref.t('nav.home'),
                    route: AppRoutes.home,
                    current: currentLocation,
                  ),

                  const Divider(),

                  _section(ref.t('onboarding.checklist.title')),

                  // ─── 1. Kompaniya profili ──────────────────────────
                  _DrawerItem(
                    step: 1,
                    icon: Icons.apartment_outlined,
                    label: ref.t('onboarding.checklist.tasks.companyProfile'),
                    route: AppRoutes.companyEdit,
                    current: currentLocation,
                  ),
                  // ─── 2. Sotuv kassasi ─────────────────────────────
                  _DrawerItem(
                    step: 2,
                    icon: Icons.point_of_sale_outlined,
                    label: ref.t('onboarding.checklist.tasks.firstCashbox'),
                    route: AppRoutes.cashboxes,
                    current: currentLocation,
                  ),
                  // ─── 3. Mahsulot kategoriyasi ─────────────────────
                  _DrawerItem(
                    step: 3,
                    icon: Icons.category_outlined,
                    label: ref.t('onboarding.checklist.tasks.firstCategory'),
                    route: AppRoutes.categories,
                    current: currentLocation,
                  ),
                  // ─── 4. Ta'minotchi ───────────────────────────────
                  _DrawerItem(
                    step: 4,
                    icon: Icons.local_shipping_outlined,
                    label: ref.t('onboarding.checklist.tasks.firstSupplier'),
                    route: AppRoutes.suppliers,
                    current: currentLocation,
                  ),
                  // ─── 5. Mahsulot ──────────────────────────────────
                  _DrawerItem(
                    step: 5,
                    icon: Icons.inventory_2_outlined,
                    label: ref.t('nav.products'),
                    route: AppRoutes.products,
                    current: currentLocation,
                  ),
                  // ─── 6. Kirim fakturasi ──────────────────────────
                  _DrawerItem(
                    step: 6,
                    icon: Icons.move_to_inbox,
                    label: ref.t(
                      'onboarding.checklist.tasks.firstInputInvoice',
                    ),
                    route: AppRoutes.inputInvoiceNew,
                    current: currentLocation,
                  ),
                  // ─── 7. Birinchi sotuv (plan-gated) ──────────────
                  if (hasPos)
                    _DrawerItem(
                      step: 7,
                      icon: Icons.shopping_cart_checkout,
                      label:
                          ref.t('onboarding.checklist.tasks.firstSale'),
                      route: AppRoutes.saleNew,
                      current: currentLocation,
                      highlight: true,
                    ),
                  if (hasPos)
                    _DrawerItem(
                      icon: Icons.history,
                      label: ref.t('nav.salesHistory'),
                      route: AppRoutes.salesHistory,
                      current: currentLocation,
                    ),
                  // ─── 8. Jamoa a'zosi (plan-gated) ─────────────────
                  if (canInviteTeam)
                    _DrawerItem(
                      step: 8,
                      icon: Icons.group_add_outlined,
                      label: ref.t('onboarding.checklist.tasks.inviteTeam'),
                      route: AppRoutes.teamMembers,
                      current: currentLocation,
                    ),

                  const Divider(),

                  // ─── Extras — beyond the checklist ────────────────
                  _section(ref.t('nav.products')),
                  _DrawerItem(
                    icon: Icons.branding_watermark_outlined,
                    label: ref.t('nav.brands'),
                    route: AppRoutes.brands,
                    current: currentLocation,
                  ),
                  _section(ref.t('nav.clients')),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    label: ref.t('nav.clients'),
                    route: AppRoutes.clients,
                    current: currentLocation,
                  ),
                  _section(ref.t('nav.invoices')),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: ref.t('nav.invoices'),
                    route: AppRoutes.invoices,
                    current: currentLocation,
                  ),

                  const Divider(),

                  _DrawerItem(
                    icon: Icons.help_outline,
                    label: ref.t('onboarding.help.title'),
                    route: AppRoutes.help,
                    current: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: ref.t('nav.settings'),
                    route: AppRoutes.settings,
                    current: currentLocation,
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: AppColors.danger,
                    ),
                    title: Text(
                      ref.t('settings.logout'),
                      style: const TextStyle(color: AppColors.danger),
                    ),
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.gray500,
          ),
        ),
      );

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        content: Text(ref.t('auth.logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(ref.t('common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(ref.t('settings.logout')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(welcomeSeenProvider.notifier).reset();
    await ref.read(logoutUseCaseProvider)(const NoParams());
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = user?.fullName ?? '';
    final company = user?.companyName ?? '';
    final planName = user?.planLimits?.planName ?? '';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (company.isNotEmpty)
            Text(
              company,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          if (planName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                planName.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    this.highlight = false,
    this.step,
  });

  final IconData icon;
  final String label;
  final String route;
  final String current;
  final bool highlight;

  /// Optional 1-based step index — when set, shown as a small leading
  /// badge so users see the drawer mirrors the checklist order.
  final int? step;

  bool get isActive => current == route;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppColors.primary
        : (highlight ? AppColors.success : null);
    return Material(
      color: isActive
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          // Close the drawer first, then `go` instead of `push`: drawer
          // navigation should replace the current route, not stack pages
          // on top of each other. Previously `push` made the stack grow
          // by one on every drawer tap, which pinned state in memory and
          // caused the app to freeze on slow devices.
          Navigator.of(context).pop();
          context.go(route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (step != null)
                _StepBadge(step: step!, active: isActive)
              else
                Icon(icon, size: 20, color: color ?? AppColors.gray600),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: color ?? context.colors.onSurface,
                  ),
                ),
              ),
              if (step != null)
                Icon(icon, size: 16, color: AppColors.gray400),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small numbered badge rendered in place of the icon for checklist
/// steps. Gives the user an at-a-glance "I'm on step N of 8" cue that
/// matches the dashboard checklist.
class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step, required this.active});
  final int step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.12);
    final fg = active ? Colors.white : AppColors.primary;
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$step',
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
