import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<UserEntity, NoParams> {
  GetCurrentUserUseCase(this._repo);
  final AuthRepository _repo;

  @override
  AsyncResult<UserEntity> call(NoParams params) => _repo.getCurrentUser();
}
