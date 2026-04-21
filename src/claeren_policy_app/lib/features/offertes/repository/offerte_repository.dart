import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/offerte_model.dart';

final offerteRepositoryProvider = Provider<OfferteRepository>((ref) {
  return OfferteRepository(ref.read(apiClientProvider));
});

class OfferteRepository {
  final ApiClient _api;
  const OfferteRepository(this._api);

  Future<List<OfferteModel>> getOffertes(String entityId) async {
    final res = await _api.get(ApiConstants.offertes(entityId));
    return (res.data as List)
        .map((o) => OfferteModel.fromJson(o as Map<String, dynamic>))
        .toList();
  }

  Future<OfferteModel> getOfferte(String id) async {
    final res = await _api.get(ApiConstants.offerteDetail(id));
    return OfferteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OfferteModel> accorderen(String id) async {
    final res = await _api.post(ApiConstants.offerteAccorderen(id));
    return OfferteModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OfferteModel> weigeren(String id) async {
    final res = await _api.post(ApiConstants.offerteWeigeren(id));
    return OfferteModel.fromJson(res.data as Map<String, dynamic>);
  }
}
