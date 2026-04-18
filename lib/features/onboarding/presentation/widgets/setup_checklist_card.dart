import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../domain/entities/onboarding_task.dart';
import '../providers/onboarding_providers.dart';

/// Home-screen setup checklist. Collapsed by default to avoid dominating
/// the dashboard; expands to show all tasks available for the user's
/// plan. Tasks gated behind a higher tier are filtered out entirely.
class SetupChecklistCard extends ConsumerStatefulWidget {
  const SetupChecklistCard({super.key});

  @override
  ConsumerState<SetupChecklistCard> createState() =>
      _SetupChecklistCardState();
}

class _SetupChecklistCardState extends ConsumerState<SetupChecklistCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final dismissed = ref.watch(onboardingDismissedProvider);
    if (dismissed) return const SizedBox.shrink();

    final user = ref.watch(currentUserProvider).value;
    final planLimits = user?.planLimits;

    final tasks = kOnboardingTasks
        .where((t) => t.isAvailable(planLimits))
        .toList();
    final total = tasks.length;

    final progressAsync = ref.watch(onboardingProgressProvider);
    final progress = progressAsync.value ?? const {};
    final doneCount =
        tasks.where((t) => progress[t.probe] ?? false).length;
    final allDone = doneCount == total && total > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              allDone: allDone,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
              onDismiss: () async {
                await ref
                    .read(onboardingDismissedProvider.notifier)
                    .setDismissed(true);
                if (!context.mounted) return;
                context.showSnack(
                  ref.t('onboarding.checklist.dismissedHint'),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (allDone)
              Text(
                ref.t('onboarding.checklist.allDoneBody'),
                style: context.textTheme.bodyMedium,
              )
            else ...[
              _ProgressHeader(done: doneCount, total: total),
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.md),
                for (final task in tasks)
                  _TaskRow(
                    task: task,
                    done: progress[task.probe] ?? false,
                    loading: progressAsync.isLoading && progress.isEmpty,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends ConsumerWidget {
  const _HeaderRow({
    required this.allDone,
    required this.expanded,
    required this.onToggle,
    required this.onDismiss,
  });

  final bool allDone;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: (allDone ? AppColors.success : AppColors.primary)
                .withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            allDone ? Icons.check : Icons.rocket_launch_outlined,
            color: allDone ? AppColors.success : AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            allDone
                ? ref.t('onboarding.checklist.allDoneTitle')
                : ref.t('onboarding.checklist.title'),
            style: context.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: expanded
              ? ref.t('onboarding.checklist.minimize')
              : ref.t('onboarding.checklist.expand'),
          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          onPressed: onToggle,
        ),
        IconButton(
          tooltip: ref.t('onboarding.checklist.dismiss'),
          icon: const Icon(Icons.close, size: 18),
          onPressed: onDismiss,
        ),
      ],
    );
  }
}

class _ProgressHeader extends ConsumerWidget {
  const _ProgressHeader({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = total == 0 ? 0.0 : done / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.t(
            'onboarding.checklist.subtitle',
            params: {'done': done, 'total': total},
          ),
          style: context.textTheme.bodySmall
              ?.copyWith(color: AppColors.gray500),
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.gray200,
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({
    required this.task,
    required this.done,
    required this.loading,
  });
  final OnboardingTask task;
  final bool done;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.t(task.translationKey);
    return InkWell(
      onTap: done ? null : () => context.push(task.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: 2,
        ),
        child: Row(
          children: [
            _TaskIcon(done: done, loading: loading, fallback: task.icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? AppColors.gray400 : context.colors.onSurface,
                ),
              ),
            ),
            if (!done)
              const Icon(
                Icons.chevron_right,
                color: AppColors.gray400,
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskIcon extends StatelessWidget {
  const _TaskIcon({
    required this.done,
    required this.loading,
    required this.fallback,
  });

  final bool done;
  final bool loading;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return const Icon(Icons.check_circle, color: AppColors.success, size: 22);
    }
    if (loading) {
      return const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Container(
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(fallback, size: 14, color: AppColors.primary),
    );
  }
}
