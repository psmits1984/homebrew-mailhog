import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/claim_model.dart';

final claimRepositoryProvider = Provider<ClaimRepository>((ref) {
  return ClaimRepository(ref.read(apiClientProvider));
});

class ClaimRepository {
  final ApiClient _api;
  const ClaimRepository(this._api);

  Future<List<ClaimModel>> getClaims(String entityId) async {
    final res = await _api.get(ApiConstants.claims(entityId));
    return (res.data as List)
        .map((c) => ClaimModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<String> meldClaim({
    required String entityId,
    required String polisNummer,
    required DateTime schadeDatum,
    required String omschrijving,
    String? locatie,
    double? schatting,
  }) async {
    final res = await _api.post(
      ApiConstants.claims(entityId),
      data: {
        'polisNummer': polisNummer,
        'schadeDatum': schadeDatum.toIso8601String(),
        'omschrijving': omschrijving,
        if (locatie != null) 'locatie': locatie,
        if (schatting != null) 'geschadeSchadeEstimatie': schatting,
      },
    );
    return (res.data as Map<String, dynamic>)['schadeNummer'] as String;
  }
}
