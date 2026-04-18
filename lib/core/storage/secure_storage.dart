import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around [FlutterSecureStorage] so the rest of the app
/// doesn't depend on the concrete package.
abstract interface class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class SecureStorageImpl implements SecureStorage {
  SecureStorageImpl(this._storage);
  final FlutterSecureStorage _storage;

  static const _options = AndroidOptions(encryptedSharedPreferences: true);

  @override
  Future<String?> read(String key) =>
      _storage.read(key: key, aOptions: _options);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value, aOptions: _options);

  @override
  Future<void> delete(String key) =>
      _storage.delete(key: key, aOptions: _options);

  @override
  Future<void> clear() => _storage.deleteAll(aOptions: _options);
}
