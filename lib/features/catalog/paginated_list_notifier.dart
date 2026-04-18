import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failure.dart';
import '../../core/models/named_ref.dart';
import 'catalog_service.dart';

/// Immutable snapshot of a paginated list view. Kept as a plain class
/// rather than a sealed union so `copyWith` reads naturally from widgets.
class PaginatedListState {
  const PaginatedListState({
    this.items = const [],
    this.page = 0,
    this.total,
    this.hasMore = true,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.query = '',
  });

  final List<NamedRef> items;
  final int page;
  final int? total;
  final bool hasMore;
  final bool loading;
  final bool loadingMore;
  final Failure? error;
  final String query;

  PaginatedListState copyWith({
    List<NamedRef>? items,
    int? page,
    int? total,
    bool? hasMore,
    bool? loading,
    bool? loadingMore,
    Failure? error,
    bool clearError = false,
    String? query,
  }) =>
      PaginatedListState(
        items: items ?? this.items,
        page: page ?? this.page,
        total: total ?? this.total,
        hasMore: hasMore ?? this.hasMore,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        error: clearError ? null : error ?? this.error,
        query: query ?? this.query,
      );

  bool get isInitial => page == 0 && !loading;
}

/// Owns pagination for one endpoint. Drives any list widget:
///   - first build calls `refresh()` (fetches page 1)
///   - scrolling near bottom → `loadMore()` appends page N+1
///   - pull-to-refresh → `refresh()` resets to page 1
///   - typing a search query → debounced `refresh(query: ...)`
class PaginatedListNotifier extends StateNotifier<PaginatedListState> {
  PaginatedListNotifier({
    required CatalogService service,
    required this.path,
    this.pageSize = 20,
    this.extraQuery = const {},
    this.searchParam,
  })  : _service = service,
        super(const PaginatedListState()) {
    refresh();
  }

  final CatalogService _service;
  final String path;
  final int pageSize;
  final Map<String, dynamic> extraQuery;

  /// Backend-specific search query key (`q`, `search`, or `name_like`).
  /// Supply only if the endpoint actually supports it — otherwise we
  /// skip sending the search param and filter client-side.
  final String? searchParam;

  Future<void> refresh({String? query}) async {
    final effectiveQuery = query ?? state.query;
    state = state.copyWith(
      loading: true,
      clearError: true,
      query: effectiveQuery,
    );
    final result = await _service.page(
      path,
      page: 1,
      limit: pageSize,
      query: _buildQuery(effectiveQuery),
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(loading: false, error: f),
      (resp) => state = state.copyWith(
        items: resp.items,
        page: 1,
        total: resp.total,
        hasMore: resp.items.length >= pageSize &&
            (resp.total == null || resp.items.length < resp.total!),
        loading: false,
        clearError: true,
      ),
    );
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.loading || !state.hasMore) return;
    state = state.copyWith(loadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    final result = await _service.page(
      path,
      page: nextPage,
      limit: pageSize,
      query: _buildQuery(state.query),
    );
    if (!mounted) return;
    result.fold(
      (f) => state = state.copyWith(loadingMore: false, error: f),
      (resp) {
        final combined = [...state.items, ...resp.items];
        state = state.copyWith(
          items: combined,
          page: nextPage,
          total: resp.total,
          hasMore: resp.items.length >= pageSize &&
              (resp.total == null || combined.length < resp.total!),
          loadingMore: false,
        );
      },
    );
  }

  void setQuery(String q) {
    if (q == state.query) return;
    refresh(query: q);
  }

  Map<String, dynamic> _buildQuery(String q) {
    if (q.isEmpty) return extraQuery;
    if (searchParam != null) {
      return {...extraQuery, searchParam!: q};
    }
    return extraQuery;
  }
}

