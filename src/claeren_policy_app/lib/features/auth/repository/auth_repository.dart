import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider), ref.read(secureStorageProvider));
});

class AuthRepository {
  final ApiClient _api;
  final SecureStorage _storage;

  const AuthRepository(this._api, this._storage);

  Future<LoginResponse> login(String username, String password) async {
    final res = await _api.post(
      ApiConstants.login,
      data: {'username': username, 'password': password},
    );
    return LoginResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LoginResponse> verifyTwoFactor(String sessionToken, String code) async {
    final res = await _api.post(
      ApiConstants.twoFactor,
      data: {'sessionToken': sessionToken, 'code': code},
    );
    return LoginResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OnboardingResponse> completeOnboarding({
    required String sessionToken,
    required String geboortedatum,
    required String postcode,
    required String huisnummer,
  }) async {
    final res = await _api.post(
      ApiConstants.onboarding,
      data: {
        'sessionToken': sessionToken,
        'geboortedatum': geboortedatum,
        'postcode': postcode,
        'huisnummer': huisnummer,
      },
    );
    return OnboardingResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> saveToken(String token) => _storage.saveToken(token);
  Future<void> logout() => _storage.clearAll();
}
