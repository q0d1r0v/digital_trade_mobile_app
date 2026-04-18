import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/usecases/login_usecase.dart';
import 'auth_providers.dart';

/// UI-facing login state.
sealed class LoginState {
  const LoginState();
}

class LoginIdle extends LoginState {
  const LoginIdle();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  const LoginSuccess();
}

class LoginError extends LoginState {
  const LoginError(this.failure);
  final Failure failure;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._login) : super(const LoginIdle());
  final LoginUseCase _login;

  Future<void> submit({required String email, required String password}) async {
    state = const LoginLoading();
    final result = await _login(LoginParams(email: email, password: password));
    state = result.fold(
      (failure) => LoginError(failure),
      (_) => const LoginSuccess(),
    );
  }

  void reset() => state = const LoginIdle();
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, LoginState>(
  (ref) => LoginController(ref.read(loginUseCaseProvider)),
);
