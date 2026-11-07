import '../../brand/care360_entry.dart';
import '../../api/patient_optional_settings.dart';
import '../../api/care360_connection_error.dart';
import '../../api/apis.dart';
import 'package:doctro_patient/FirebaseProviders/auth_provider.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/model/login_model.dart';
import 'package:doctro_patient/Screen/Authentication/phoneverification.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:location/location.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctro_patient/api/base_model.dart';
import 'package:doctro_patient/api/server_error.dart';
import 'package:doctro_patient/const/Palette.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/localization/localization_constant.dart';
import 'package:doctro_patient/model/detail_setting_model.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool _isHidden = true;
  bool _loginInProgress = false;

  String? msg = "";
  String? deviceToken = "";

  int? verify = 0;
  int? id = 0;
  List<String> gender = [];

  @override
  void initState() {
    super.initState();

    /// TODO Setup: Uncomment the following lines to automatically fill the email and password fields for testing, so you don't have to type them every time
    // emailController.text = "example@example.com";
    // passwordController.text = "12345678";
    
    // Location permission belongs to location-dependent features, not sign-in.
    // Users must be able to authenticate without granting GPS access.
    callApiSetting();
  }

  AuthProvider? authProvider;

  late LocationData _locationData;
  Location location = new Location();

  Future<void> getLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _locationData = await location.getLocation();

    prefs.setString('lat', _locationData.latitude.toString());
    prefs.setString('lang', _locationData.longitude.toString());
  }

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    double width;
    width = MediaQuery.of(context).size.width;
    final size = MediaQuery.of(context).size;
    return Care360AuthShell(
      professional: false,
      child: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          if (Care360ConnectionError.isOfflinePreview(Apis.baseUrl))
            Container(
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'OFFLINE DESIGN TEST — This APK cannot sign in or access '
                'Care360 services. A connected test build is required.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5D4300),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),


                                  Container(
                                    margin: EdgeInsets.only(top: width * 0.08),
                                    child: Column(
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.signIn_welcome).toString(),
                                          style: TextStyle(fontSize: width * 0.1, fontWeight: FontWeight.bold, color: Palette.light_black),
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(
                                    child: Column(
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.signIn_title).toString(),
                                          style: TextStyle(fontSize: width * 0.04, color: Palette.dark_grey1),
                                        )
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 30,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      decoration: BoxDecoration(color: Palette.dark_white, borderRadius: BorderRadius.circular(10)),
                                      child: TextFormField(
                                        controller: emailController,
                                        keyboardType: TextInputType.text,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Palette.dark_blue,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: getTranslated(context, AppString.signIn_email_hint).toString(),
                                          hintStyle: TextStyle(
                                            fontSize: 16,
                                            color: Palette.dark_grey,
                                          ),
                                        ),
                                        validator: (String? value) {
                                          if (value!.isEmpty) {
                                            return getTranslated(context, AppString.signIn_email_validator1).toString();
                                          }
                                          if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                                            return getTranslated(context, AppString.signIn_email_validator2).toString();
                                          }
                                          return null;
                                        },
                                        onSaved: (String? name) {},
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      decoration: BoxDecoration(color: Palette.dark_white, borderRadius: BorderRadius.circular(10)),
                                      child: TextFormField(
                                        controller: passwordController,
                                        keyboardType: TextInputType.text,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Palette.dark_blue,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: getTranslated(context, AppString.signIn_password_hint).toString(),
                                          hintStyle: TextStyle(
                                            fontSize: 16,
                                            color: Palette.dark_grey,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isHidden ? Icons.visibility : Icons.visibility_off,
                                              color: Palette.grey,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _isHidden = !_isHidden;
                                              });
                                            },
                                          ),
                                        ),
                                        obscureText: _isHidden,
                                        validator: (String? value) {
                                          if (value!.isEmpty) {
                                            return getTranslated(context, AppString.signIn_password_validator).toString();
                                          }
                                          return null;
                                        },
                                        onSaved: (String? name) {},
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                                    child: Container(
                                      width: width * 1,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ElevatedButton(
                                        child: Text(
                                          getTranslated(context, AppString.signIn_signIn_button).toString(),
                                          style: TextStyle(fontSize: 18),
                                          textAlign: TextAlign.center,
                                        ),
                                        onPressed: (Care360ConnectionError.isOfflinePreview(Apis.baseUrl) || _loginInProgress) ? null : () {
                                          if (formKey.currentState!.validate()) {
                                            callForLogin();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    child: Text(
                                      getTranslated(context, AppString.signIn_forgotPassword_button).toString(),
                                      style: TextStyle(fontSize: 16, color: Palette.dark_grey),
                                      textAlign: TextAlign.center,
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(context, 'ForgotPasswordScreen');
                                    },
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        getTranslated(context, AppString.signIn_notAccount).toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Palette.dark_grey,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(context, 'SignUp');
                                        },
                                        child: Text(
                                          getTranslated(context, AppString.signIn_signUp_button).toString(),
                                          style: TextStyle(fontSize: 16, color: Palette.blue, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                
        ]),
      ),
    );
  }

  Future<BaseModel<Login>> callForLogin() async {
    if (_loginInProgress) return BaseModel<Login>();
    setState(() => _loginInProgress = true);
    Login response;
    Map<String, dynamic> body = {
      "email": emailController.text.toString(),
      "password": passwordController.text.toString(),
      "device_token": SharedPreferenceHelper.getString(Preferences.device_token),
    };

    setState(() {
      Preferences.onLoading(context);
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).loginRequest(body);
      if (response.success == true) {
        Preferences.hideDialog(context);
        await SharedPreferenceHelper.setString(FirestoreConstants.email, response.data!.email!);
        // Never persist login credentials; Firebase Auth maintains its own session.
        await SharedPreferenceHelper.setString(FirestoreConstants.nickname, response.data!.name!);
        await SharedPreferenceHelper.setString(FirestoreConstants.photoUrl, response.data!.fullImage!);
        await SharedPreferenceHelper.setString(Preferences.name, response.data!.name!);
        await SharedPreferenceHelper.setString(Preferences.image, response.data!.fullImage!);
        await SharedPreferenceHelper.setString(Preferences.image, response.data!.fullImage!);
        await SharedPreferenceHelper.setString(Preferences.userId, response.data!.id.toString());
        await SharedPreferenceHelper.setString(Preferences.phone, response.data!.phone.toString());
        await SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
        if (response.data!.token != null && response.data!.token!.isNotEmpty && response.data!.token != "null") {
          await SharedPreferenceHelper.setSecureString(Preferences.auth_token, response.data!.token!);
          await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, true);
          // Ensure token is visible to auth Dio before navigating (avoids 401 race on Home).
          await Future.delayed(const Duration(milliseconds: 100));
          final readBack = await SharedPreferenceHelper.getSecureString(Preferences.auth_token);
          if (readBack == null || readBack.isEmpty) {
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } else {
          await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, false);
        }

        // Sign into Firebase using backend-issued custom token (stronger identity).
        // Falls back to the legacy email/password path if the token is missing
        // or if sign-in with the custom token fails (e.g. wrong service account project).
        final fbToken = response.data!.firebaseCustomToken;
        if (kDebugMode) {
          print('Firebase custom token: ${fbToken != null && fbToken.isNotEmpty ? "present (${fbToken.length} chars)" : "NOT returned by server"}');
        }
        bool fbSignedIn = false;
        if (fbToken != null && fbToken.isNotEmpty) {
          try {
            fbSignedIn = await authProvider!.signInWithCustomToken(
              customToken: fbToken,
              appUserId: response.data!.id.toString(),
              nickname: response.data!.name ?? '',
              photoUrl: response.data!.fullImage ?? '',
              userType: 'patient',
            );
          } catch (e) {
            if (kDebugMode) print('signInWithCustomToken error: $e');
          }
        }
        if (!fbSignedIn) {
          if (kDebugMode) print('Falling back to handleSignIn (email/password Firebase Auth)');
          try {
            final result = await authProvider!.handleSignIn(emailController.text.toString(), passwordController.text.toString());
            if (kDebugMode) print('handleSignIn result: $result');
          } catch (e) {
            if (kDebugMode) print('handleSignIn error: $e');
          }
        }
        if (kDebugMode) {
          final uid = authProvider!.getUserFirebaseId();
          print('Firebase Auth UID after login: $uid');
          print('Firebase currentUser: ${FirebaseAuth.instance.currentUser?.uid}');
        }

        final verifyValue = response.data!.verify;
        final idValue = response.data!.id;
        setState(() {
          verify = verifyValue;
          id = idValue;
          msg = response.msg;
        });

        verifyValue != 0
            ? Navigator.pushReplacementNamed(context, "Home")
            : Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhoneVerification(id: idValue),
                ),
              );
        emailController.clear();
        passwordController.clear();

        Fluttertoast.showToast(
          msg: '${response.msg}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Palette.blue,
          textColor: Palette.white,
        );
      } else {
        setState(() {
          Preferences.hideDialog(context);
          Fluttertoast.showToast(
            msg: '${response.msg}',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Palette.blue,
            textColor: Palette.white,
          );
        });
      }
    } catch (error) {
      if (mounted) {
        Preferences.hideDialog(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(Care360ConnectionError.describe(error, apiBaseUrl: Apis.baseUrl)),
        ));
      }
      return BaseModel()..setException(ServerError.withError(error: error));
    } finally {
      if (mounted) setState(() => _loginInProgress = false);
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<DetailSetting>> callApiSetting() async {
    DetailSetting response;

    try {
      response = await RestClient(RetroApi2().dioData2()).settingRequest();
      // Settings and push notifications are optional during sign-in.
      // In particular, an empty patient_app_id must not crash the screen.
      if (response.success == true) {
        final mapKey = response.data?.mapKey?.trim();
        if (mapKey != null && mapKey.isNotEmpty && mapKey.toLowerCase() != 'null') {
          await SharedPreferenceHelper.setString(Preferences.map_key_value, mapKey);
        }
        final appId = validPatientOneSignalAppId(response);
        if (appId != null) {
          await SharedPreferenceHelper.setString(Preferences.patientAppId, appId);
          getOneSignalToken(appId);
        }
      }
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  getOneSignalToken(appId) async {
    OneSignal.Debug.setLogLevel(OSLogLevel.info);

    OneSignal.initialize(appId);
    // Only the Settings > Enable notifications action requests OS permission.
    // OneSignal can initialize here without interrupting sign-in.
    OneSignal.Debug.setAlertLevel(OSLogLevel.none);

    if (SharedPreferenceHelper.getString(Preferences.device_token) == "" ||
        SharedPreferenceHelper.getString(Preferences.device_token) == "N_A") {
      if (OneSignal.User.pushSubscription.id != null) {
        SharedPreferenceHelper.setString(Preferences.device_token, OneSignal.User.pushSubscription.id.toString());
      } else {
        // getOneSingleToken(appId);
        SharedPreferenceHelper.setString(Preferences.device_token, '');
      }
    }
  }
}

