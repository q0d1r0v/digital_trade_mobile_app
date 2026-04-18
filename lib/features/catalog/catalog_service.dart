import 'package:fpdart/fpdart.dart';

import '../../core/error/app_exception.dart';
import '../../core/error/error_mapper.dart';
import '../../core/error/failure.dart';
import '../../core/models/named_ref.dart';
import '../../core/network/api_client.dart';
import '../../core/network/paginated_response.dart';
import '../../core/utils/result.dart';

/// Full CRUD service for every `{id, name, ...}` resource on the backend.
/// The REST contract is symmetrical across resources (list / create /
/// detail / update / delete / restore), so one generic client covers
/// cashbox, category, supplier, client, product, invoice, and user.
class CatalogService {
  CatalogService(this._api);
  final ApiClient _api;

  // ─── List ────────────────────────────────────────────────────────────

  AsyncResult<PaginatedResponse<NamedRef>> page(
    String path, {
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _api.get<dynamic>(
        path,
        query: {'page': page, 'limit': limit, ...?query},
      );
      return Right(PaginatedResponse.from(response, NamedRef.fromJson));
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  AsyncResult<List<NamedRef>> list(
    String path, {
    int limit = 100,
    Map<String, dynamic>? query,
  }) async {
    final result = await page(path, page: 1, limit: limit, query: query);
    return result.map((p) => p.items);
  }

  // ─── Detail / Create / Update / Delete ───────────────────────────────

  /// Returns the raw JSON map for the detail endpoint. Features that need
  /// strongly-typed detail pages project it themselves; the generic
  /// service stays json-in-json-out because the fields vary per resource.
  AsyncResult<Map<String, dynamic>> detail(String path, int id) async {
    try {
      final response = await _api.get<dynamic>('$path/$id');
      if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is Map<String, dynamic>) return Right(data);
        return Right(response);
      }
      return const Left(UnknownFailure('Unexpected detail response shape'));
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  AsyncResult<NamedRef> create(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _api.post<dynamic>(path, data: body);
      return Right(unwrapSingle(response, NamedRef.fromJson));
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  AsyncResult<NamedRef> update(
    String path,
    int id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _api.put<dynamic>('$path/$id', data: body);
      return Right(unwrapSingle(response, NamedRef.fromJson));
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Soft-delete (backend `deleted_at` timestamp). Matches the web
  /// frontend, which hides soft-deleted rows unless the user toggles the
  /// filter on.
  AsyncResult<void> softDelete(String path, int id) async {
    try {
      await _api.delete<dynamic>('$path/$id');
      return const Right(null);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Undoes a soft-delete. Backend exposes this at `PUT <path>/:id/restore`
  /// on most resources; a couple use `POST`. We try PUT first (the
  /// common case) and fall back for the rest if the endpoint 404s —
  /// callers that know the shape can override with [post].
  AsyncResult<void> restore(
    String path,
    int id, {
    bool post = false,
  }) async {
    try {
      if (post) {
        await _api.post<dynamic>('$path/$id/restore');
      } else {
        await _api.put<dynamic>('$path/$id/restore');
      }
      return const Right(null);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  /// Generic "action on a detail" verb (e.g. `POST {path}/:id/approve`,
  /// `POST {path}/:id/pay`). Keeps invoice-specific flows in the
  /// invoice feature file but lets them reuse the same error mapping.
  AsyncResult<void> action(
    String path,
    int id,
    String verb, {
    Map<String, dynamic>? body,
    bool isPut = false,
  }) async {
    try {
      final url = '$path/$id/$verb';
      if (isPut) {
        await _api.put<dynamic>(url, data: body);
      } else {
        await _api.post<dynamic>(url, data: body);
      }
      return const Right(null);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
