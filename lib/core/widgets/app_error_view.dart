import 'package:flutter/material.dart';

import '../error/failure.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Renders a user-friendly view for any [Failure]. Features just pass their
/// error object; no need to branch on it at the call site.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.failure,
    this.onRetry,
  });

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (icon, title) = _presentation(failure);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: 'Retry',
                onPressed: onRetry,
                fullWidth: false,
                variant: AppButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, String) _presentation(Failure f) => switch (f) {
        NetworkFailure() => (Icons.wifi_off, 'Connection problem'),
        TimeoutFailure() => (Icons.timer_off_outlined, 'Request timed out'),
        UnauthorizedFailure() => (Icons.lock_outline, 'Session expired'),
        ForbiddenFailure() => (Icons.block, 'Access denied'),
        NotFoundFailure() => (Icons.search_off, 'Not found'),
        ValidationFailure() => (Icons.warning_amber_rounded, 'Invalid data'),
        ServerFailure() => (Icons.cloud_off, 'Server error'),
        CacheFailure() => (Icons.storage, 'Cache error'),
        UnknownFailure() => (Icons.error_outline, 'Something went wrong'),
      };
}
