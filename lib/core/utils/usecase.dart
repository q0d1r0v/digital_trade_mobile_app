import 'result.dart';

/// Single-method use case contract. Keeping it tiny removes boilerplate
/// while still giving each business action a stable name and test seam.
abstract interface class UseCase<Output, Params> {
  AsyncResult<Output> call(Params params);
}

/// Use when a use case takes no parameters.
class NoParams {
  const NoParams();
}
