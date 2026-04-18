/// Normalises the two list shapes the backend returns:
/// 1. `{ data: [...], meta: { total, page, ... } }` — standard list
/// 2. `{ data: [...] }` — single object list (no meta)
/// 3. Plain `[...]` — rare but handled
class PaginatedResponse<T> {
  const PaginatedResponse({required this.items, this.total, this.page});

  final List<T> items;
  final int? total;
  final int? page;

  factory PaginatedResponse.from(
    dynamic raw,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (raw is List) {
      return PaginatedResponse(
        items: raw.whereType<Map<String, dynamic>>().map(parse).toList(),
      );
    }
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['items'] ?? raw['rows'];
      final meta = raw['meta'] as Map<String, dynamic>?;
      final list = data is List
          ? data.whereType<Map<String, dynamic>>().map(parse).toList()
          : <T>[];
      return PaginatedResponse(
        items: list,
        total: (meta?['total'] ?? raw['total']) as int?,
        page: (meta?['page'] ?? raw['page']) as int?,
      );
    }
    return PaginatedResponse(items: const []);
  }
}

/// Unwraps `{ data: T, message: string }` single-object responses.
T unwrapSingle<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw is Map<String, dynamic>) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return parse(data);
    return parse(raw);
  }
  throw FormatException('Expected object response, got ${raw.runtimeType}');
}
