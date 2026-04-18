import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

/// Bridge from GetIt to Riverpod. Keeping the graph in GetIt means data
/// sources & repos can be used outside the widget tree; Riverpod only
/// handles UI-facing reactive state.
final authRepositoryProvider = Provider<AuthRepository>((ref) => sl());
final loginUseCaseProvider = Provider<LoginUseCase>((ref) => sl());
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) => sl());
final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) => sl());
final getCurrentUserUseCaseProvider =
    Provider<GetCurrentUserUseCase>((ref) => sl());

/// Emits the current auth state. Used by the router's `refreshListenable`
/// so navigation reacts instantly to login/logout.
final authStateProvider = StreamProvider<bool>((ref) async* {
  final repo = ref.watch(authRepositoryProvider);
  yield await repo.isAuthenticated;
  yield* repo.authStateChanges;
});
