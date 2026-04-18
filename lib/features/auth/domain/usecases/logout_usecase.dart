import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/auth_repository.dart';

class LogoutUseCase implements UseCase<void, NoParams> {
  LogoutUseCase(this._repo);
  final AuthRepository _repo;

  @override
  AsyncResult<void> call(NoParams params) => _repo.logout();
}
