import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';

/// Attaches the bearer access token to every outgoing request.
/// Refresh flow is handled separately in [RefreshTokenInterceptor].
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokens);
  final TokenStorage _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] == true) {
      handler.next(options);
      return;
    }
    final token = await _tokens.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
