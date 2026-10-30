import 'package:dio/dio.dart' hide Headers;
import 'package:fluttertoast/fluttertoast.dart';
import '../const/prefConstatnt.dart';
import '../const/preference.dart';

class ServerError implements Exception {
  int? _errorCode;
  String _errorMessage = "";

  ServerError.withError({error}) {
    _handleError(error);
  }

  getErrorCode() {
    return _errorCode;
  }

  getErrorMessage() {
    return _errorMessage;
  }

  _handleError(error) {
    if (error is DioException) {
      final response = error.response;
      final data = response?.data;
      final dataMap = data is Map ? data : null;
      final errorsMap = dataMap != null && dataMap['errors'] is Map ? dataMap['errors'] as Map : null;
      if (response?.statusCode == 401 && dataMap?['msg'] != null) {
        final isLoggedIn = SharedPreferenceHelper.getBoolean(Preferences.is_logged_in);
        final hasToken = SharedPreferenceHelper.getBoolean(Preferences.has_auth_token);
        if (!isLoggedIn || !hasToken) {
          return Fluttertoast.showToast(msg: '${dataMap?['msg'].toString()}');
        }
        return;
      } else if (dataMap?['error'] != null) {
        Fluttertoast.showToast(
          msg: '${dataMap?['error']}',
        );
        return;
      } else if (errorsMap?['email'] != null) {
        Fluttertoast.showToast(
          msg: '${errorsMap?['email'][0]}',
        );
        return;
      } else if (errorsMap?['name'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['name'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['phone'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['phone'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['email'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['email'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['phone_code'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['phone_code'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['dob'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['dob'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['gender'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['gender'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['password'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['password'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['time'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['time'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['date'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['date'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['payment_type'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['payment_type'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['review'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['review'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['rate'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['rate'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['appointment_id'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['appointment_id'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['otp'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['otp'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['appointment_for'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['appointment_for'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['illness_information'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['illness_information'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['patient_name'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['patient_name'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['age'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['age'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['patient_address'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['patient_address'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['phone_no'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['phone_no'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['drug_effect'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['drug_effect'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['note'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['note'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['amount'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['amount'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['image'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['image'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['medicines'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['medicines'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['old_password'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['old_password'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['password_confirmation'] != null) {
        Fluttertoast.showToast(msg: '${errorsMap?['password_confirmation'][0]}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (dataMap?['msg'] != null) {
        Fluttertoast.showToast(msg: '${dataMap?['msg']}', toastLength: Toast.LENGTH_SHORT, gravity: ToastGravity.BOTTOM);
        return;
      } else if (errorsMap?['phone'] != null) {
        Fluttertoast.showToast(
          msg: '${errorsMap?['phone'][0]}',
        );
        return;
      } else if (errorsMap?['confirm'] != null) {
        Fluttertoast.showToast(
          msg: '${errorsMap?['confirm'][0]}',
        );
        return;
      } else if (errorsMap?['password'] != null) {
        Fluttertoast.showToast(
          msg: '${errorsMap?['password'][0]}',
        );
        return;
      } else if (error.type == DioExceptionType.badResponse) {
        if (dataMap?['msg'] != null) {
          print(dataMap?['msg'].toString());
          return Fluttertoast.showToast(msg: '${dataMap?['msg'].toString()}');
        } else if (dataMap?['message'] != null) {
          print(dataMap?['message'].toString());
          return Fluttertoast.showToast(msg: '${dataMap?['message'].toString()}');
        }
      } else if (error.type == DioExceptionType.unknown) {
        if (dataMap?['msg'] != null) {
          print(dataMap?['msg'].toString());
          return Fluttertoast.showToast(msg: '${dataMap?['msg'].toString()}');
        }
      } else if (error.type == DioExceptionType.cancel) {
        return Fluttertoast.showToast(msg: 'Request was cancelled');
      } else if (error.type == DioExceptionType.connectionError) {
        return Fluttertoast.showToast(msg: 'Connection failed. Please check internet connection');
      } else if (error.type == DioExceptionType.connectionTimeout) {
        return Fluttertoast.showToast(msg: 'Connection timeout');
      } else if (error.type == DioExceptionType.badCertificate) {
        if (dataMap?['msg'] != null) {
          return Fluttertoast.showToast(msg: '${dataMap?['msg']}');
        }
      } else if (error.type == DioExceptionType.receiveTimeout) {
        return Fluttertoast.showToast(msg: 'Receive timeout in connection');
      } else if (error.type == DioExceptionType.sendTimeout) {
        return Fluttertoast.showToast(msg: 'Receive timeout in send request');
      }
      return _errorMessage;
    }
    Fluttertoast.showToast(msg: error.toString());
    return _errorMessage;
  }
}
