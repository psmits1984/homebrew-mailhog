import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/naverrrekening_model.dart';

final navRepoProvider = Provider<NaverrekenRepository>((ref) {
  return NaverrekenRepository(ref.read(apiClientProvider));
});

class NaverrekenRepository {
  final ApiClient _api;
  const NaverrekenRepository(this._api);

  Future<List<NaverrekenUitvraag>> getUitvragen(String entityId) async {
    final res = await _api.get(ApiConstants.naverrrekening(entityId));
    return (res.data as List)
        .map((u) => NaverrekenUitvraag.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<void> beantwoord({
    required String entityId,
    required String uitvraagId,
    required Map<String, String> antwoorden,
  }) async {
    await _api.post(
      ApiConstants.navAntwoorden(entityId, uitvraagId),
      data: {
        'uitvraagId': uitvraagId,
        'antwoorden': antwoorden.entries
            .map((e) => {'vraagId': e.key, 'waarde': e.value})
            .toList(),
      },
    );
  }
}
