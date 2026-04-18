import 'package:flutter/material.dart';

import '../../../auth/domain/entities/plan_limits.dart';

/// One row in the setup checklist. `translationKey` resolves a dot-path in
/// the i18n JSON; `route` is the destination when the user taps the CTA.
///
/// `probe` is a value key returned by `OnboardingProbes` — the controller
/// maps it to the right REST call.
///
/// `isAvailable` decides whether the task even shows up for this user's
/// plan. E.g. "invite team" disappears on Starter (max_users = 1).
enum OnboardingProbe {
  companyProfile,
  firstCashbox,
  firstCategory,
  firstSupplier,
  firstProduct,
  firstInputInvoice,
  firstSale,
  inviteTeam,
}

class OnboardingTask {
  const OnboardingTask({
    required this.probe,
    required this.translationKey,
    required this.route,
    required this.icon,
    this.requiresPlan,
  });

  final OnboardingProbe probe;
  final String translationKey;
  final String route;
  final IconData icon;

  /// Predicate on the user's plan limits. `null` → always available.
  final bool Function(PlanLimits limits)? requiresPlan;

  bool isAvailable(PlanLimits? limits) {
    if (requiresPlan == null) return true;
    if (limits == null) return true; // Show by default while plan is loading.
    return requiresPlan!(limits);
  }
}

/// Canonical task ordering. Defined once so the Welcome modal, the
/// checklist panel, and the tour stay in lock-step.
const List<OnboardingTask> kOnboardingTasks = [
  OnboardingTask(
    probe: OnboardingProbe.companyProfile,
    translationKey: 'onboarding.checklist.tasks.companyProfile',
    route: '/company/edit',
    icon: Icons.apartment_outlined,
  ),
  OnboardingTask(
    probe: OnboardingProbe.firstCashbox,
    translationKey: 'onboarding.checklist.tasks.firstCashbox',
    route: '/cashboxes',
    icon: Icons.point_of_sale_outlined,
  ),
  OnboardingTask(
    probe: OnboardingProbe.firstCategory,
    translationKey: 'onboarding.checklist.tasks.firstCategory',
    route: '/categories',
    icon: Icons.category_outlined,
  ),
  OnboardingTask(
    probe: OnboardingProbe.firstSupplier,
    translationKey: 'onboarding.checklist.tasks.firstSupplier',
    route: '/suppliers',
    icon: Icons.local_shipping_outlined,
  ),
  OnboardingTask(
    probe: OnboardingProbe.firstProduct,
    translationKey: 'onboarding.checklist.tasks.firstProduct',
    route: '/products/new',
    icon: Icons.inventory_2_outlined,
  ),
  OnboardingTask(
    probe: OnboardingProbe.firstInputInvoice,
    translationKey: 'onboarding.checklist.tasks.firstInputInvoice',
    route: '/invoices/input/new',
    icon: Icons.receipt_long_outlined,
    requiresPlan: _hasInvoiceInput,
  ),
  OnboardingTask(
    probe: OnboardingProbe.firstSale,
    translationKey: 'onboarding.checklist.tasks.firstSale',
    route: '/invoices/sale/new',
    icon: Icons.shopping_cart_outlined,
    requiresPlan: _hasPos,
  ),
  OnboardingTask(
    probe: OnboardingProbe.inviteTeam,
    translationKey: 'onboarding.checklist.tasks.inviteTeam',
    route: '/team/invite',
    icon: Icons.group_add_outlined,
    requiresPlan: _canInviteTeam,
  ),
];

bool _hasPos(PlanLimits limits) => limits.hasPos;
bool _hasInvoiceInput(PlanLimits limits) => limits.hasInvoiceInput;
bool _canInviteTeam(PlanLimits limits) =>
    limits.maxUsers > 1 || limits.maxUsers == -1;
