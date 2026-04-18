import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/flavor_config.dart';
import '../storage/token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';

/// Builds two configured Dio instances:
///
/// * [buildApiClient] — the main client used by features. Has auth, refresh
///   and error interceptors wired in.
/// * [buildRefreshClient] — a minimal client used by the refresh interceptor
///   itself. Kept separate to avoid re-entrancy.
class DioFactory {
  DioFactory({required this.config, required this.tokens});

  final FlavorConfig config;
  final TokenStorage tokens;

  BaseOptions get _baseOptions => BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // Default is `ListFormat.multi` which serialises an array as
        // `date=from&date=to`. NestJS (and the web frontend) expect the
        // bracketed form `date[]=from&date[]=to` — switch globally so
        // dashboard date-range filters actually reach the backend.
        listFormat: ListFormat.multiCompatible,
      );

  Dio buildRefreshClient() {
    final dio = Dio(_baseOptions);
    if (config.enableLogging) {
      dio.interceptors.add(_loggingInterceptor());
    }
    return dio;
  }

  Dio buildApiClient({required Future<void> Function() onAuthFailed}) {
    final dio = Dio(_baseOptions);
    final refreshDio = buildRefreshClient();

    dio.interceptors.addAll([
      AuthInterceptor(tokens),
      RefreshTokenInterceptor(
        refreshDio: refreshDio,
        tokens: tokens,
        onAuthFailed: onAuthFailed,
      ),
      ErrorInterceptor(),
      if (config.enableLogging) _loggingInterceptor(),
    ]);

    return dio;
  }

  PrettyDioLogger _loggingInterceptor() => PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 120,
      );
}
