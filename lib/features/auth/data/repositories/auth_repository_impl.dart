import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required TokenStorage tokens,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _tokens = tokens,
        _networkInfo = networkInfo;

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokens;
  final NetworkInfo _networkInfo;

  final StreamController<bool> _authController =
      StreamController<bool>.broadcast();

  @override
  Stream<bool> get authStateChanges => _authController.stream;

  @override
  Future<bool> get isAuthenticated => _tokens.hasTokens;

  @override
  AsyncResult<AuthTokens> login({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final response = await _remote.login(email: email, password: password);
        await _tokens.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        _authController.add(true);
        return response.toTokens();
      });

  @override
  AsyncResult<AuthTokens> register(RegisterParams params) => _guard(() async {
        final response = await _remote.register(params);
        await _tokens.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        _authController.add(true);
        return response.toTokens();
      });

  @override
  AsyncResult<UserEntity> getCurrentUser() =>
      _guard(() async => (await _remote.me()).toEntity());

  @override
  AsyncResult<void> logout() => _guard(() async {
        try {
          await _remote.logout();
        } catch (_) {
          // Ignore: we still want to clear local state on any network failure.
        }
        await _tokens.clear();
        _authController.add(false);
      });

  @override
  Future<void> clearSession() async {
    // No remote call here — the refresh interceptor already failed the
    // refresh; hitting logout would 401 again and loop.
    await _tokens.clear();
    if (!_authController.isClosed) _authController.add(false);
  }

  /// Shared try/catch + online check so each method stays one-liner.
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      return Right(await action());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
