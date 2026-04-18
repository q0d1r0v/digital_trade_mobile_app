import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/shell/app_drawer.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/i18n/translations_extension.dart';
import '../../../../core/models/named_ref.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/shell_back_handler.dart';
import '../../../auth/presentation/providers/current_user_provider.dart';
import '../../../catalog/catalog_providers.dart';
import '../../../onboarding/presentation/providers/onboarding_providers.dart';
import '../../../reference/reference_providers.dart';
import '../widgets/product_picker_sheet.dart';

/// Simplified POS — built around a "cart" metaphor instead of a raw DTO
/// form.
///
/// Flow:
///   1. Tap "+ Product" → picker sheet with search → qty/price inline
///   2. Cart rows show subtotal per line, total sticks to the bottom
///   3. Pick cashbox + payment method in a compact top-level card
///   4. Save posts the exact shape `POST
///      /company/invoice/output-invoice/sale` expects.
///
/// Reference data (cashbox, repo, currency, clients) auto-selects the
/// first item once loaded so single-branch accounts don't have to pick.
class SaleNewPage extends ConsumerStatefulWidget {
  const SaleNewPage({super.key});

  @override
  ConsumerState<SaleNewPage> createState() => _SaleNewPageState();
}

class _SaleNewPageState extends ConsumerState<SaleNewPage> {
  NamedRef? _cashbox;
  NamedRef? _repository;
  NamedRef? _currency;
  NamedRef? _client;
  String _payMethod = 'cash';
  final List<_CartLine> _cart = [];
  bool _saving = false;

  /// Grand total = sum of each line's discounted subtotal, rounded by
  /// the current currency's `round_mark` so our number matches what the
  /// backend will compute. Without rounding, UZS (round_mark=-3) causes
  /// "Payment not enough" because 10 sum here → 0 sum on the server.
  double get _total {
    final raw = _cart.fold(0.0, (s, it) => s + it.subtotal);
    final meta = _currencyMeta;
    return meta?.round(raw) ?? raw;
  }

  CurrencyMeta? get _currencyMeta {
    if (_currency == null) return null;
    final metas = ref.read(currencyMetasProvider).value;
    if (metas == null) return null;
    for (final m in metas) {
      if (m.currencyId == _currency!.id) return m;
    }
    return null;
  }

  @override
  void dispose() {
    for (final line in _cart) {
      line.dispose();
    }
    super.dispose();
  }

  /// Seeds a default picker value from the current async snapshot. Used
  /// during build() to cover the case where the provider was already
  /// resolved from a previous screen (keepAlive cache hit) — ref.listen
  /// wouldn't fire in that case, so defaults stayed empty.
  ///
  /// Schedules the `setState` after the current frame to avoid the
  /// "setState called during build" assertion.
  void _applyDefault(
    NamedRef? current,
    AsyncValue<List<NamedRef>> async,
    void Function(NamedRef) setter,
  ) {
    if (current != null) return;
    final items = async.value;
    if (items == null || items.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => setter(items.first));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watched here only so the `RefDropdown` children inside MetaCard
    // rebuild with the latest values; the auto-default wiring is in
    // the `ref.listen` calls below.
    final cashboxesAsync = ref.watch(cashboxesRefProvider);
    final clientsAsync = ref.watch(clientsRefProvider);
    // Warm the currency-meta cache so `_total` can round correctly.
    ref.watch(currencyMetasProvider);

    // `ref.listen` only fires on state *changes*. When the provider is
    // already resolved from a previous screen (keepAlive cache hit) the
    // listener never fires here, leaving defaults empty. Seed them
    // manually from the current cached value, then listen for later
    // updates.
    _applyDefault(_cashbox, ref.read(cashboxesRefProvider),
        (v) => _cashbox = v);
    _applyDefault(_repository, ref.read(repositoriesProvider),
        (v) => _repository = v);
    _applyDefault(_currency, ref.read(currenciesProvider),
        (v) => _currency = v);

    ref.listen<AsyncValue<List<NamedRef>>>(cashboxesRefProvider, (_, next) {
      next.whenData((items) {
        if (items.isNotEmpty && _cashbox == null && mounted) {
          setState(() => _cashbox = items.first);
        }
      });
    });
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

    return ShellBackHandler(
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          title: Text(ref.t('onboarding.checklist.tasks.firstSale')),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _MetaCard(
                      cashbox: _cashbox,
                      repository: _repository,
                      client: _client,
                      cashboxesAsync: cashboxesAsync,
                      repositoriesAsync: ref.watch(repositoriesProvider),
                      clientsAsync: clientsAsync,
                      onCashboxChanged: (v) =>
                          setState(() => _cashbox = v),
                      onRepositoryChanged: (v) =>
                          setState(() => _repository = v),
                      onClientChanged: (v) => setState(() => _client = v),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _CartHeader(onAdd: _pickProduct),
                    const SizedBox(height: AppSpacing.sm),
                    if (_cart.isEmpty)
                      _EmptyCart(onAdd: _pickProduct)
                    else
                      for (var i = 0; i < _cart.length; i++)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _CartRow(
                            line: _cart[i],
                            onChanged: () => setState(() {}),
                            onRemove: () => setState(() {
                              _cart[i].dispose();
                              _cart.removeAt(i);
                            }),
                          ),
                        ),
                  ],
                ),
              ),
              _CheckoutBar(
                total: _total,
                method: _payMethod,
                // Always enabled so the user can tap and see WHY save is
                // blocked (empty cart, missing cashbox, etc.). Blocking
                // rules now live in `_save()` and surface via snackbars.
                disabled: false,
                saving: _saving,
                onMethodChanged: (v) => setState(() => _payMethod = v),
                onSubmit: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProduct() async {
    final picked = await ProductPickerSheet.show(context);
    if (picked == null) return;

    // Pre-fill the cart line with the product's default selling price.
    // Backend `product.resource.ts` exposes `productPrices: { cost_price,
    // expense, selling_price }` — the `selling_price` is what the web
    // POS uses, so we mirror that here. A network failure just leaves
    // the line at 0 so the user can still type a price manually.
    final line = _CartLine(product: picked);
    setState(() => _cart.add(line));

    final detailResult = await ref
        .read(catalogServiceProvider)
        .detail(ApiEndpoints.product, picked.id);
    if (!mounted) return;
    detailResult.fold(
      (_) {}, // silent fallback
      (data) {
        final prices = data['productPrices'];
        if (prices is! Map<String, dynamic>) return;

        final selling = _extractSellingPrice(prices);
        final cost = _asDouble(prices['cost_price']);

        if (_cart.contains(line)) {
          // Only overwrite price if the user hasn't already typed one.
          if (selling > 0 &&
              (double.tryParse(line.priceCtrl.text.trim()) ?? 0) == 0) {
            line.priceCtrl.text = _formatAmount(selling);
          }
          line.costPrice = cost;
          setState(() {});
        }
      },
    );
  }

  double _extractSellingPrice(Map<String, dynamic> prices) {
    final selling = prices['selling_price'];
    if (selling is num) return selling.toDouble();
    if (selling is String) return double.tryParse(selling) ?? 0;
    // Fall back to cost+expense in case the backend returns those
    // individually without the computed `selling_price`.
    final cost = _asDouble(prices['cost_price']);
    final expense = _asDouble(prices['expense']);
    return cost + expense;
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  String _formatAmount(double v) {
    // Trim trailing zeros for readability (100.0 → 100, 99.5 → 99.5).
    if (v == v.truncate()) return v.toInt().toString();
    return v.toString();
  }

  Future<void> _save() async {
    // Surface the exact reason save can't proceed so the user isn't left
    // staring at a disabled button wondering why.
    if (_cart.isEmpty) {
      context.showSnack(ref.t('sales.cartEmpty'), error: true);
      return;
    }
    if (_cashbox == null) {
      context.showSnack(ref.t('sales.pickCashbox'), error: true);
      return;
    }
    if (_repository == null) {
      context.showSnack(ref.t('sales.pickRepository'), error: true);
      return;
    }
    if (_currency == null) {
      context.showSnack(ref.t('sales.pickCurrency'), error: true);
      return;
    }
    if (_total <= 0) {
      context.showSnack(ref.t('sales.totalMustBePositive'), error: true);
      return;
    }
    setState(() => _saving = true);
    // Body shape matches `CreateSaleInvoiceDto` exactly:
    //   - products[].bonus_value is @IsNumber() (conditionally required
    //     via @IsRequiredIf) so we always send `0` to keep validation
    //     happy even when there's no discount applied.
    //   - payments[].payment_type is the correct field name (NOT
    //     `payment_method`); valid enum values are `bank|card|cash`.
    final body = {
      'repository_id': _repository!.id,
      'currency_id': _currency!.id,
      'cashbox_id': _cashbox!.id,
      if (_client != null) 'client_id': _client!.id,
      'comment': '',
      'status': 'approved',
      'products': [
        for (final it in _cart)
          {
            'product_id': it.product.id,
            'variation_id': null,
            'price': it.price,
            'quantity': it.quantity,
            'bonus_value': it.bonusKind == _BonusKind.none ? 0 : it.bonusValue,
            if (it.bonusKind.apiValue != null)
              'bonus_type': it.bonusKind.apiValue,
          },
      ],
      'payments': [
        {'payment_type': _payMethod, 'value': _total},
      ],
    };

    final result = await ref.read(catalogServiceProvider).create(
          ApiEndpoints.saleInvoice,
          body,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => context.showSnack(f.message, error: true),
      (_) {
        ref.invalidate(saleInvoiceListProvider);
        ref.invalidate(onboardingProgressProvider);
        ref.invalidate(currentUserProvider);
        context.showSnack(ref.t('common.done'));
        context.safePop();
      },
    );
  }
}

/// Bonus types the backend accepts (`InvoiceProductBonusType` enum).
/// We expose `none` in the UI as a separate state so the cart line's
/// bonus section can be hidden completely when the user doesn't want
/// a discount.
enum _BonusKind { none, percent, amount }

extension on _BonusKind {
  String? get apiValue => switch (this) {
        _BonusKind.none => null,
        _BonusKind.percent => 'percentage_discount',
        _BonusKind.amount => 'amount_discount',
      };
}

/// Cart line state owned by the parent. Keeps controllers close to the
/// mutable data so tearing them down is a single loop.
class _CartLine {
  _CartLine({required this.product})
      : qtyCtrl = TextEditingController(text: '1'),
        priceCtrl = TextEditingController(text: '0'),
        bonusValueCtrl = TextEditingController(text: '0');

  final NamedRef product;

  /// Cost per unit — populated after product details load. Not a
  /// constructor param because pickers create the line first and price
  /// info arrives asynchronously. Shown to the user so they can eye
  /// the margin; never sent to the backend.
  double costPrice = 0;

  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController bonusValueCtrl;
  _BonusKind bonusKind = _BonusKind.none;

  double get quantity => double.tryParse(qtyCtrl.text.trim()) ?? 0;
  double get price => double.tryParse(priceCtrl.text.trim()) ?? 0;
  double get bonusValue =>
      double.tryParse(bonusValueCtrl.text.trim()) ?? 0;

  /// `price * qty - discount`. Discount is either a percentage of the
  /// subtotal or a flat amount, depending on [bonusKind].
  double get subtotal {
    final base = quantity * price;
    switch (bonusKind) {
      case _BonusKind.none:
        return base;
      case _BonusKind.percent:
        final pct = bonusValue.clamp(0, 100);
        return base - (base * pct / 100);
      case _BonusKind.amount:
        return (base - bonusValue).clamp(0, double.infinity);
    }
  }

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
    bonusValueCtrl.dispose();
  }
}

class _MetaCard extends ConsumerWidget {
  const _MetaCard({
    required this.cashbox,
    required this.repository,
    required this.client,
    required this.cashboxesAsync,
    required this.repositoriesAsync,
    required this.clientsAsync,
    required this.onCashboxChanged,
    required this.onRepositoryChanged,
    required this.onClientChanged,
  });

  final NamedRef? cashbox;
  final NamedRef? repository;
  final NamedRef? client;
  final AsyncValue<List<NamedRef>> cashboxesAsync;
  final AsyncValue<List<NamedRef>> repositoriesAsync;
  final AsyncValue<List<NamedRef>> clientsAsync;
  final ValueChanged<NamedRef?> onCashboxChanged;
  final ValueChanged<NamedRef?> onRepositoryChanged;
  final ValueChanged<NamedRef?> onClientChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: Icons.warehouse_outlined,
            label: ref.t('catalog.repository'),
            value: repository,
            async: repositoriesAsync,
            onChanged: onRepositoryChanged,
          ),
          const Divider(height: AppSpacing.lg),
          _MetaRow(
            icon: Icons.point_of_sale_outlined,
            label: ref.t('catalog.cashbox'),
            value: cashbox,
            async: cashboxesAsync,
            createRoute: AppRoutes.cashboxNew,
            onChanged: onCashboxChanged,
          ),
          const Divider(height: AppSpacing.lg),
          _MetaRow(
            icon: Icons.person_outline,
            label: ref.t('nav.clients'),
            value: client,
            async: clientsAsync,
            createRoute: AppRoutes.clientNew,
            onChanged: onClientChanged,
            optional: true,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends ConsumerWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.async,
    required this.onChanged,
    this.createRoute,
    this.optional = false,
  });

  final IconData icon;
  final String label;
  final NamedRef? value;
  final AsyncValue<List<NamedRef>> async;
  final ValueChanged<NamedRef?> onChanged;
  final String? createRoute;
  final bool optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _pickFromSheet(context),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.gray500),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value?.name ??
                        (optional
                            ? '—'
                            : ref.t('validation.required')),
                    style: context.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<NamedRef?>(
      context: context,
      builder: (_) => _RefPickerSheet(
        title: label,
        async: async,
        createRoute: createRoute,
        optional: optional,
      ),
    );
    if (picked == null && !optional) return;
    onChanged(picked);
  }
}

class _RefPickerSheet extends ConsumerWidget {
  const _RefPickerSheet({
    required this.title,
    required this.async,
    required this.optional,
    this.createRoute,
  });
  final String title;
  final AsyncValue<List<NamedRef>> async;
  final String? createRoute;
  final bool optional;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    title,
                    style: context.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (optional)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('—'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(e.toString()),
              ),
              data: (items) {
                if (items.isEmpty && createRoute != null) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(createRoute!);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(title),
                    ),
                  );
                }
                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(items[i].name),
                      onTap: () => Navigator.of(context).pop(items[i]),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CartHeader extends ConsumerWidget {
  const _CartHeader({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Text(
          ref.t('nav.products'),
          style: context.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: Text(ref.t('nav.products')),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 44,
            color: AppColors.gray300,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            ref.t('onboarding.checklist.tasks.firstSale'),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium
                ?.copyWith(color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(ref.t('nav.products')),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  const _CartRow({
    required this.line,
    required this.onChanged,
    required this.onRemove,
  });

  final _CartLine line;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = line.quantity * line.price;
    final hasDiscount = line.bonusKind != _BonusKind.none;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.product.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (line.costPrice > 0)
                      Text(
                        '${ref.t('sales.cost')}: ${line.costPrice.toStringAsFixed(2)}',
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: AppColors.gray500),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.danger),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _QtyStepper(controller: line.qtyCtrl, onChanged: onChanged),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: line.priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: ref.t('sales.sellPrice'),
                    prefixIcon: const Icon(Icons.payments_outlined),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _BonusPicker(line: line, onChanged: onChanged),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: hasDiscount
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        base.toStringAsFixed(2),
                        style: context.textTheme.bodySmall?.copyWith(
                          color: AppColors.gray400,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        line.subtotal.toStringAsFixed(2),
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '${ref.t('sales.subtotal')}: ${line.subtotal.toStringAsFixed(2)}',
                    style: context.textTheme.bodySmall
                        ?.copyWith(color: AppColors.gray500),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Inline bonus (discount) editor per cart line:
///   - SegmentedButton to pick None / % / amount
///   - When % or amount is selected, a numeric field appears next to it
///
/// Sends `bonus_type` + `bonus_value` in the sale body (web parity).
class _BonusPicker extends StatelessWidget {
  const _BonusPicker({required this.line, required this.onChanged});
  final _CartLine line;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<_BonusKind>(
            segments: const [
              ButtonSegment(
                value: _BonusKind.none,
                label: Text('—'),
              ),
              ButtonSegment(
                value: _BonusKind.percent,
                icon: Icon(Icons.percent, size: 14),
                label: Text('%'),
              ),
              ButtonSegment(
                value: _BonusKind.amount,
                icon: Icon(Icons.money_off, size: 14),
                label: Text('Sum'),
              ),
            ],
            selected: {line.bonusKind},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
            onSelectionChanged: (s) {
              line.bonusKind = s.first;
              if (line.bonusKind == _BonusKind.none) {
                line.bonusValueCtrl.text = '0';
              }
              onChanged();
            },
          ),
        ),
        if (line.bonusKind != _BonusKind.none) ...[
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: line.bonusValueCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText:
                    line.bonusKind == _BonusKind.percent ? '%' : 'Sum',
                isDense: true,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ],
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  void _bump(int delta) {
    final current = int.tryParse(controller.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 999999);
    controller.text = next.toString();
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray300),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => _bump(-1),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 48,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => _bump(1),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom action bar — total + payment method + submit. Styled as a
/// surface elevated above the list so the user always sees the cart total
/// while scrolling.
class _CheckoutBar extends ConsumerWidget {
  const _CheckoutBar({
    required this.total,
    required this.method,
    required this.disabled,
    required this.saving,
    required this.onMethodChanged,
    required this.onSubmit,
  });

  final double total;
  final String method;
  final bool disabled;
  final bool saving;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                ref.t('sales.total'),
                style: context.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.gray500),
              ),
              const Spacer(),
              Text(
                total.toStringAsFixed(2),
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<String>(
            // Values MUST match the backend `PaymentType` enum:
            //   `cash`, `card`, `bank` — anything else fails @IsEnum().
            segments: [
              ButtonSegment(
                value: 'cash',
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: Text(ref.t('sales.cash')),
              ),
              ButtonSegment(
                value: 'card',
                icon: const Icon(Icons.credit_card, size: 16),
                label: Text(ref.t('sales.card')),
              ),
              ButtonSegment(
                value: 'bank',
                icon: const Icon(Icons.account_balance, size: 16),
                label: Text(ref.t('sales.bank')),
              ),
            ],
            selected: {method},
            onSelectionChanged: (s) => onMethodChanged(s.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: ref.t('common.save'),
            onPressed: disabled ? null : onSubmit,
            loading: saving,
            icon: Icons.check,
          ),
        ],
      ),
    );
  }
}
