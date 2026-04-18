import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';

/// Bottom-sheet walkthrough. Matches the web `SpotlightTour` in scope —
/// four slides that briefly explain each top-level tab plus a CTA that
/// drops the user into that tab when the tour ends.
class GuidedTourSheet extends ConsumerStatefulWidget {
  const GuidedTourSheet({super.key});

  @override
  ConsumerState<GuidedTourSheet> createState() => _GuidedTourSheetState();
}

class _GuidedTourSheetState extends ConsumerState<GuidedTourSheet> {
  final _controller = PageController();
  int _index = 0;

  static const _steps = [
    _TourStep(
      icon: Icons.dashboard_outlined,
      titleKey: 'onboarding.tour.dashboard.title',
      bodyKey: 'onboarding.tour.dashboard.body',
      route: AppRoutes.home,
    ),
    _TourStep(
      icon: Icons.inventory_2_outlined,
      titleKey: 'onboarding.tour.products.title',
      bodyKey: 'onboarding.tour.products.body',
      route: AppRoutes.products,
    ),
    _TourStep(
      icon: Icons.receipt_long_outlined,
      titleKey: 'onboarding.tour.invoices.title',
      bodyKey: 'onboarding.tour.invoices.body',
      route: AppRoutes.invoices,
    ),
    _TourStep(
      icon: Icons.people_outline,
      titleKey: 'onboarding.tour.clients.title',
      bodyKey: 'onboarding.tour.clients.body',
      route: AppRoutes.clients,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _steps.length - 1;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Text(
                      ref.t(
                        'onboarding.tour.progress',
                        params: {
                          'current': _index + 1,
                          'total': _steps.length,
                        },
                      ),
                      style: context.textTheme.labelLarge
                          ?.copyWith(color: AppColors.gray500),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _steps.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) =>
                      _TourSlide(step: _steps[i], scroll: scrollController),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    if (_index > 0)
                      Expanded(
                        child: AppButton(
                          variant: AppButtonVariant.outlined,
                          label: ref.t('onboarding.tour.prev'),
                          onPressed: () => _controller.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                    if (_index > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: isLast
                            ? ref.t('onboarding.tour.done')
                            : ref.t('onboarding.tour.next'),
                        icon:
                            isLast ? Icons.check : Icons.arrow_forward_rounded,
                        onPressed: () {
                          if (isLast) {
                            Navigator.of(context).pop();
                            context.go(_steps[_index].route);
                            return;
                          }
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TourStep {
  const _TourStep({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
    required this.route,
  });
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  final String route;
}

class _TourSlide extends ConsumerWidget {
  const _TourSlide({required this.step, required this.scroll});
  final _TourStep step;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      controller: scroll,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 96,
            width: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(step.icon, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            ref.t(step.titleKey),
            style: context.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            ref.t(step.bodyKey),
            style: context.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
