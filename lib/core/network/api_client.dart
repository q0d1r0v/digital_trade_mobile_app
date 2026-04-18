import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../error/error_mapper.dart';

/// Typed facade over [Dio]. Data sources depend on this, not on Dio directly,
/// which makes them trivial to mock and keeps the dependency surface small.
class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _call(() => _dio.get<T>(path, queryParameters: query, options: options));
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _call(() => _dio.post<T>(
          path,
          data: data,
          queryParameters: query,
          options: options,
        ));
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _call(() => _dio.put<T>(
          path,
          data: data,
          queryParameters: query,
          options: options,
        ));
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _call(() => _dio.patch<T>(
          path,
          data: data,
          queryParameters: query,
          options: options,
        ));
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return _call(() => _dio.delete<T>(
          path,
          data: data,
          queryParameters: query,
          options: options,
        ));
  }

  Future<T> _call<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      final data = response.data;
      if (data == null) {
        throw const ServerException('Empty response body');
      }
      return data;
    } on DioException catch (e) {
      // ErrorInterceptor has already converted e.error into an AppException.
      final err = e.error;
      if (err is AppException) throw err;
      throw mapDioException(e);
    }
  }
}
