import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_exception.dart';
import 'failure.dart';

/// Converts low-level `DioException` into typed `AppException` for the data layer.
AppException mapDioException(DioException e) {
  // Log the raw server response once so we can see exactly what the
  // backend sent back — validation details, unexpected shapes, etc.
  // Debug-only; release builds stay silent.
  if (kDebugMode) {
    final resp = e.response;
    if (resp != null) {
      debugPrint(
        '[API ERROR] ${resp.requestOptions.method} '
        '${resp.requestOptions.uri}\n'
        '  status=${resp.statusCode}\n'
        '  body=${resp.data}',
      );
    } else {
      debugPrint('[API ERROR] ${e.requestOptions.uri}: ${e.message}');
    }
  }

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const TimeoutException();
    case DioExceptionType.connectionError:
      return const NetworkException();
    case DioExceptionType.cancel:
      return const UnknownException('Request cancelled');
    case DioExceptionType.badCertificate:
      return const ServerException('Bad SSL certificate');
    case DioExceptionType.unknown:
      return UnknownException(e.message ?? 'Unknown error');
    case DioExceptionType.badResponse:
      return _mapBadResponse(e);
  }
}

AppException _mapBadResponse(DioException e) {
  final status = e.response?.statusCode ?? 0;
  final data = e.response?.data;
  final message = _extractMessage(data) ?? e.message ?? 'Server error';
  final code = _extractCode(data);

  return switch (status) {
    400 => ValidationException(message, fieldErrors: _extractFieldErrors(data)),
    401 => UnauthorizedException(message),
    403 => ForbiddenException(message),
    404 => NotFoundException(message),
    422 => ValidationException(message, fieldErrors: _extractFieldErrors(data)),
    >= 500 => ServerException(message, code: code, statusCode: status),
    _ => ServerException(message, code: code, statusCode: status),
  };
}

String? _extractMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final m = data['message'] ?? data['error'] ?? data['detail'];
    if (m is String) return _humanize(m);
    // NestJS class-validator returns `message: string[]` for 400/422.
    // Join all so the user sees every failing field, not just the first.
    if (m is List && m.isNotEmpty) {
      return m.map((e) => _humanize(e.toString())).join('\n');
    }
  }
  return null;
}

/// Translates known backend error keys (e.g. `cashbox.errors.
/// main_cashbox_exists`) into short user-readable messages. Unknown
/// keys fall through unchanged so nothing is silently swallowed.
///
/// Kept as a plain map rather than going through the i18n provider
/// because [mapDioException] runs below the widget tree and has no
/// access to `ref`. The set is small enough to stay in sync manually.
String _humanize(String raw) {
  final mapped = _backendErrorMessages[raw];
  return mapped ?? raw;
}

const Map<String, String> _backendErrorMessages = {
  // Cashbox
  'cashbox.errors.main_cashbox_exists':
      "Asosiy (main) kassa allaqachon mavjud — faqat bitta ruxsat etiladi.",
  'cashbox.errors.sale_cashbox_exists':
      "Bu nomli sotuv kassasi allaqachon mavjud.",

  // Auth
  'auth.errors.invalid_credentials':
      "Email yoki parol noto'g'ri.",
  'auth.errors.email_already_exists':
      "Bu email bilan hisob allaqachon bor.",
  'auth.errors.company_unique_name_exists':
      "Bu kompaniya nomi band — boshqasini tanlang.",

  // Plan
  'plan.errors.limit_reached':
      "Tarifingiz chegarasiga yetdingiz — yangisini qo'shish uchun yuqori tarifga o'ting.",
  'plan.errors.feature_not_available':
      "Ushbu funksiya sizning tarifingizda mavjud emas.",

  // Product
  'product.errors.name_exists':
      "Bu nomli mahsulot allaqachon mavjud.",
  'product.errors.code_exists':
      "Bu kod/barkod boshqa mahsulotda ishlatilgan.",

  // Supplier / client
  'supplier.errors.name_exists': "Bu nomli ta'minotchi allaqachon mavjud.",
  'client.errors.name_exists': "Bu nomli mijoz allaqachon mavjud.",

  // Invoice
  'invoice.errors.product_out_of_stock':
      "Mahsulot ombordagi qoldiqdan ko'proq.",
  'invoice.errors.invalid_status': "Hujjat holatini o'zgartirish mumkin emas.",
};

String? _extractCode(dynamic data) {
  if (data is Map<String, dynamic>) {
    final c = data['code'] ?? data['errorCode'];
    if (c is String) return c;
  }
  return null;
}

Map<String, List<String>> _extractFieldErrors(dynamic data) {
  if (data is! Map<String, dynamic>) return const {};
  final errors = data['errors'];
  if (errors is! Map<String, dynamic>) return const {};

  return errors.map((key, value) {
    final messages = value is List
        ? value.map((e) => e.toString()).toList()
        : [value.toString()];
    return MapEntry(key, messages);
  });
}

/// Converts a data-layer [AppException] into a domain-layer [Failure].
/// Called from repository implementations.
Failure mapExceptionToFailure(Object exception) {
  return switch (exception) {
    NetworkException() => NetworkFailure(exception.message),
    TimeoutException() => TimeoutFailure(exception.message),
    UnauthorizedException() => UnauthorizedFailure(exception.message),
    ForbiddenException() => ForbiddenFailure(exception.message),
    NotFoundException() => NotFoundFailure(exception.message),
    ValidationException() =>
      ValidationFailure(exception.message, fieldErrors: exception.fieldErrors),
    ServerException() => ServerFailure(
        exception.message,
        code: exception.code,
        statusCode: exception.statusCode,
      ),
    CacheException() => CacheFailure(exception.message),
    AppException() => UnknownFailure(exception.message),
    _ => const UnknownFailure(),
  };
}
