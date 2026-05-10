import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _loginTypeKey = 'login_type';
  static const String _userIdKey = 'user_id';

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveLoginType(String type) => _storage.write(key: _loginTypeKey, value: type);
  Future<String?> getLoginType() => _storage.read(key: _loginTypeKey);

  Future<void> saveUserId(String id) => _storage.write(key: _userIdKey, value: id);
  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _loginTypeKey);
    await _storage.delete(key: _userIdKey);
  }
}

