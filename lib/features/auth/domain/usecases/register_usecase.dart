import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<AuthTokens, RegisterParams> {
  RegisterUseCase(this._repo);
  final AuthRepository _repo;

  @override
  AsyncResult<AuthTokens> call(RegisterParams params) => _repo.register(params);
}
