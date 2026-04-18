import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/models/named_ref.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../reference/reference_providers.dart';
import 'package:go_router/go_router.dart';

/// Bottom sheet with a search-filtered product list. Returns the picked
/// `NamedRef` or `null` if the sheet is dismissed. Intentionally stateless
/// beyond the search query — product quantity + price are edited in the
/// cart, not here, so the picker stays fast.
class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key});

  static Future<NamedRef?> show(BuildContext context) {
    return showModalBottomSheet<NamedRef>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProductPickerSheet(),
    );
  }

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productsRefProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) {
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
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: ref.t('nav.products'),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: async.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (items) {
                    final filtered = _query.isEmpty
                        ? items
                        : items
                            .where((p) => p.name.toLowerCase().contains(_query))
                            .toList();
                    if (filtered.isEmpty) {
                      return _emptyState(context);
                    }
                    return ListView.separated(
                      controller: scroll,
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        return ListTile(
                          leading: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusSm),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          title: Text(p.name),
                          onTap: () => Navigator.of(context).pop(p),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      children: [
        const SizedBox(height: 20),
        const Icon(
          Icons.inventory_2_outlined,
          size: 56,
          color: AppColors.gray300,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            ref.t('onboarding.checklist.tasks.firstProduct'),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.gray500),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.productNew);
            },
            icon: const Icon(Icons.add),
            label: Text(ref.t('onboarding.checklist.tasks.firstProduct')),
          ),
        ),
      ],
    );
  }
}
