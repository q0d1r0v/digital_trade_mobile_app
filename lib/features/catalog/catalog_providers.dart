import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/di/injection.dart';
import 'catalog_service.dart';
import 'paginated_list_notifier.dart';

final catalogServiceProvider = Provider<CatalogService>((ref) => sl());

/// Creates a `PaginatedListNotifier` and **keeps it alive** for a short
/// grace period after the last listener disappears. This prevents the
/// "every time I open this page the list refetches" problem: a user
/// drawer-navigating between Cashboxes → Categories → back to Cashboxes
/// reuses the cached data instead of firing fresh requests on every
/// visit, which had been pegging slow devices into ANR.
///
/// Lists still refresh on:
///   - pull-to-refresh (explicit user action)
///   - `ref.invalidate(...)` after create / update / delete
PaginatedListNotifier _paginated(
  Ref ref, {
  required String path,
  Map<String, dynamic> extraQuery = const {},
  String? searchParam,
}) {
  // Hold the state for 5 minutes of inactivity — plenty for navigation
  // churn, short enough that stale data doesn't surprise the user.
  final link = ref.keepAlive();
  Timer? timer;
  ref.onDispose(() => timer?.cancel());
  ref.onCancel(() {
    timer = Timer(const Duration(minutes: 5), link.close);
  });
  ref.onResume(() => timer?.cancel());

  return PaginatedListNotifier(
    service: ref.watch(catalogServiceProvider),
    path: path,
    extraQuery: extraQuery,
    searchParam: searchParam,
  );
}

final cashboxListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.cashbox),
);

final categoryListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.category),
);

final brandListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.brand),
);

final supplierListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.supplier),
);

final clientListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.client),
);

final productListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.product),
);

final inputInvoiceListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.inputInvoice),
);

final saleInvoiceListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.saleInvoice),
);

final userListProvider = StateNotifierProvider.autoDispose<
    PaginatedListNotifier, PaginatedListState>(
  (ref) => _paginated(ref, path: ApiEndpoints.companyUser),
);
