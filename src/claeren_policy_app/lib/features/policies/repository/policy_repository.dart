import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/policy_model.dart';

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return PolicyRepository(ref.read(apiClientProvider));
});

class PolicyRepository {
  final ApiClient _api;
  const PolicyRepository(this._api);

  Future<List<PolicyModel>> getPolissen(String entityId) async {
    final res = await _api.get(ApiConstants.polissen(entityId));
    return (res.data as List)
        .map((p) => PolicyModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<PolicyDetailModel?> getPolisDetail(String entityId, String polisNummer) async {
    final res = await _api.get(ApiConstants.polisDetail(entityId, polisNummer));
    if (res.data == null) return null;
    return PolicyDetailModel.fromJson(res.data as Map<String, dynamic>);
  }
}
