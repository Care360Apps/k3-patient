import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/localization/localization_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/apis.dart';
import '../../api/retrofit_Api.dart';
import '../../api/base_model.dart';
import '../../api/network_api.dart';
import '../../api/server_error.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../model/book_appointments_model.dart';

class StripePayment extends ChangeNotifier {
  Map<String, dynamic>? paymentIntent;

  Future<void> makePayment({
    required BuildContext context,
    required String? selectAppointmentFor,
    required int? hospitalId,
    required String? patientName,
    required String? illnessInformation,
    required String? age,
    required String? patientAddress,
    required String? phoneNo,
    required String? selectDrugEffects,
    required String? note,
    required String? newDate,
    required String? selectTime,
    required String? appointmentFees,
    required int? doctorId,
    required String? newDateUser,
    required List<String>? reportImages,
    required bool isInsured,
    required String insurerName,
    required String policyNumber,
    String? offerCode,
  }) async {
    try {
      paymentIntent = await createPaymentIntent(appointmentFees!);
      //STEP 2: Initialize Payment Sheet
      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret:
                  paymentIntent!['client_secret'], //Gotten from payment intent
              style: ThemeMode.dark,
              merchantDisplayName: 'Doctro Patient',
            ),
          )
          .then((value) {});

      //STEP 3: Display Payment sheet
      displayPaymentSheet(
        newDate: newDate,
        reportImages: reportImages,
        newDateUser: newDateUser,
        doctorId: doctorId,
        appointmentFees: appointmentFees,
        selectTime: selectTime,
        note: note,
        selectDrugEffects: selectDrugEffects,
        phoneNo: phoneNo,
        patientAddress: patientAddress,
        age: age,
        illnessInformation: illnessInformation,
        patientName: patientName,
        hospitalId: hospitalId,
        selectAppointmentFor: selectAppointmentFor,
        context: context,
        policyNumber: policyNumber,
        insurerName: insurerName,
        isInsured: isInsured,
        offerCode: offerCode,
      );
    } catch (err) {
      throw Exception(err);
    }
  }

  displayPaymentSheet({
    required String? selectAppointmentFor,
    required int? hospitalId,
    required String? patientName,
    required String? illnessInformation,
    required String? age,
    required String? patientAddress,
    required String? phoneNo,
    required String? selectDrugEffects,
    required String? note,
    required String? newDate,
    required String? selectTime,
    required String? appointmentFees,
    required int? doctorId,
    required String? newDateUser,
    required List<String>? reportImages,
    required BuildContext context,
    required bool isInsured,
    required String insurerName,
    required String policyNumber,
    String? offerCode,
  }) async {
    try {
      await Stripe.instance
          .presentPaymentSheet()
          .then((value) {
            callApiBook(
              stripeToken: paymentIntent!["id"],
              context: context,
              selectAppointmentFor: selectAppointmentFor,
              hospitalId: hospitalId,
              patientName: patientName,
              illnessInformation: illnessInformation,
              age: age,
              patientAddress: patientAddress,
              phoneNo: phoneNo,
              selectDrugEffects: selectDrugEffects,
              note: note,
              selectTime: selectTime,
              appointmentFees: appointmentFees,
              doctorId: doctorId,
              newDateUser: newDateUser,
              reportImages: reportImages,
              newDate: newDate,
              isInsured: isInsured,
              insurerName: insurerName,
              policyNumber: policyNumber,
              offerCode: offerCode,
            );

            paymentIntent = null;
          })
          .onError((error, stackTrace) {
            throw Exception(error);
          });
    } on StripeException catch (e) {
      print('Error is:---> $e');
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red),
                Text(
                  getTranslated(context, AppString.paymentFailed).toString(),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      print('$e');
      AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.cancel, color: Colors.red),
                Text(
                  getTranslated(context, AppString.paymentFailed).toString(),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  /// The backend creates the intent (in the store currency) so the Stripe secret key stays on the server.
  Future<Map<String, dynamic>> createPaymentIntent(String amount) async {
    try {
      final response = await RetroApi().dioData().post(
        '${Apis.baseUrl}stripe/payment_intent',
        data: {'amount': amount},
      );
      return Map<String, dynamic>.from(response.data['data']);
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future<BaseModel<BookAppointments>> callApiBook({
    required String? selectAppointmentFor,
    required int? hospitalId,
    required String? patientName,
    required String? illnessInformation,
    required String? age,
    required String? patientAddress,
    required String? phoneNo,
    required String? selectDrugEffects,
    required String? note,
    required String? newDate,
    required String? selectTime,
    required String? appointmentFees,
    required int? doctorId,
    required String? newDateUser,
    required List<String>? reportImages,
    required String stripeToken,
    required BuildContext context,
    required bool isInsured,
    required String insurerName,
    required String policyNumber,
    String? offerCode,
  }) async {
    BookAppointments response;
    Map<String, dynamic> body = {
      "appointment_for": selectAppointmentFor,
      "patient_name": patientName,
      "illness_information": illnessInformation,
      "age": age,
      "patient_address": patientAddress,
      "phone_no": phoneNo,
      "drug_effect": selectDrugEffects,
      "note": note != "" ? note : "No note",
      "date": newDate,
      "time": selectTime,
      "payment_type": "Stripe",
      "payment_status": 1,
      "payment_token": stripeToken,
      "amount": appointmentFees,
      "doctor_id": doctorId,
      "report_image": reportImages!.length != 0 ? reportImages : "",
    };
    if (hospitalId != null && hospitalId != 0) {
      body["hospital_id"] = hospitalId;
    }
    if (offerCode != null && offerCode.isNotEmpty) {
      body["offer_code"] = offerCode;
    }
    if (isInsured == true) {
      body['is_insured'] = isInsured == true ? 1 : 0;
      body['policy_insurer_name'] = insurerName;
      body['policy_number'] = policyNumber;
    } else if (isInsured == false) {
      body['is_insured'] = isInsured == true ? 1 : 0;
    }
    print(body);
    Preferences.onLoading(context);
    notifyListeners();
    try {
      response = await RestClient(RetroApi().dioData()).bookAppointment(body);
      if (response.success == true) {
        Preferences.hideDialog(context);
        passBookID = response.data!;
        _passDateTime(
          newDate: newDate!,
          bookingId: passBookID,
          selectedTime: selectTime!,
        );
        Navigator.pushReplacementNamed(context, 'BookSuccess');
        Fluttertoast.showToast(
          msg: '${response.msg}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
      } else {
        Preferences.hideDialog(context);
        notifyListeners();
      }
    } catch (error, stacktrace) {
      Preferences.hideDialog(context);
      notifyListeners();
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  String? passBookDate = "";
  String? passBookTime = "";
  String passBookID = "";

  _passDateTime({
    required String newDate,
    required String selectedTime,
    required String bookingId,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    passBookDate = newDate;
    passBookTime = selectedTime;
    passBookID = '$bookingId';
    prefs.setString('BookDate', passBookDate!);
    prefs.setString('BookTime', passBookTime!);
    prefs.setString('BookID', passBookID);
  }
}
