import 'package:dio/dio.dart';

import '../../error/error_mapper.dart';

/// Converts raw [DioException] into our typed [AppException] so data sources
/// only ever catch a single exception type.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = mapDioException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: mapped,
        stackTrace: err.stackTrace,
        message: mapped.message,
      ),
    );
  }
}
