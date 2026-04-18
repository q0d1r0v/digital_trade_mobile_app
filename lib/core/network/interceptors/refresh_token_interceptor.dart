import 'dart:async';

import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../../storage/token_storage.dart';

typedef OnAuthFailed = Future<void> Function();

/// Access-token refresh + retry handler.
///
/// Contract:
/// 1. When a protected request returns **401**, we attempt to refresh
///    tokens once, then replay the original request with the fresh
///    access token.
/// 2. If N concurrent requests race into 401 at the same time, they all
///    wait on a single refresh Future (Completer mutex) — the backend
///    only sees one `POST /refresh`.
/// 3. A request that has already been retried (`extra._retried == true`)
///    never retries again; we bubble the error up.
/// 4. 401s on the auth endpoints themselves (login/register/refresh) are
///    passed through untouched — retrying them would loop.
/// 5. When refresh itself fails (invalid/expired refresh token) we call
///    [onAuthFailed] which clears local session state and lets the
///    router redirect to `/login`.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required Dio refreshDio,
    required TokenStorage tokens,
    required this.onAuthFailed,
  })  : _refreshDio = refreshDio,
        _tokens = tokens;

  final Dio _refreshDio;
  final TokenStorage _tokens;
  final OnAuthFailed onAuthFailed;

  /// Currently-in-flight refresh attempt. Concurrent 401 errors await
  /// this so the refresh endpoint is only hit once per burst.
  Completer<void>? _refreshCompleter;

  /// Per-request retry marker stashed in `RequestOptions.extra`.
  static const _retriedKey = '_refreshRetried';

  /// Paths where a 401 must pass straight through.
  static bool _isAuthEndpoint(String path) {
    return path.endsWith(ApiEndpoints.login) ||
        path.endsWith(ApiEndpoints.register) ||
        path.endsWith(ApiEndpoints.refresh);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    final request = err.requestOptions;

    // Only 401s trigger refresh. Anything else (network error, 500, …)
    // is handled elsewhere.
    if (status != 401) {
      handler.next(err);
      return;
    }

    // Never refresh on the refresh endpoint itself, or on the login/
    // register endpoints — those 401s mean "bad credentials".
    if (_isAuthEndpoint(request.path)) {
      handler.next(err);
      return;
    }

    // Guard against infinite retry loops: if we already replayed this
    // request once, surface the error.
    if (request.extra[_retriedKey] == true) {
      await _surrenderSession();
      handler.next(err);
      return;
    }

    try {
      // Serialise concurrent 401s onto a single refresh attempt.
      if (_refreshCompleter != null) {
        await _refreshCompleter!.future;
      } else {
        final completer = Completer<void>();
        _refreshCompleter = completer;
        try {
          await _performRefresh();
          completer.complete();
        } catch (e, s) {
          completer.completeError(e, s);
          rethrow;
        } finally {
          _refreshCompleter = null;
        }
      }
    } catch (_) {
      // Refresh itself failed (refresh token expired / revoked / 401).
      // Clear local session and let the app route to /login.
      await _surrenderSession();
      handler.next(err);
      return;
    }

    // Refresh succeeded — replay the original request with the new
    // access token.
    try {
      final retried = await _retry(request);
      handler.resolve(retried);
    } on DioException catch (e) {
      // Retry returned another failure — let the upstream handle it
      // without attempting a second refresh (thanks to the retry flag).
      handler.next(e);
    } catch (e, s) {
      handler.next(
        DioException(
          requestOptions: request,
          type: DioExceptionType.unknown,
          error: e,
          stackTrace: s,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _performRefresh() async {
    final refreshToken = await _tokens.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token at all — treat as an auth failure.
      throw DioException(
        requestOptions: RequestOptions(path: ApiEndpoints.refresh),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: ApiEndpoints.refresh),
          statusCode: 401,
        ),
      );
    }

    final response = await _refreshDio.post<Map<String, dynamic>>(
      ApiEndpoints.refresh,
      data: {'refresh_token': refreshToken},
    );
    final data = response.data ?? const {};
    final newAccess =
        (data['access_token'] ?? data['accessToken']) as String?;
    final newRefresh =
        (data['refresh_token'] ?? data['refreshToken']) as String? ??
            refreshToken;

    if (newAccess == null || newAccess.isEmpty) {
      throw StateError('Refresh response missing access_token');
    }
    await _tokens.saveTokens(
      accessToken: newAccess,
      refreshToken: newRefresh,
    );
  }

  /// Replays [options] through the refresh-dio client (which has no auth
  /// interceptors), attaching the freshly-issued access token and the
  /// retry-guard flag so a future 401 doesn't loop through refresh again.
  Future<Response<dynamic>> _retry(RequestOptions options) async {
    final access = await _tokens.getAccessToken();
    final newOptions = Options(
      method: options.method,
      headers: {
        ...options.headers,
        if (access != null && access.isNotEmpty)
          'Authorization': 'Bearer $access',
      },
      responseType: options.responseType,
      contentType: options.contentType,
      sendTimeout: options.sendTimeout,
      receiveTimeout: options.receiveTimeout,
      followRedirects: options.followRedirects,
      validateStatus: options.validateStatus,
      extra: {...options.extra, _retriedKey: true},
    );
    return _refreshDio.request<dynamic>(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: newOptions,
      cancelToken: options.cancelToken,
      onReceiveProgress: options.onReceiveProgress,
      onSendProgress: options.onSendProgress,
    );
  }

  Future<void> _surrenderSession() async {
    try {
      await onAuthFailed();
    } catch (_) {
      // Best-effort — even if the callback throws, we still want the
      // original 401 to propagate.
    }
  }
}
