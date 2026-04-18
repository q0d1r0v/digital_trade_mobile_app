import '../constants/api_endpoints.dart';
import 'secure_storage.dart';

/// Token-specific facade over [SecureStorage]. Callers never touch key strings.
class TokenStorage {
  TokenStorage(this._storage);
  final SecureStorage _storage;

  Future<String?> getAccessToken() => _storage.read(StorageKeys.accessToken);
  Future<String?> getRefreshToken() => _storage.read(StorageKeys.refreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(StorageKeys.accessToken, accessToken),
      _storage.write(StorageKeys.refreshToken, refreshToken),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(StorageKeys.accessToken),
      _storage.delete(StorageKeys.refreshToken),
    ]);
  }

  Future<bool> get hasTokens async {
    final access = await getAccessToken();
    return access != null && access.isNotEmpty;
  }
}
