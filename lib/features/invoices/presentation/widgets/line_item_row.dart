import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/named_ref.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import 'ref_dropdown.dart';

/// Mutable state for one invoice line. Owning the controllers on the
/// parent lets the parent tear them down cleanly in `dispose()`.
class LineItem {
  LineItem()
      : uid = DateTime.now().microsecondsSinceEpoch,
        qtyCtrl = TextEditingController(),
        priceCtrl = TextEditingController(),
        expenseCtrl = TextEditingController();

  final int uid;
  NamedRef? product;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController expenseCtrl;

  double get quantity => double.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get price => double.tryParse(priceCtrl.text.trim()) ?? 0;
  double get expense => double.tryParse(expenseCtrl.text.trim()) ?? price;

  bool get isValid => product != null && quantity > 0 && price >= 0;

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
    expenseCtrl.dispose();
  }
}

/// Renders one [LineItem]: product picker + qty + price (+ optional
/// expense for input invoices). Bonus/discount is intentionally omitted
/// from the mobile form to keep the MVP focused on the onboarding task.
class LineItemRow extends ConsumerStatefulWidget {
  const LineItemRow({
    super.key,
    required this.item,
    required this.products,
    required this.showExpense,
    this.onRemove,
    this.onCreateProductRoute,
  });

  final LineItem item;
  final AsyncValue<List<NamedRef>> products;
  final bool showExpense;
  final VoidCallback? onRemove;
  final String? onCreateProductRoute;

  @override
  ConsumerState<LineItemRow> createState() => _LineItemRowState();
}

class _LineItemRowState extends ConsumerState<LineItemRow> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: RefDropdown(
                  label: 'Product',
                  value: widget.item.product,
                  icon: Icons.inventory_2_outlined,
                  async: widget.products,
                  onCreateRoute: widget.onCreateProductRoute,
                  onChanged: (v) => setState(() => widget.item.product = v),
                ),
              ),
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.danger),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: widget.item.qtyCtrl,
                  label: 'Qty',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _NumberField(
                  controller: widget.item.priceCtrl,
                  label: 'Price',
                ),
              ),
              if (widget.showExpense) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _NumberField(
                    controller: widget.item.expenseCtrl,
                    label: 'Cost',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: '0',
      ),
      style: context.textTheme.bodyMedium,
    );
  }
}
