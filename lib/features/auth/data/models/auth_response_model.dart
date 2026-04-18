import '../../domain/entities/auth_tokens.dart';
import 'user_model.dart';

/// Mirrors the NestJS TokenResponse shape
/// (`src/base/interfaces/jwt-payload.interface.ts`).
class AuthResponseModel {
  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int? expiresIn;
  final UserModel? user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    // Backend uses snake_case; support both just in case a future version
    // or a different gateway rewrites the response.
    final access = (json['access_token'] ?? json['accessToken']) as String?;
    final refresh = (json['refresh_token'] ?? json['refreshToken']) as String?;
    if (access == null || refresh == null) {
      throw FormatException(
        'Malformed auth response: missing access/refresh token. Got keys: '
        '${json.keys.toList()}',
      );
    }
    return AuthResponseModel(
      accessToken: access,
      refreshToken: refresh,
      tokenType: (json['token_type'] ?? 'Bearer') as String,
      expiresIn: (json['expires_in'] ?? json['expiresIn']) as int?,
      user: json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  AuthTokens toTokens() =>
      AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
}
