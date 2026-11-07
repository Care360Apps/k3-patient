import 'startup_gate.dart';
import 'diagnostics/k3_startup_diagnostics.dart';
import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctro_patient/Screen/Location/AddLocation.dart';
import 'package:doctro_patient/Screen/Location/Addtocart.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/AllPharamacy.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Book_success.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Bookappointment.dart';
import 'package:doctro_patient/Screen/Provider/ProvidersScreen.dart';
import 'package:doctro_patient/Screen/Provider/FindProvidersScreen.dart';
import 'package:doctro_patient/Screen/Doctor/Favoritedoctor.dart';
import 'package:doctro_patient/FirebaseProviders/auth_provider.dart';
import 'package:doctro_patient/FirebaseProviders/chat_provider.dart';
import 'package:doctro_patient/FirebaseProviders/home_provider.dart';
import 'package:doctro_patient/FirebaseProviders/setting_provider.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/HealthTips.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/HealthTipsDetail.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/MedicineDescription.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/PharamacyDetail.dart';
import 'package:doctro_patient/Screen/Courses/CourseList.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Review_Appointment.dart';
import 'package:doctro_patient/Screen/Authentication/SignIn.dart';
import 'package:doctro_patient/Screen/Doctor/Specialist.dart';
import 'package:doctro_patient/Screen/Doctor/Treatment.dart';
import 'package:doctro_patient/Screen/Doctor/TreatmentSpecialist.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/Screen/Doctor/doctordetail.dart';
import 'package:doctro_patient/Screen/Authentication/forgotpassword.dart';
import 'package:doctro_patient/Screen/Location/Showlocation.dart';
import 'package:doctro_patient/Screen/Authentication/phoneverification.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/Myprescription.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Appointment.dart';
import 'package:doctro_patient/Screen/Setting/ChangeLanguage.dart';
import 'package:doctro_patient/Chat/chat_list.dart';
import 'package:doctro_patient/VideoCall/videocallhistory.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/MedicineOrder.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/MedicineOrderDetail.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Screen/Authentication/signup.dart';
import 'Screen/AppointmentRelatedScreen/appointment_stripe_service.dart';
import 'Screen/Payment/MedicinePayment.dart';
import 'Screen/Payment/StripePaymentScreen.dart';
import 'Screen/Payment/StripePaymentScreenMedicine.dart';
import 'Screen/Payment/medicines_stripe_services.dart';
import 'Screen/Screens/Home.dart';
import 'Screen/Screens/Home.dart';
import 'Screen/Screens/HospitalsScreen.dart';
import 'Screen/Screens/Laboratory.dart';
import 'Screen/Screens/MapView.dart';
import 'Screen/Screens/Offer.dart';
import 'Screen/Screens/Setting.dart';
import 'Screen/Screens/notifications.dart';
import 'Screen/Screens/profile.dart';
import 'Screen/Setting/AboutUs.dart';
import 'Chat/chatPage.dart';
import 'Screen/Setting/ChangePassword.dart';
import 'Screen/Setting/PrivacyPolicy.dart';
import 'VideoCall/overlay_handler.dart';
import 'api/retrofit_Api.dart';
import 'api/base_model.dart';
import 'api/network_api.dart';
import 'api/server_error.dart';
import 'const/Palette.dart';
import 'const/prefConstatnt.dart';
import 'localization/language_localization.dart';
import 'localization/care360_framework_locale_fallback.dart';
import 'localization/localization_constant.dart';
import 'localization/localization_constant.dart' as care360_locale;
import 'brand/care360_global_language.dart';
import 'model/detail_setting_model.dart';
import 'package:doctro_patient/firebase_options.dart';
import 'package:doctro_patient/api/patient_optional_settings.dart';
import 'Screen/Onboarding/Onboarding.dart';

void main() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  runZoned(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      installK3StartupDiagnostics();
      runApp(StartupGate(
        initialize: _initializeApp,
        onReady: () => unawaited(_initFirebaseMessagingWithLogging()),
      ));
    },
    zoneSpecification: kReleaseMode ? ZoneSpecification(print: (_, __, ___, ____) {}) : null,
  );
}

Future<Widget> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform);
  
  await SharedPreferenceHelper.init(offlineSandbox: k3OfflineSynthetic);
  final token = k3OfflineSynthetic
      ? null
      : await SharedPreferenceHelper.getSecureString(Preferences.auth_token);
  final hasToken = token != null && token.isNotEmpty && token != "N_A" && token != "null";
  await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, hasToken);
  await SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, hasToken);
  if (hasToken) {
    Future(() async {
      try {
        final response = await RestClient(RetroApi().dioData()).refreshToken().timeout(Duration(seconds: 10));
        final newToken = response.data?.token;
        if (response.success == true && newToken != null && newToken.isNotEmpty && newToken != "null") {
          await SharedPreferenceHelper.setSecureString(Preferences.auth_token, newToken);
          await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, true);
          await SharedPreferenceHelper.setBoolean(Preferences.is_logged_in, true);
        }
      } catch (_) {}
    });
  }
  return MyApp(prefs: prefs);
}

Future<void> _initFirebaseMessagingWithLogging() async {
  if (k3OfflineSynthetic) return;
  try {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    ).timeout(const Duration(seconds: 5));
    await FirebaseMessaging.instance.subscribeToTopic("all")
        .timeout(const Duration(seconds: 5));
  } catch (_) {
    debugPrint('Optional push setup unavailable; app remains usable.');
  }
}

final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    importance: Importance.high,
    showBadge: true,
    playSound: true,
    enableVibration: true);

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;

  MyApp({required this.prefs});

  @override
  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    // Isolated widget tests may not mount MyApp. Live app selections still
    // update the root locale immediately and remain saved on device.
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  String? deviceToken = "";
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage firebaseStorage = FirebaseStorage.instance;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  String msgId = "";
  String msgName = "";
  String msgImage = "";
  String doctorToken = "";

  String token = "";
  bool? router;

  @override
  void initState() {
    super.initState();
    if (k3OfflineSynthetic) {
      debugPrint('K3_OFFLINE_TEST: optional network and push setup skipped');
      return;
    }
    callApiSetting();
    Future.delayed(const Duration(seconds: 2), () {
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          Map<String, dynamic> dataValue = message.data;
          msgImage = dataValue['doctorImage'].toString();
          msgName = dataValue['doctorName'].toString();
          msgId = dataValue['doctorId'].toString();
          doctorToken = dataValue['doctorToken'].toString();
          print("message not null");
          if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
            Navigator.of(navigatorKey.currentState!.context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  peerId: msgId,
                  peerAvatar: msgImage,
                  peerNickname: msgName,
                  doctorToken: doctorToken,
                  where: "",
                ),
              ),
            );
          } else {
            Navigator.of(navigatorKey.currentState!.context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SignIn(),
              ),
            );
          }
        }
      });
    });
    var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = new DarwinInitializationSettings();
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: onSelectNotification);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      Map<String, dynamic> dataValue = message.data;
      String screen = dataValue['screen'].toString();
      msgImage = dataValue['doctorImage'].toString();
      msgName = dataValue['doctorName'].toString();
      msgId = dataValue['doctorId'].toString();
      doctorToken = dataValue['doctorToken'].toString();

      print("Screen: " + screen);
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: "@mipmap/ic_launcher",
              ),
            ),
            payload: screen);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        Navigator.of(navigatorKey.currentState!.context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              peerId: msgId,
              peerAvatar: msgImage,
              peerNickname: msgName,
              doctorToken: doctorToken,
              where: "",
            ),
          ),
        );
      }
    });
    getToken();
  }

  onSelectNotification(payload) {
    if (payload.payload == "screen") {
      if (msgId.isNotEmpty && msgName.isNotEmpty && msgImage.isNotEmpty && SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
        Navigator.of(navigatorKey.currentState!.context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ChatPage(
              peerId: msgId,
              peerAvatar: msgImage,
              peerNickname: msgName,
              doctorToken: doctorToken,
              where: "",
            ),
          ),
        );
      }
    }
  }

  getToken() async {
    try {
      String? apnsToken;
      int attempts = 0;
      const maxAttempts = 5; // Short timeout; on iOS simulator APNs is never available

      while (apnsToken == null && attempts < maxAttempts) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          attempts++;
          await Future.delayed(Duration(seconds: 1));
        }
      }

      if (apnsToken != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          token = fcmToken;
          SharedPreferenceHelper.setString(Preferences.notificationRegisterKey, fcmToken);
        }
      } else {
        // e.g. iOS simulator – try FCM anyway
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null && fcmToken.isNotEmpty) {
          token = fcmToken;
          SharedPreferenceHelper.setString(Preferences.notificationRegisterKey, fcmToken);
        }
      }
    } catch (e) {
      // Don't spam console; push is optional
    }
  }

  @override
  void didChangeDependencies() {
    getLocale().then((local) {
      if (!mounted) return;
      setState(() => _locale = local);
    }).catchError((Object _) {
      if (kDebugMode) debugPrint('Care360: language preference unavailable; using English.');
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Colors.black,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<StripePayment>(
            create: (context) => StripePayment(),
          ),
          ChangeNotifierProvider<MedicinesStripePayment>(
            create: (context) => MedicinesStripePayment(),
          ),
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
              firebaseAuth: FirebaseAuth.instance,
              prefs: widget.prefs,
              firebaseFirestore: this.firebaseFirestore,
            ),
          ),
          Provider<SettingProvider>(
            create: (_) => SettingProvider(
              prefs: widget.prefs,
              firebaseFirestore: this.firebaseFirestore,
              firebaseStorage: this.firebaseStorage,
            ),
          ),
          Provider<HomeProvider>(
            create: (_) => HomeProvider(
              firebaseFirestore: this.firebaseFirestore,
            ),
          ),
          Provider<ChatProvider>(
            create: (_) => ChatProvider(
              prefs: widget.prefs,
              firebaseFirestore: this.firebaseFirestore,
              firebaseStorage: this.firebaseStorage,
            ),
          ),
        ],
        child: ChangeNotifierProvider<OverlayHandlerProvider>(
          create: (_) => OverlayHandlerProvider(),
          child: MaterialApp(
            navigatorKey: navigatorKey,
            builder: (context, navigatorChild) => Stack(
              children: [
                if (navigatorChild != null) navigatorChild,
                // The floating live language widget is deliberately excluded
                // from disconnected synthetic builds. Language options remain
                // visible inside the offline-only review hub; no service-backed
                // screens, overlays or state are mounted by that hub.
                if (!k3OfflineSynthetic)
                  PositionedDirectional(
                  end: 10,
                  bottom: 64,
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: Care360GlobalLanguageSwitch(
                      rootNavigatorKey: navigatorKey,
                      onSelect: (code) async {
                        final selectedLocale = await care360_locale.setLocale(code);
                        if (!mounted) return;
                        setLocale(selectedLocale);
                      },
                    ),
                  ),
                ),
              ],
            ),
            title: 'Patient',
            locale: _locale ?? Locale(ENGLISH, 'US'),
            supportedLocales: [
              Locale(ENGLISH, 'US'),
              Locale(HAUSA, 'NG'),
              Locale(IGBO, 'NG'),
              Locale(YORUBA, 'NG'),
              Locale(FRENCH, 'FR'),
              Locale(SPANISH, 'ES'),
              Locale(ARABIC, 'AE'),
            ],
            localizationsDelegates: const [
              LanguageLocalization.delegate,
              Care360MaterialFallbackDelegate(),
              Care360WidgetsFallbackDelegate(),
              Care360CupertinoFallbackDelegate(),
            ],
            localeResolutionCallback: (deviceLocal, supportedLocales) {
              for (var local in supportedLocales) {
                if (deviceLocal != null && local.languageCode == deviceLocal.languageCode && local.countryCode == deviceLocal.countryCode) {
                  return deviceLocal;
                }
              }
              return supportedLocales.first;
            },
            debugShowCheckedModeBanner: false,
            initialRoute: "/",
            theme: ThemeData(
              // A shared, high-contrast healthcare identity across Patient.
              // Keep Material 2 compatibility for established clinical forms.
              useMaterial3: false,
              splashColor: Palette.transparent,
              highlightColor: Palette.transparent,
              scaffoldBackgroundColor: const Color(0xFFF5F8F7),
              primaryColor: const Color(0xFF123E4D),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF087D76),
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF123E4D),
                foregroundColor: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087D76),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF123E4D),
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            routes: {
              '/': (context) {
                // Always show onboarding once after splash, even if already logged in.
                final hasSeenOnboarding = SharedPreferenceHelper.getBoolean(Preferences.onboarding_seen);
                final isLoggedIn = SharedPreferenceHelper.getBoolean(Preferences.is_logged_in);

                if (!hasSeenOnboarding) {
                  k3ReportInitialRoute('onboarding');
                  return const OnboardingScreen();
                }

                k3ReportInitialRoute(isLoggedIn ? 'home' : 'sign-in');
                return isLoggedIn ? Home() : SignIn();
              },
              'SignIn': (context) => SignIn(),
              'SignUp': (context) => SignUp(),
              'ForgotPasswordScreen': (context) => ForgotPasswordScreen(),
              'PhoneVerification': (context) => PhoneVerification(),
              'Home': (context) => Home(),
              'Treatment': (context) => Treatment(),
              'FavoriteDoctorScreen': (context) => FavoriteDoctorScreen(),
              'Specialist': (context) => Specialist(),
              'FindProviders': (context) => FindProvidersScreen(),
              'DoctorDetail': (context) => DoctorDetail(),
              'BookAppointment': (context) => BookAppointment(),
              'Providers': (context) => ProvidersScreen(),
              'Appointment': (context) => Appointment(),
              'Myprescription': (context) => MyPrescription(),
              'HealthTips': (context) => HealthTips(),
              'HealthTipsDetail': (context) => HealthTipsDetail(),
              'Setting': (context) => Setting(),
              'AddToCart': (context) => AddToCart(),
              'Offer': (context) => Offer(),
              'Profile': (context) => Profile(),
              'ShowLocation': (context) => ShowLocation(),
              'AddLocation': (context) => AddLocation(),
              'BookSuccess': (context) => BookSuccess(),
              'Review': (context) => Review(),
              'MedicineDescription': (context) => MedicineDescription(),
              'AllPharamacy': (context) => AllPharamacy(),
              'PharamacyDetail': (context) => PharamacyDetail(),
              'MedicinePayment': (context) => MedicinePayment(),
              'MedicineOrder': (context) => MedicineOrder(),
              'MedicineOrderDetail': (context) => MedicineOrderDetail(),
              'TreatmentSpecialist': (context) => TreatmentSpecialist(),
              'Notifications': (context) => Notifications(),
              'Laboratory': (context) => Laboratory(title: 'Find Laboratories', icon: Icons.science_outlined),
              'Hospitals': (context) => HospitalsScreen(),
              'MapView': (context) => MapView(),
              'StripePaymentScreen': (context) => StripePaymentScreen(),
              'StripePaymentScreenMedicine': (context) => StripePaymentScreenMedicine(),
              'ChangePassword': (context) => ChangePassword(),
              'PrivacyPolicy': (context) => PrivacyPolicy(),
              'AboutUs': (context) => AboutUs(),
              'ChangeLanguage': (context) => ChangeLanguage(),
              'VideoCallHistory': (context) => VideoCallHistory(),
              'ChatList': (context) => ChatListScreen(),
              'Courses': (context) => CourseList(),
            },
          ),
        ),
      ),
    );
  }

  Future<BaseModel<DetailSetting>> callApiSetting() async {
    DetailSetting response;
    try {
      response = await RestClient(RetroApi2().dioData2()).settingRequest();
      // The local Laravel settings endpoint can return success without an
      // optional OneSignal app ID. Never dereference that field with '!'.
      final appId = validPatientOneSignalAppId(response);
      if (appId != null) {
        await SharedPreferenceHelper.setString(Preferences.patientAppId, appId);
        getOneSignalToken(appId);
      }
    } catch (error, stacktrace) {
      if (kDebugMode) debugPrint('Care360: optional settings unavailable; continuing.');
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  bool _oneSignalInitialized = false;

  getOneSignalToken(appId) async {
    if (_oneSignalInitialized) return;
    _oneSignalInitialized = true;

    OneSignal.Debug.setLogLevel(OSLogLevel.info);
    OneSignal.initialize(appId);

    if (kDebugMode) {
      print("OneSignal App ID: $appId");
    }

    OneSignal.Notifications.addPermissionObserver((state) {
      print("Has permission $state");
    });

    if (Platform.isIOS) {
      if (OneSignal.Notifications.permission == false &&
          SharedPreferenceHelper.getBoolean(Preferences.notificationPermissionDialog) == false) {
        OneSignal.Notifications.requestPermission(true);
      }
    } else if (Platform.isAndroid) {
      OneSignal.Notifications.requestPermission(true);
    }

    OneSignal.User.pushSubscription.addObserver((state) {
      final id = state.current.id;
      if (id != null) {
        SharedPreferenceHelper.setString(Preferences.device_token, id);
        if (kDebugMode) {
          print("OneSignal ID : $id");
        }
      }
    });

    OneSignal.Debug.setAlertLevel(OSLogLevel.none);

    final subId = OneSignal.User.pushSubscription.id;
    if (subId != null) {
      SharedPreferenceHelper.setString(Preferences.device_token, subId);
    }

    if (kDebugMode) {
      print("OneSignal ID : $subId");
    }
  }
}