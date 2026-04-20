import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/payment_model.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(apiClientProvider));
});

class PaymentRepository {
  final ApiClient _api;
  const PaymentRepository(this._api);

  Future<List<PaymentModel>> getBetalingen(String entityId) async {
    final res = await _api.get(ApiConstants.betalingen(entityId));
    return (res.data as List)
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
