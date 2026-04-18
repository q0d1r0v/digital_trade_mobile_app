/// Data-layer exceptions. Repositories catch these and convert to [Failure].
sealed class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection']);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out']);
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, this.statusCode});
  final int? statusCode;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Unauthorized']);
}

class ForbiddenException extends AppException {
  const ForbiddenException([super.message = 'Forbidden']);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

class ValidationException extends AppException {
  const ValidationException(super.message, {this.fieldErrors = const {}});
  final Map<String, List<String>> fieldErrors;
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error']);
}

class UnknownException extends AppException {
  const UnknownException([super.message = 'Unknown error']);
}
