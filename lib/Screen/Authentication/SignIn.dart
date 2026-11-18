import '../../preview/care360_offline_dashboard.dart';
import '../../localization/care360_language_picker.dart';
import '../../main.dart';
import '../../diagnostics/k3_startup_diagnostics.dart';
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
    // Synthetic previews must not attempt any API or OneSignal initialization.
    if (!Care360ConnectionError.isOfflinePreview(Apis.baseUrl)) {
      callApiSetting();
    }
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
    return Care360AuthShell(
      professional: false,
      child: Form(
        key: formKey,
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Care360LanguagePicker(
                languageCode: Localizations.localeOf(context).languageCode,
                onSelected: (language) async {
                  final selected = await setLocale(language);
                  if (!mounted) return;
                  MyApp.setLocale(context, selected);
                },
              ),
            ),
          ),
          if (Care360ConnectionError.isOfflinePreview(Apis.baseUrl))
            Container(
              margin: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4DE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'OFFLINE DESIGN TEST — Real sign-in and services are disabled. '
                'Use the design preview below, or install a connected staging APK.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF5D4300),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (k3OfflineSynthetic &&
              Care360ConnectionError.isOfflinePreview(Apis.baseUrl))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('care360-offline-preview-open'),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Preview patient dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF08785E),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Care360OfflineDashboard(),
                    ),
                  ),
                ),
              ),
            ),


          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  getTranslated(context, AppString.signIn_welcome).toString(),
                  key: const Key('care360-signin-heading'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF123E4D),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  getTranslated(context, AppString.signIn_title).toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF526F77),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextFormField(
              key: const Key('care360-signin-email'),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(fontSize: 16, color: Color(0xFF123E4D)),
              decoration: InputDecoration(
                labelText: getTranslated(context, AppString.signIn_email_hint).toString(),
                hintText: 'name@example.com',
                prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF087D76)),
                filled: true,
                fillColor: const Color(0xFFF5F8F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Color(0xFFDCE8E5)),
                ),
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return getTranslated(context, AppString.signIn_email_validator1).toString();
                }
                if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
                  return getTranslated(context, AppString.signIn_email_validator2).toString();
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextFormField(
              key: const Key('care360-signin-password'),
              controller: passwordController,
              obscureText: _isHidden,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              autocorrect: false,
              enableSuggestions: false,
              onFieldSubmitted: (_) {
                if (Care360ConnectionError.isOfflinePreview(Apis.baseUrl) ||
                    _loginInProgress) return;
                if (formKey.currentState?.validate() == true) callForLogin();
              },
              style: const TextStyle(fontSize: 16, color: Color(0xFF123E4D)),
              decoration: InputDecoration(
                labelText: getTranslated(context, AppString.signIn_password_hint).toString(),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF087D76)),
                filled: true,
                fillColor: const Color(0xFFF5F8F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Color(0xFFDCE8E5)),
                ),
                suffixIcon: IconButton(
                  key: const Key('care360-signin-toggle-password'),
                  tooltip: _isHidden ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _isHidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: const Color(0xFF526F77),
                  ),
                  onPressed: () => setState(() => _isHidden = !_isHidden),
                ),
              ),
              validator: (value) => (value?.isEmpty ?? true)
                  ? getTranslated(context, AppString.signIn_password_validator).toString()
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('care360-signin-submit'),
                onPressed: (Care360ConnectionError.isOfflinePreview(Apis.baseUrl) ||
                    _loginInProgress) ? null : () {
                  if (formKey.currentState?.validate() == true) {
                    callForLogin();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087D76),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: _loginInProgress
                    ? const SizedBox(
                        width: 21, height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white,
                        ),
                      )
                    : Text(
                        getTranslated(context, AppString.signIn_signIn_button).toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          TextButton(
            key: const Key('care360-signin-forgot-password'),
            onPressed: () => Navigator.pushNamed(context, 'ForgotPasswordScreen'),
            child: Text(
              getTranslated(context, AppString.signIn_forgotPassword_button).toString(),
              style: const TextStyle(
                color: Color(0xFF087D76),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 7,
            children: [
              Text(
                getTranslated(context, AppString.signIn_notAccount).toString(),
                style: const TextStyle(color: Color(0xFF526F77), fontSize: 14),
              ),
              TextButton(
                key: const Key('care360-signin-create-account'),
                onPressed: () => Navigator.pushNamed(context, 'SignUp'),
                child: Text(
                  getTranslated(context, AppString.signIn_signUp_button).toString(),
                  style: const TextStyle(
                    color: Color(0xFF087D76), fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
    } catch (error) {
      // Never log full upstream exceptions or stack traces from optional
      // settings: they may include tokens, locations or user identifiers.
      if (kDebugMode) debugPrint('Care360: optional settings unavailable.');
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

