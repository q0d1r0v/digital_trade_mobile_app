import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_providers.dart';

/// UI-facing register state. Mirrors [LoginState] so the page code stays
/// uniform.
sealed class RegisterState {
  const RegisterState();
}

class RegisterIdle extends RegisterState {
  const RegisterIdle();
}

class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

class RegisterSuccess extends RegisterState {
  const RegisterSuccess();
}

class RegisterError extends RegisterState {
  const RegisterError(this.failure);
  final Failure failure;
}

class RegisterController extends StateNotifier<RegisterState> {
  RegisterController(this._register) : super(const RegisterIdle());
  final RegisterUseCase _register;

  Future<void> submit(RegisterParams params) async {
    state = const RegisterLoading();
    final result = await _register(params);
    state = result.fold(
      (failure) => RegisterError(failure),
      (_) => const RegisterSuccess(),
    );
  }

  void reset() => state = const RegisterIdle();
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, RegisterState>(
  (ref) => RegisterController(ref.read(registerUseCaseProvider)),
);
