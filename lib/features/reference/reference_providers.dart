import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/di/injection.dart';
import '../../core/error/app_exception.dart';
import '../../core/models/named_ref.dart';
import '../../core/network/api_client.dart';
import '../../core/network/paginated_response.dart';

/// Pulls `{id, name}` pairs from the list endpoints used purely to fill
/// dropdowns (units, currencies, repositories, roles). Shared so no
/// feature re-implements the "fetch → parse → cache" cycle.
///
/// Keeping these in one file — rather than a folder per reference —
/// mirrors the way the backend treats them: simple lookups that rarely
/// change.
Future<List<NamedRef>> _fetchList(
  String path, {
  Map<String, dynamic>? query,
}) async {
  try {
    final response = await sl<ApiClient>().get<dynamic>(
      path,
      query: {'page': 1, 'limit': 100, ...?query},
    );
    return PaginatedResponse.from(response, NamedRef.fromJson).items;
  } on AppException {
    return const [];
  }
}

final repositoriesProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.repository),
);

/// Currency picker specifically needs the **`currency_id`** from each
/// CompanyCurrency row (that's what the invoice DTO's
/// `@IsExist({column: 'currency_id'})` validator checks against), not the
/// CompanyCurrency record's own `id`. We therefore project manually here
/// instead of reusing the generic `_fetchList` helper.
final currenciesProvider = FutureProvider<List<NamedRef>>((ref) async {
  try {
    final response = await sl<ApiClient>().get<dynamic>(
      ApiEndpoints.currency,
      query: {'page': 1, 'limit': 100},
    );
    return _projectCurrencies(response);
  } on AppException {
    return const [];
  }
});

List<NamedRef> _projectCurrencies(dynamic raw) {
  final list = raw is Map<String, dynamic>
      ? (raw['data'] ?? raw['items'] ?? raw['rows']) as List? ?? const []
      : raw is List
          ? raw
          : const [];

  return [
    for (final item in list)
      if (item is Map<String, dynamic>)
        NamedRef(
          // Backend invoice validator looks up CompanyCurrency by
          // `currency_id`, so surface that value as our `id` — the
          // CompanyCurrency record's own `id` is useless to downstream
          // callers.
          id: ((item['currency_id'] ?? item['id']) as num).toInt(),
          name: (item['currency']?['name'] ??
                  item['currency']?['code'] ??
                  item['name'] ??
                  '')
              .toString(),
        ),
  ];
}

final rolesProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.role),
);

final productUnitsProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.productUnit),
);

final categoriesRefProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.category),
);

final suppliersRefProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.supplier),
);

final productsRefProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.product),
);

/// Dropdown source for the POS / sale page. Hides `type=main` cashboxes
/// because those are dedicated to company-level money movements — only
/// `type=sale` cashboxes should accept POS sales, mirroring the web UI.
final cashboxesRefProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.cashbox, query: {'type': 'sale'}),
);

final clientsRefProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.client),
);

final brandsRefProvider = FutureProvider<List<NamedRef>>(
  (ref) => _fetchList(ApiEndpoints.brand),
);

/// Currency metadata the sale page needs beyond just `{id, name}` — most
/// importantly `round_mark`, which controls the rounding precision the
/// backend applies to invoice totals. Mobile must round payments the
/// same way, otherwise the backend's strict `totalPayment !==
/// invoicePrice` check rejects the sale (`messages.payment_not_enough`).
///
/// UZS uses `round_mark = -3` (round to nearest 1000), so 10 sum on the
/// mobile UI gets rounded to 0 by the backend and the sale fails unless
/// the client rounds the same way.
class CurrencyMeta {
  const CurrencyMeta({
    required this.currencyId,
    required this.name,
    required this.roundMark,
  });

  final int currencyId;
  final String name;
  final int roundMark;

  /// Mirrors `sale.service.ts::roundByCurrency`. See [roundMark] for the
  /// semantics of each branch.
  double round(double value) {
    if (roundMark == 0) return value.roundToDouble();
    if (roundMark > 0) {
      final p = _pow10(roundMark);
      return (value * p).round() / p;
    }
    final factor = _pow10(-roundMark);
    return (value / factor).round() * factor;
  }

  static double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }
}

final currencyMetasProvider =
    FutureProvider<List<CurrencyMeta>>((ref) async {
  try {
    final response = await sl<ApiClient>().get<dynamic>(
      ApiEndpoints.currency,
      query: {'page': 1, 'limit': 100},
    );
    final list = response is Map<String, dynamic>
        ? (response['data'] ?? response['items'] ?? response['rows'])
                as List? ??
            const []
        : response is List
            ? response
            : const [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>)
          CurrencyMeta(
            currencyId:
                ((item['currency_id'] ?? item['id']) as num).toInt(),
            name: (item['currency']?['name'] ??
                    item['currency']?['code'] ??
                    item['name'] ??
                    '')
                .toString(),
            roundMark: ((item['currency']?['round_mark'] ??
                    item['round_mark'] ??
                    0) as num)
                .toInt(),
          ),
    ];
  } on AppException {
    return const [];
  }
});
