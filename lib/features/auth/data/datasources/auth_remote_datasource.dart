import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  });

  Future<AuthResponseModel> register(RegisterParams params);

  Future<UserModel> me();

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._api);
  final ApiClient _api;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
      options: Options(extra: const {'skipAuth': true}),
    );
    return AuthResponseModel.fromJson(json);
  }

  @override
  Future<AuthResponseModel> register(RegisterParams params) async {
    final json = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: params.toJson(),
      options: Options(extra: const {'skipAuth': true}),
    );
    return AuthResponseModel.fromJson(json);
  }

  @override
  Future<UserModel> me() async {
    final json = await _api.get<Map<String, dynamic>>(ApiEndpoints.authUser);
    return UserModel.fromJson(json);
  }

  @override
  Future<void> logout() async {
    // Backend has no dedicated logout endpoint (session is stateless JWT);
    // we just clear tokens locally. Left as a no-op here so the repository
    // keeps a consistent surface area.
    return;
  }
}
