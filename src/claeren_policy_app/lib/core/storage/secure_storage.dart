import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

class SecureStorage {
  // Web: iOptions zorgt voor localStorage-gebaseerde opslag
  // iOS: Keychain  |  Android: EncryptedSharedPreferences
  static final _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    wOptions: WebOptions(dbName: 'claeren_secure', publicKey: 'claeren_pk'),
  );

  static const _keyToken = 'jwt_token';
  static const _keyEntityId = 'selected_entity_id';

  Future<void> saveToken(String token) => _storage.write(key: _keyToken, value: token);
  Future<String?> getToken() => _storage.read(key: _keyToken);
  Future<void> deleteToken() => _storage.delete(key: _keyToken);

  Future<void> saveSelectedEntity(String entityId) =>
      _storage.write(key: _keyEntityId, value: entityId);
  Future<String?> getSelectedEntity() => _storage.read(key: _keyEntityId);

  Future<void> clearAll() => _storage.deleteAll();
}
