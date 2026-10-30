import 'dart:async';
import 'package:doctro_patient/api/apis.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';

/// PayPal calls go through the backend, which holds the PayPal secret.
class PaypalServices {
  Future<Map<String, String>> createPaypalPayment({required String total, required String returnUrl, required String cancelUrl}) async {
    final response = await RetroApi().dioData().post(
      '${Apis.baseUrl}paypal/create_payment',
      data: {"amount": total, "return_url": returnUrl, "cancel_url": cancelUrl},
    );
    final data = response.data['data'];
    return {"paymentId": data['id'].toString(), "approvalUrl": data['approval_url'].toString()};
  }

  Future<String?> executePayment(String paymentId, String payerId) async {
    final response = await RetroApi().dioData().post(
      '${Apis.baseUrl}paypal/execute_payment',
      data: {"payment_id": paymentId, "payer_id": payerId},
    );
    return response.data['data']?['id']?.toString();
  }
}
