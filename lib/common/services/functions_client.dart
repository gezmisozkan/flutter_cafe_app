import 'package:cloud_functions/cloud_functions.dart';

class FunctionsClient {
  FunctionsClient._();
  static final instance = FunctionsClient._();

  Future<Map<String, dynamic>> createPaymentIntent(
    Map<String, Object?> payload,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createPaymentIntent',
      );
      final res = await callable.call<Map<String, dynamic>>(payload);
      return (res.data as Map).cast<String, dynamic>();
    } catch (_) {
      // Stubbed params for MVP
      return {'client_secret': 'stub_secret'};
    }
  }

  Future<Map<String, dynamic>> confirmCheckout(
    Map<String, Object?> payload,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'confirmCheckout',
      );
      final res = await callable.call<Map<String, dynamic>>(payload);
      return (res.data as Map).cast<String, dynamic>();
    } catch (_) {
      // Stubbed order id for MVP
      return {'order_id': DateTime.now().millisecondsSinceEpoch.toString()};
    }
  }

  Future<Map<String, dynamic>> applyPromo(Map<String, Object?> payload) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('applyPromo');
      final res = await callable.call<Map<String, dynamic>>(payload);
      return (res.data as Map).cast<String, dynamic>();
    } catch (_) {
      return {'discount_amount': 0};
    }
  }
}
