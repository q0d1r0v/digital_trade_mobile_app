import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/models/named_ref.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/form_scaffold.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../reference/reference_providers.dart';
import '../widgets/line_item_row.dart';
import '../widgets/ref_dropdown.dart';

/// Input invoice (stock-in). Needs a repository, currency, supplier
/// (optional), and at least one product line with quantity+price+expense.
class InputInvoiceNewPage extends ConsumerStatefulWidget {
  const InputInvoiceNewPage({super.key});

  @override
  ConsumerState<InputInvoiceNewPage> createState() =>
      _InputInvoiceNewPageState();
}

class _InputInvoiceNewPageState extends ConsumerState<InputInvoiceNewPage> {
  NamedRef? _supplier;
  NamedRef? _repository;
  NamedRef? _currency;
  final List<LineItem> _items = [LineItem()];
  bool _saving = false;

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }


  Future<void> _save() async {
    if (_repository == null || _currency == null) {
      context.showSnack(ref.t('validation.required'), error: true);
      return;
    }
    final validItems = _items.where((i) => i.isValid).toList();
    if (validItems.isEmpty) {
      context.showSnack(ref.t('validation.required'), error: true);
      return;
    }
    final user = ref.read(currentUserProvider).value;
    final companyId = int.tryParse(user?.companyId ?? '');
    if (companyId == null) return;

    setState(() => _saving = true);
    // Body shape mirrors the web frontend's request 1:1 — that's the
    // format the backend happily accepts:
    //   - `status: 'approved'` so the invoice immediately books stock
    //     (web flow: supplier delivered + posted to repository).
    //   - `comment: ''` sent explicitly (backend happier with empty
    //     string than omitted field in some validation configs).
    //   - `variation_id: null` on each product line so the nested
    //     @ValidateNested check has the field it expects.
    //   - `date` omitted — @IsOptional + backend default new Date().
    final body = {
      'company_id': companyId,
      'repository_id': _repository!.id,
      'currency_id': _currency!.id,
      if (_supplier != null) 'supplier_id': _supplier!.id,
      'comment': '',
      'status': 'approved',
      'products': [
        for (final it in validItems)
          {
            'product_id': it.product!.id,
            'variation_id': null,
            'price': it.price,
            'expense': it.expense,
            'quantity': it.quantity,
          },
      ],
      'bonus_products': <Map<String, dynamic>>[],
    };

    final result = await ref.read(catalogServiceProvider).create(
          ApiEndpoints.inputInvoice,
          body,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(inputInvoiceListProvider);
        ref.invalidate(onboardingProgressProvider);
        ref.invalidate(currentUserProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repositoriesAsync = ref.watch(repositoriesProvider);
    final currenciesAsync = ref.watch(currenciesProvider);
    final suppliersAsync = ref.watch(suppliersRefProvider);
    final productsAsync = ref.watch(productsRefProvider);

    // `ref.listen` reacts to provider value changes without rebuilding
    // the widget tree, so we can setState here safely — no post-frame
    // callback + no chance of build-loop on slow devices.
    ref.listen<AsyncValue<List<NamedRef>>>(repositoriesProvider, (_, next) {
      next.whenData((items) {
        if (items.isNotEmpty && _repository == null && mounted) {
          setState(() => _repository = items.first);
        }
      });
    });
    ref.listen<AsyncValue<List<NamedRef>>>(currenciesProvider, (_, next) {
      next.whenData((items) {
        if (items.isNotEmpty && _currency == null && mounted) {
          setState(() => _currency = items.first);
        }
      });
    });

    return FormScaffold(
      title: ref.t('onboarding.checklist.tasks.firstInputInvoice'),
      saving: _saving,
      onSubmit: _save,
      children: [
        RefDropdown(
          label: ref.t('onboarding.checklist.tasks.firstSupplier'),
          value: _supplier,
          icon: Icons.local_shipping_outlined,
          async: suppliersAsync,
          onCreateRoute: AppRoutes.supplierNew,
          onChanged: (v) => setState(() => _supplier = v),
          optional: true,
        ),
        const SizedBox(height: AppSpacing.md),
        RefDropdown(
          label: ref.t('catalog.repository'),
          value: _repository,
          icon: Icons.warehouse_outlined,
          async: repositoriesAsync,
          onChanged: (v) => setState(() => _repository = v),
        ),
        const SizedBox(height: AppSpacing.md),
        RefDropdown(
          label: ref.t('catalog.currency'),
          value: _currency,
          icon: Icons.currency_exchange,
          async: currenciesAsync,
          onChanged: (v) => setState(() => _currency = v),
        ),
        FormSection(label: ref.t('nav.products'), icon: Icons.inventory_2),
        for (var i = 0; i < _items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: LineItemRow(
              key: ValueKey(_items[i].uid),
              item: _items[i],
              products: productsAsync,
              showExpense: true,
              onCreateProductRoute: AppRoutes.productNew,
              onRemove: _items.length > 1
                  ? () => setState(() {
                        _items[i].dispose();
                        _items.removeAt(i);
                      })
                  : null,
            ),
          ),
        OutlinedButton.icon(
          onPressed: () => setState(() => _items.add(LineItem())),
          icon: const Icon(Icons.add),
          label: Text(ref.t('nav.products')),
        ),
      ],
    );
  }
}
