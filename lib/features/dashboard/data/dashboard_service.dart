import '../../../core/constants/api_endpoints.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/network/api_client.dart';

/// Thin HTTP wrapper for the backend's aggregated-KPI endpoints. Each
/// method returns the raw decoded JSON so the presentation layer can
/// project exactly the shape it needs — the backend response structure
/// varies per endpoint and isn't worth a dedicated DTO class.
class DashboardService {
  DashboardService(this._api);
  final ApiClient _api;

  /// Fetches every KPI source in parallel so the dashboard finishes in
  /// one network round-trip worth of time instead of many sequentially.
  /// Missing endpoints (permissions, older server) degrade to empty
  /// maps/lists instead of propagating errors — the dashboard renders
  /// what it can.
  Future<DashboardSnapshot> loadAll({DateTime? from, DateTime? to}) async {
    final dateQuery = _dateRange(from, to);

    final futures = <Future<dynamic>>[
      _safeGetMap(ApiEndpoints.dashboardSoldProduct, query: dateQuery),
      // Monthly endpoint returns a bare array `[{month, ...}]` (no
      // `{data: ...}` wrapper), so use the list helper.
      _safeGetList(
        ApiEndpoints.dashboardSoldProductMonthly,
        query: dateQuery,
      ),
      _safeGetMap(ApiEndpoints.dashboardStock),
      _safeGetList(ApiEndpoints.dashboardCurrency),
      _safeGetList(ApiEndpoints.dashboardGivenBonus, query: dateQuery),
      _safeGetMap(ApiEndpoints.dashboardInputInvoice, query: dateQuery),
      _safeGetMap(ApiEndpoints.dashboardSaleInvoice, query: dateQuery),
    ];

    final results = await Future.wait(futures);
    return DashboardSnapshot(
      soldProduct: results[0] as Map<String, dynamic>,
      soldProductMonthly: results[1] as List<dynamic>,
      stock: results[2] as Map<String, dynamic>,
      currencies: results[3] as List<dynamic>,
      givenBonuses: results[4] as List<dynamic>,
      inputInvoice: results[5] as Map<String, dynamic>,
      saleInvoice: results[6] as Map<String, dynamic>,
    );
  }

  /// Backend accepts `date[]=YYYY-MM-DD&date[]=YYYY-MM-DD`. Dio serialises
  /// list query params that way when `ListFormat.multiCompatible` is
  /// configured (see `DioFactory`).
  Map<String, dynamic>? _dateRange(DateTime? from, DateTime? to) {
    if (from == null && to == null) return null;
    String iso(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'date': [
        if (from != null) iso(from),
        if (to != null) iso(to),
      ],
    };
  }

  Future<Map<String, dynamic>> _safeGetMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final raw = await _api.get<dynamic>(path, query: query);
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) return data;
        return raw;
      }
      return const {};
    } on AppException {
      return const {};
    }
  }

  Future<List<dynamic>> _safeGetList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final raw = await _api.get<dynamic>(path, query: query);
      if (raw is List) return raw;
      if (raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is List) return data;
      }
      return const [];
    } on AppException {
      return const [];
    }
  }
}

/// Bundle of responses from every dashboard endpoint. Keeping them
/// together simplifies downstream projection code and prevents one slow
/// endpoint from blocking the whole UI.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.soldProduct,
    required this.soldProductMonthly,
    required this.stock,
    required this.currencies,
    required this.givenBonuses,
    required this.inputInvoice,
    required this.saleInvoice,
  });

  final Map<String, dynamic> soldProduct;
  final List<dynamic> soldProductMonthly;
  final Map<String, dynamic> stock;
  final List<dynamic> currencies;
  final List<dynamic> givenBonuses;
  final Map<String, dynamic> inputInvoice;
  final Map<String, dynamic> saleInvoice;

  // ─── Stock ───────────────────────────────────────────────────────────

  double get stockTotalValue => _asDouble(stock['total_value']);

  String get stockCurrencyLabel =>
      (stock['currency']?['code'] ??
              stock['currency']?['name'] ??
              stock['currency']?['symbol'] ??
              '')
          .toString();

  /// Backend returns flat `{unit_id, unit_name, quantity}` objects, not
  /// nested `{unit: {name}}` — project accordingly.
  List<StockBucket> get stockByUnit {
    final raw = stock['by_unit'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          StockBucket(
            label: (item['unit_name'] ??
                    item['unit']?['name'] ??
                    item['name'] ??
                    '')
                .toString(),
            value: _asDouble(item['quantity'] ?? item['total_quantity']),
          ),
    ];
  }

  /// Backend returns `{currency_id, currency_code, currency_symbol,
  /// value, currency_change, converted_value}` per bucket.
  List<StockBucket> get stockByCurrency {
    final raw = stock['by_currency'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map<String, dynamic>)
          StockBucket(
            label: (item['currency_code'] ??
                    item['currency']?['code'] ??
                    item['currency']?['name'] ??
                    '')
                .toString(),
            value: _asDouble(
              item['converted_value'] ?? item['value'] ?? item['total_value'],
            ),
          ),
    ];
  }

  // ─── Invoice KPIs ────────────────────────────────────────────────────
  //
  // Sale-invoice-dashboard response (confirmed via live log):
  //   { sold: [...], canceled: [...], waiting: [...], debt: [...],
  //     returns: [...], returns_canceled: [...] }
  // Each row: { total_sales|total_income, price, paid, debt, status,
  //             currency: {id, code, symbol} }
  //
  // Input-invoice-dashboard response:
  //   { approved, canceled, waiting } with `total_income` counts.

  double get totalSalesAmount =>
      _sumField(saleInvoice['sold'], 'price');
  double get totalSalesPaid =>
      _sumField(saleInvoice['sold'], 'paid');
  double get totalReturnsAmount =>
      _sumField(saleInvoice['returns'], 'price');
  double get debtSalesAmount =>
      _sumField(saleInvoice['debt'], 'price');
  double get totalPurchasesAmount =>
      _sumField(inputInvoice['approved'], 'price');

  int get approvedSalesCount =>
      _sumIntField(saleInvoice['sold'], 'total_sales');
  int get approvedPurchasesCount =>
      _sumIntField(inputInvoice['approved'], 'total_income');

  // ─── Derived from monthly series ─────────────────────────────────────

  List<MonthlyPoint> get monthlySales =>
      _monthlySeries(pickKey: 'soldProducts');

  List<MonthlyPoint> get monthlyProfit =>
      _monthlySeries(pickKey: 'profit');

  List<MonthlyPoint> get monthlyQuantity =>
      _monthlySeries(pickKey: 'soldProductQuantity', quantity: true);

  double get monthlySalesTotal =>
      monthlySales.fold(0.0, (s, p) => s + p.value);

  double get monthlyProfitTotal =>
      monthlyProfit.fold(0.0, (s, p) => s + p.value);

  double get monthlyQuantityTotal =>
      monthlyQuantity.fold(0.0, (s, p) => s + p.value);

  /// Profit number used by the headline KPI. Prefer the backend's
  /// authoritative monthly total; fall back to sales-minus-purchases if
  /// the monthly endpoint returned nothing.
  double get profit {
    if (monthlyProfitTotal != 0) return monthlyProfitTotal;
    return totalSalesAmount - totalPurchasesAmount;
  }

  // ─── Given bonuses (by month) ────────────────────────────────────────

  List<MonthlyPoint> get monthlyBonuses {
    final points = <MonthlyPoint>[];
    for (final m in givenBonuses) {
      if (m is! Map<String, dynamic>) continue;
      final label = (m['month'] ?? m['label'] ?? '').toString();
      final items = m['items'];
      double bonus = 0;
      if (items is List) {
        for (final it in items) {
          if (it is Map<String, dynamic>) {
            bonus += _asDouble(it['total_bonus']);
          }
        }
      }
      points.add(MonthlyPoint(label: label, value: bonus));
    }
    return points;
  }

  double get totalBonuses =>
      monthlyBonuses.fold(0.0, (s, p) => s + p.value);

  // ─── Currency rates ──────────────────────────────────────────────────

  List<CurrencyRate> get currencyRates {
    final rates = <CurrencyRate>[];
    for (final c in currencies) {
      if (c is! Map<String, dynamic>) continue;
      final currency = c['currency'] as Map<String, dynamic>?;
      final main = c['mainCurrency'] as Map<String, dynamic>?;
      if (currency == null || main == null) continue;
      if (currency['code'] == main['code']) continue;
      rates.add(CurrencyRate(
        targetCode:
            (currency['code'] ?? currency['name'] ?? '').toString(),
        mainCode: (main['code'] ?? main['name'] ?? '').toString(),
        rate: _asDouble(c['currencyChange']),
        countryName: (currency['country'] ?? '').toString(),
        symbol: (currency['symbol'] ?? '').toString(),
      ));
    }
    return rates;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Iterates the months array and sums the requested per-month series.
  /// Backend shape per month:
  ///   soldProducts/profit: [{ currency, value }]
  ///   soldProductQuantity: [{ unit, quantity }]
  List<MonthlyPoint> _monthlySeries({
    required String pickKey,
    bool quantity = false,
  }) {
    final points = <MonthlyPoint>[];
    for (final item in soldProductMonthly) {
      if (item is! Map<String, dynamic>) continue;
      final label = (item['month'] ?? item['label'] ?? '').toString();
      final sub = item[pickKey];
      double value = 0;
      if (sub is List && sub.isNotEmpty) {
        for (final s in sub) {
          if (s is! Map<String, dynamic>) continue;
          final key = quantity
              ? (s['quantity'] ?? s['total_quantity'] ?? s['value'])
              : (s['value'] ?? s['price'] ?? s['amount']);
          value += _asDouble(key);
        }
      }
      points.add(MonthlyPoint(label: label, value: value));
    }
    return points;
  }

  /// Sums a numeric field across every status bucket row in an invoice
  /// dashboard response. Handles both direct fields (`price`) and the
  /// legacy nested-sum shape (`sum: {price}`).
  double _sumField(dynamic raw, String key) {
    if (raw is! List || raw.isEmpty) return 0;
    var total = 0.0;
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final sum = item['sum'];
      final v = sum is Map<String, dynamic> ? sum[key] : item[key];
      total += _asDouble(v);
    }
    return total;
  }

  int _sumIntField(dynamic raw, String key) {
    if (raw is! List || raw.isEmpty) return 0;
    var total = 0;
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final v = item[key];
      if (v is num) total += v.toInt();
    }
    return total;
  }

  static double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}

class MonthlyPoint {
  const MonthlyPoint({required this.label, required this.value});
  final String label;
  final double value;
}

class StockBucket {
  const StockBucket({required this.label, required this.value});
  final String label;
  final double value;
}

class CurrencyRate {
  const CurrencyRate({
    required this.targetCode,
    required this.mainCode,
    required this.rate,
    required this.countryName,
    required this.symbol,
  });
  final String targetCode;
  final String mainCode;
  final double rate;
  final String countryName;
  final String symbol;
}
