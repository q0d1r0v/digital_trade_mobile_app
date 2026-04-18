import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

/// Canonical return type for repositories and use cases.
/// Left = domain failure, Right = success value.
typedef Result<T> = Either<Failure, T>;

typedef AsyncResult<T> = Future<Result<T>>;
