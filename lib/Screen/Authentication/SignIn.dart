import 'dart:io';
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
import 'package:doctro_patient/const/care360_theme.dart';
import 'package:doctro_patient/widgets/care360_brand_signature.dart';
import 'package:doctro_patient/widgets/care360_master_brand.dart';
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
    
    getLocation();
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

    return Scaffold(
      backgroundColor: Care360Theme.canvas,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Palette.dark_blue, Color(0xFF1571BA)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Care360MasterBrand(
                                productName: 'Care360 Patient',
                                onDark: true,
                                logoSize: 80,
                              ),
                            ),
                            const SizedBox(height: 35),
                            Text(
                              getTranslated(context, AppString.signIn_welcome).toString(),
                              style: const TextStyle(
                                fontSize: 29,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              getTranslated(context, AppString.signIn_title).toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFFE4F1FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Care360Theme.border),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.dark_blue.withOpacity(0.035),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Sign in to your account',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Care360Theme.ink,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              getTranslated(context, AppString.signIn_email_hint).toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Care360Theme.ink,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              decoration: const InputDecoration(
                                hintText: 'name@example.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return getTranslated(context, AppString.signIn_email_validator1).toString();
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                                  return getTranslated(context, AppString.signIn_email_validator2).toString();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Text(
                              getTranslated(context, AppString.signIn_password_hint).toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Care360Theme.ink,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: passwordController,
                              obscureText: _isHidden,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                hintText: getTranslated(context, AppString.signIn_password_hint).toString(),
                                suffixIcon: IconButton(
                                  tooltip: _isHidden ? 'Show password' : 'Hide password',
                                  icon: Icon(
                                    _isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () => setState(() => _isHidden = !_isHidden),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return getTranslated(context, AppString.signIn_password_validator).toString();
                                }
                                return null;
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(context, 'ForgotPasswordScreen'),
                                child: Text(
                                  getTranslated(context, AppString.signIn_forgotPassword_button).toString(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (formKey.currentState?.validate() ?? false) {
                                    callForLogin();
                                  }
                                },
                                child: Text(
                                  getTranslated(context, AppString.signIn_signIn_button).toString(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            getTranslated(context, AppString.signIn_notAccount).toString(),
                            style: const TextStyle(color: Care360Theme.muted, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, 'SignUp'),
                            child: Text(
                              getTranslated(context, AppString.signIn_signUp_button).toString(),
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Center(child: Care360BrandSignature()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<Login>> callForLogin() async {
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
        await SharedPreferenceHelper.setString(FirestoreConstants.password, passwordController.text.toString());
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
    } catch (error, stacktrace) {
      Preferences.hideDialog(context);
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<DetailSetting>> callApiSetting() async {
    DetailSetting response;

    try {
      response = await RestClient(RetroApi2().dioData2()).settingRequest();
      setState(() {
        if (response.success == true) {
          SharedPreferenceHelper.setString(Preferences.patientAppId, response.data!.patientAppId!);
          if (response.data!.mapKey != null && response.data!.mapKey.toString() != "null") {
            SharedPreferenceHelper.setString(Preferences.map_key_value, response.data!.mapKey.toString());
          }

          if (response.data!.patientAppId != null) {
            getOneSignalToken(SharedPreferenceHelper.getString(Preferences.patientAppId));
          }
        }
      });
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  getOneSignalToken(appId) async {
    OneSignal.Debug.setLogLevel(OSLogLevel.info);

    OneSignal.initialize(appId);
    if (kDebugMode) {
      print("OneSignal App ID: " + appId);
    }
    OneSignal.Notifications.addPermissionObserver((state) {
      print("Has permission " + state.toString());
    });
    print("Permission ${OneSignal.Notifications.permission}");
    Platform.isIOS
        ? OneSignal.Notifications.permission == false &&
                SharedPreferenceHelper.getBoolean(Preferences.notificationPermissionDialog) == false
            ? OneSignal.Notifications.requestPermission(true)
            : null
        : null;
    Platform.isAndroid ? OneSignal.Notifications.requestPermission(true) : null;
    if (kDebugMode) {
      print("OneSignal ID : ${OneSignal.User.pushSubscription.id}");
    }
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
