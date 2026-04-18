import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/utils/usecase.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';

/// Hard gate that covers the whole app when the company's plan is no
/// longer `active`. Renders a modal overlay so every underlying screen
/// becomes unreachable — the user can only retry the check or log out.
///
/// Status mapping (see backend `CompanyPlanStatus` enum):
///   - `active`    → overlay hidden, app works normally
///   - `pending`   → awaiting admin approval (new Business/Enterprise sign-up)
///   - `expired`   → trial / subscription lapsed
///   - `canceled`  → subscription revoked
/// All non-`active` statuses show the same overlay with tailored copy.
class PlanStatusGate extends ConsumerWidget {
  const PlanStatusGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final status = user?.planLimits?.status;

    // Hide the gate while the user hasn't loaded yet or the plan is
    // genuinely active. Pending / expired / canceled → overlay.
    final isBlocked = user != null &&
        status != null &&
        status.isNotEmpty &&
        status.toLowerCase() != 'active';

    return Stack(
      children: [
        child,
        if (isBlocked)
          _BlockingOverlay(status: status.toLowerCase()),
      ],
    );
  }
}

class _BlockingOverlay extends ConsumerWidget {
  const _BlockingOverlay({required this.status});
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageKey = switch (status) {
      'pending' => 'planGate.pending',
      'expired' => 'planGate.expired',
      'canceled' => 'planGate.canceled',
      _ => 'planGate.generic',
    };

    // Positioned.fill + ColoredBox absorbs every tap so the app
    // underneath stays interactive-proof. PopScope intercepts Android
    // back — the user can't swipe out either.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) {},
      child: Positioned.fill(
        child: Material(
          color: Colors.black.withValues(alpha: 0.7),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 440),
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _StatusIcon(status: status),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        ref.t('planGate.title'),
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        ref.t(messageKey),
                        style: context.textTheme.bodyMedium
                            ?.copyWith(color: AppColors.gray600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _ContactBlock(),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: ref.t('planGate.retry'),
                        icon: Icons.refresh,
                        onPressed: () =>
                            ref.invalidate(currentUserProvider),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: ref.t('planGate.logout'),
                        variant: AppButtonVariant.outlined,
                        icon: Icons.logout,
                        onPressed: () => _logout(ref),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(WidgetRef ref) async {
    await ref.read(welcomeSeenProvider.notifier).reset();
    await ref.read(logoutUseCaseProvider)(const NoParams());
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'pending' => (AppColors.warning, Icons.hourglass_empty),
      'expired' => (AppColors.danger, Icons.timer_off_outlined),
      'canceled' => (AppColors.danger, Icons.block),
      _ => (AppColors.gray500, Icons.lock_outline),
    };
    return Center(
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}

class _ContactBlock extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                ref.t('planGate.contactAdmin'),
                style: context.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ref.t('planGate.contactHint'),
            style: context.textTheme.bodySmall
                ?.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CopyRow(
            icon: Icons.phone_outlined,
            value: ref.t('planGate.phone'),
          ),
          const SizedBox(height: 4),
          _CopyRow(
            icon: Icons.mail_outline,
            value: ref.t('planGate.email'),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(value),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.gray500),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.copy, size: 14, color: AppColors.gray400),
        ],
      ),
    );
  }
}
