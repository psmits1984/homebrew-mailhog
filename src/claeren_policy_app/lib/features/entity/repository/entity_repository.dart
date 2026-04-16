import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/entity_model.dart';

final entityRepositoryProvider = Provider<EntityRepository>((ref) {
  return EntityRepository(ref.read(apiClientProvider));
});

class EntityRepository {
  final ApiClient _api;
  const EntityRepository(this._api);

  Future<List<EntityModel>> getEntiteiten() async {
    final res = await _api.get(ApiConstants.entiteiten);
    return (res.data as List)
        .map((e) => EntityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
