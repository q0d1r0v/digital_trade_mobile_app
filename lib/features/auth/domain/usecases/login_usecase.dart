import 'package:equatable/equatable.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class LoginUseCase implements UseCase<AuthTokens, LoginParams> {
  LoginUseCase(this._repo);
  final AuthRepository _repo;

  @override
  AsyncResult<AuthTokens> call(LoginParams params) =>
      _repo.login(email: params.email, password: params.password);
}
