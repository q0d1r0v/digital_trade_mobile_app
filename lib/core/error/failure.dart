import 'package:equatable/equatable.dart';

/// Domain-layer error type. Never leaks HTTP / framework concerns.
///
/// UI and business code match on the sealed subtype and render an
/// appropriate message via the localization layer.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, this.statusCode});
  final int? statusCode;

  @override
  List<Object?> get props => [message, code, statusCode];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized']);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Forbidden']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
  final Map<String, List<String>> fieldErrors;

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error']);
}
