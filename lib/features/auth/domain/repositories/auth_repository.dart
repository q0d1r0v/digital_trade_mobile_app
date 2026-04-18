import '../../../../core/utils/result.dart';
import '../entities/auth_tokens.dart';
import '../entities/user_entity.dart';

/// Request payload for the register endpoint. Mirrors the NestJS
/// `RegisterDto` (auth.dtos/register.dto.ts).
class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.companyName,
    required this.companyUniqueName,
    required this.companyType,
    required this.address,
    required this.planType,
  });

  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String gender; // male | female
  final String companyName;
  final String companyUniqueName;
  final String companyType; // physical | legal
  final String address;
  final String planType; // starter | business | enterprise

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'gender': gender,
        'company_name': companyName,
        'company_unique_name': companyUniqueName,
        'company_type': companyType,
        'address': address,
        'plan_type': planType,
      };
}

/// Contract exposed to the domain layer. The presentation and use-case layers
/// depend only on this interface — implementations live under `data/`.
abstract interface class AuthRepository {
  AsyncResult<AuthTokens> login({
    required String email,
    required String password,
  });

  AsyncResult<AuthTokens> register(RegisterParams params);

  AsyncResult<UserEntity> getCurrentUser();

  AsyncResult<void> logout();

  /// Wipes locally-cached tokens and emits `false` to [authStateChanges].
  /// Called by the refresh interceptor when refresh fails — skips the
  /// remote logout so we don't trigger another 401 storm.
  Future<void> clearSession();

  Future<bool> get isAuthenticated;

  Stream<bool> get authStateChanges;
}
