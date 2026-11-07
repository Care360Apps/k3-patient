import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:doctro_patient/VideoCall/videocall.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/model/banner_model.dart';
import 'package:doctro_patient/model/treatments_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import '../../brand/care360_partner_showcase.dart';
import '../../brand/care360_nearby_care_hero.dart';
import '../../brand/care360_horizontal_cards.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/PharamacyDetail.dart';
import '../../VideoCall/PhoneScreen.dart';
import '../Doctor/TreatmentSpecialist.dart';
import '../../database/form_helper.dart';
import '../Doctor/doctordetail.dart';
import '../../model/appointments_model.dart';
import '../../model/display_offer_model.dart';
import '../../FirebaseProviders/auth_provider.dart';
import '../../FirebaseProviders/home_provider.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';
import '../../model/detail_setting_model.dart';
import '../../model/favorite_doctor_model.dart';
import '../../model/pharmacys_model.dart' as pharmacy_model;
import '../../model/user_detail_model.dart';
import '../../model/doctors_model.dart';
import '../../model/providers_model.dart';
import '../Provider/ProviderDetail.dart';
import '../../database/db_service.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Bookappointment.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/AppointmentDetailScreen.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? _address = "";
  String? _lat = "";
  String? _lang = "";

  String? name = "";
  String? email = "";
  String? phoneNo = "";
  String? image = "";

  String userPhoneNo = "";
  String userEmail = "";
  String userName = "";

  bool loading = false;
  AuthProvider? authProvider;

  List<DoctorModel> doctorList = [];
  List<ProviderModel> providerList = [];
  List<TreatmentData> treatmentList = [];
  List<pharmacy_model.Data> pharmacyList = [];

  List<Add> banner = [];

  int treatmentId = 0;

  List<bool> favoriteDoctor = [];
  int? doctorID = 0;

  List<OfferModel> offerList = [];

  List<UpcomingAppointment> upcomingAppointment = [];

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  int current = 0;

  // Search //
  TextEditingController _search = TextEditingController();
  List<DoctorModel> _searchResult = [];

  // Cart
  late DBService dbService;
  int _cartItemCount = 0;

  late LocationData _locationData;
  Location location = new Location();

  late HomeProvider homeProvider;
  Timer? _appointmentRefreshTimer;
  bool _appointmentsInFlight = false;

  @override
  void dispose() {
    // A screen that is no longer visible must not continue polling the
    // patient's appointment API or retain its search controller.
    _appointmentRefreshTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    dbService = DBService();
    _loadCachedUserDetails();
    // Only one location initialization. The location-dependent screens can
    // request permission later; Home should paint without waiting for GPS.
    getLocation();
    homeProvider = context.read<HomeProvider>();
    final isLoggedIn = SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true;
    final hasToken = _hasAuthToken();
    if (isLoggedIn && hasToken) {
      // Run all auth-dependent calls after a short delay so the token from login
      // is visible to the auth Dio interceptor (avoids 401 and forced logout).
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        if (!_hasAuthToken()) return;
        callApiSetting();
        callApiForUserDetail();
        callApiAppointment();
      });
      Future.delayed(
        const Duration(seconds: 5),
        () {
          if (!mounted || !_hasAuthToken()) return;
          final currentUser = FirebaseAuth.instance.currentUser;
          final pushToken = SharedPreferenceHelper.getString(Preferences.device_token);
          if (currentUser == null || pushToken == null || pushToken == "N_A") {
            return;
          }
          homeProvider.updateDataFirestore(
            FirestoreConstants.pathUserCollection,
            currentUser.uid,
            {'pushToken': pushToken},
          );
          // Never log notification tokens.
        },
      );
      _appointmentRefreshTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
        if (!mounted || !_hasAuthToken()) {
          timer.cancel();
          return;
        }
        callApiAppointment();
      });
    } else {
      callApiSetting();
    }
    if (isLoggedIn) {
      getOneSingleToken();
    }
    callApiBanner();
    callApiPharmacy();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    try {
      final items = await dbService.getProducts();
      if (!mounted) return;
      setState(() {
        _cartItemCount = items.length;
      });
    } catch (_) {
      // Ignore local DB errors for cart badge.
    }
  }

  void _loadCachedUserDetails() {
    final cachedName = SharedPreferenceHelper.getString(FirestoreConstants.nickname);
    final cachedEmail = SharedPreferenceHelper.getString(FirestoreConstants.email);
    final cachedPhone = SharedPreferenceHelper.getString(Preferences.phone);
    final cachedImage = SharedPreferenceHelper.getString(Preferences.image);
    setState(() {
      if ((name == null || name!.isEmpty || name == "N_A") && cachedName != "N_A") {
        name = cachedName;
      }
      if ((email == null || email!.isEmpty || email == "N_A") && cachedEmail != "N_A") {
        email = cachedEmail;
      }
      if ((phoneNo == null || phoneNo!.isEmpty || phoneNo == "N_A") && cachedPhone != "N_A") {
        phoneNo = cachedPhone;
      }
      if ((image == null || image!.isEmpty || image == "N_A") && cachedImage != "N_A") {
        image = cachedImage;
      }
    });
  }

  bool _hasAuthToken() {
    final hasToken = SharedPreferenceHelper.peekSecureString(Preferences.auth_token) != null;
    if (!hasToken) {
      SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, false);
    }
    return hasToken;
  }

  Future<void> getLocation() async {
    // Home must never demand storage/GPS permission before its first frame.
    // Use a selected/default location first, and query GPS only when permission
    // has already been granted for a location-dependent feature.
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultId = prefs.getInt(Preferences.default_address_id);
      if (defaultId != null && defaultId != 0) {
        final lat = prefs.getString(Preferences.default_lat);
        final lng = prefs.getString(Preferences.default_lang);
        final address = prefs.getString(Preferences.default_Address);
        if (lat != null && lat.isNotEmpty && lng != null &&
            lng.isNotEmpty && address != null && address.isNotEmpty) {
          await prefs.setString('lat', lat);
          await prefs.setString('lang', lng);
          await prefs.setString('Address', address);
          await prefs.setInt('addressId', defaultId);
          if (mounted) await _getAddress();
          return;
        }
      }

      final cachedLat = prefs.getString('lat');
      final cachedLng = prefs.getString('lang');
      if ((cachedLat == null || cachedLat.isEmpty ||
           cachedLng == null || cachedLng.isEmpty) &&
          (await Permission.location.status).isGranted) {
        try {
          final current = await location.getLocation().timeout(
              const Duration(seconds: 7));
          if (current.latitude != null && current.longitude != null) {
            await prefs.setString('lat', current.latitude.toString());
            await prefs.setString('lang', current.longitude.toString());
            await prefs.setString('latLive', current.latitude.toString());
            await prefs.setString('langLive', current.longitude.toString());
          }
        } catch (_) {
          // No coordinates is a valid state when GPS is slow or unavailable.
          // Continue to the address selector, not a spinner or red screen.
        }
      }
      if (mounted) await _getAddress();

      if (mounted &&
          SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) &&
          !SharedPreferenceHelper.getBoolean(
              Preferences.default_address_modal_seen)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showDefaultAddressModal(context);
        });
      }
    } catch (_) {
      if (mounted) await _getAddress();
    }
  }

  void _showDefaultAddressModal(BuildContext context) {
    final message = getTranslated(context, AppString.home_setDefaultAddress_modal_message).toString();
    final closeLabel = getTranslated(context, AppString.home_setDefaultAddress_modal_close).toString();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Palette.dark_blue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.info_outline_rounded, size: 32, color: Palette.dark_blue),
              ),
              SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Palette.dark_blue,
                ),
              ),
              SizedBox(height: 24),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () {
                    SharedPreferenceHelper.setBoolean(Preferences.default_address_modal_seen, true);
                    Navigator.of(ctx).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Palette.dark_blue,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(closeLabel, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getLiveLocation() async {
    // Optional live location refresh, only when location access is already
    // granted. No latitude/longitude, user IDs or tokens are logged.
    if (!(await Permission.location.status).isGranted) return;
    try {
      final current = await location.getLocation().timeout(
          const Duration(seconds: 7));
      if (current.latitude == null || current.longitude == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('latLive', current.latitude.toString());
      await prefs.setString('langLive', current.longitude.toString());
    } catch (_) {
      // A denied/timed-out live refresh must not block Patient Home.
    }
  }

  Future<void> _getAddress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final latitude = prefs.getString('lat');
    final longitude = prefs.getString('lang');
    setState(() {
      _address = prefs.getString('Address');
      _lat = latitude;
      _lang = longitude;
    });
    // Avoid requesting a nearby-provider lookup with empty coordinates.
    if (latitude != null && latitude.isNotEmpty &&
        longitude != null && longitude.isNotEmpty) {
      callApiDoctorList();
      callApiProviders();
    }
    callApiTreatment();
    callApIDisplayOffer();
  }

  _passDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userPhoneNo = '$phoneNo';
      userEmail = '$email';
      userName = '$name';
    });
    prefs.setString('phone_no', userPhoneNo);
    prefs.setString('email', userEmail);
    prefs.setString('name', userName);
  }

  _passIsWhere() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('isWhere', "Home");
  }

  DateTime? currentBackPressTime;

  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null || now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
        msg: getTranslated(context, AppString.exit_app).toString(),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }

  Widget _buildChatDrawerTile(BuildContext context) {
    final uid = authProvider?.getUserFirebaseId() ?? '';
    return ListTile(
      leading: uid.isNotEmpty
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(FirestoreConstants.pathUserCollection)
                  .doc(uid)
                  .snapshots(),
              builder: (ctx, snap) {
                final total =
                    ((snap.data?.data() as Map<String, dynamic>?)?['totalUnread'] ?? 0) as int;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Palette.blue),
                    if (total > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            total > 99 ? '99+' : '$total',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                );
              },
            )
          : Icon(Icons.chat_bubble_outline_rounded, color: Palette.blue),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Palette.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      onTap: () {
        SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
            ? Navigator.popAndPushNamed(context, 'ChatList')
            : FormHelper.showMessage(
                context,
                getTranslated(context, AppString.home_favoriteDoctor_alert_title).toString(),
                getTranslated(context, AppString.home_favoriteDoctor_alert_text).toString(),
                getTranslated(context, AppString.cancel).toString(),
                () => Navigator.of(context).pop(),
                buttonText2: getTranslated(context, AppString.login).toString(),
                isConfirmationDialog: true,
                onPressed2: () => Navigator.pushNamed(context, 'SignIn'),
              );
      },
      title: Text(
        getTranslated(context, AppString.chats).toString(),
        style: TextStyle(
          fontSize: 16,
          color: Palette.dark_blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    double width;
    double height;

    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: onWillPop,
      child: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.5,
        progressIndicator: SpinKitFadingCircle(
          color: Palette.blue,
          size: 50.0,
        ),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(new FocusNode());
          },
          child: Scaffold(
            key: _scaffoldKey,

            /// Drawer ///
            drawer: Drawer(
              child: Container(
                color: Palette.dark_white,
                child: SafeArea(
                  child: Column(
                    children: [
                      SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                          ? Container(
                              margin: EdgeInsets.fromLTRB(16, 12, 16, 10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  colors: [Palette.dark_blue, Palette.blue],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Palette.black.withOpacity(0.12),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    alignment: AlignmentDirectional.center,
                                    decoration: BoxDecoration(
                                      color: Palette.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CachedNetworkImage(
                                      alignment: Alignment.center,
                                      imageUrl: image!,
                                      imageBuilder: (context, imageProvider) => CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Palette.white,
                                        backgroundImage: imageProvider,
                                      ),
                                      placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                      errorWidget: (context, url, error) => ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Image.asset(
                                          "assets/images/no_image.jpg",
                                          fit: BoxFit.fitHeight,
                                          width: 58,
                                          height: 58,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$name',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Palette.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '$email',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Palette.white.withOpacity(0.85),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, 'Profile');
                                    },
                                    child: Container(
                                      height: 34,
                                      width: 34,
                                      decoration: BoxDecoration(
                                        color: Palette.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/icons/edit.svg',
                                        height: 18,
                                        width: 18,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          : Container(
                              margin: EdgeInsets.fromLTRB(16, 12, 16, 10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Palette.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Palette.black.withOpacity(0.06),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, 'SignIn');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Palette.blue,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        getTranslated(context, AppString.home_signIn_button).toString(),
                                        style: TextStyle(fontSize: 14, color: Palette.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, 'SignUp');
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Palette.blue),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        getTranslated(context, AppString.home_signUp_button).toString(),
                                        style: TextStyle(fontSize: 14, color: Palette.blue, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
                          children: [
                            ListTile(
                              leading: Icon(Icons.map_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, 'MapView');
                              },
                              title: Text(
                                'Map View',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.calendar_today_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, 'Specialist');
                              },
                              title: Text(
                                getTranslated(context, AppString.home_book_appointment).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.person_search_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, 'FindProviders');
                              },
                              title: Text(
                                getTranslated(context, AppString.home_find_providers) ?? 'Find Providers',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.event_available_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                    ? Navigator.popAndPushNamed(context, 'Appointment')
                                    : FormHelper.showMessage(
                                        context,
                                        getTranslated(context, AppString.home_medicineOrder_alert_title).toString(),
                                        getTranslated(context, AppString.home_medicineOrder_alert_text).toString(),
                                        getTranslated(context, AppString.cancel).toString(),
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                        buttonText2: getTranslated(context, AppString.login).toString(),
                                        isConfirmationDialog: true,
                                        onPressed2: () {
                                          Navigator.pushNamed(context, 'SignIn');
                                        },
                                      );
                              },
                              title: Text(
                                getTranslated(context, AppString.home_appointments).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.favorite_border, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                    ? Navigator.popAndPushNamed(context, 'FavoriteDoctorScreen')
                                    : FormHelper.showMessage(
                                        context,
                                        getTranslated(context, AppString.home_favoriteDoctor_alert_title).toString(),
                                        getTranslated(context, AppString.home_favoriteDoctor_alert_text).toString(),
                                        getTranslated(context, AppString.cancel).toString(),
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                        buttonText2: getTranslated(context, AppString.login).toString(),
                                        isConfirmationDialog: true,
                                        onPressed2: () {
                                          Navigator.pushNamed(context, 'SignIn');
                                        },
                                      );
                              },
                              title: Text(
                                getTranslated(context, AppString.home_favoritesDoctor).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.history, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                    ? Navigator.popAndPushNamed(context, 'VideoCallHistory')
                                    : FormHelper.showMessage(
                                        context,
                                        getTranslated(context, AppString.home_favoriteDoctor_alert_title).toString(),
                                        getTranslated(context, AppString.home_favoriteDoctor_alert_text).toString(),
                                        getTranslated(context, AppString.cancel).toString(),
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                        buttonText2: getTranslated(context, AppString.login).toString(),
                                        isConfirmationDialog: true,
                                        onPressed2: () {
                                          Navigator.pushNamed(context, 'SignIn');
                                        },
                                      );
                              },
                              title: Text(
                                getTranslated(context, AppString.call_history).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildChatDrawerTile(context),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.local_pharmacy_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushReplacementNamed(context, 'AllPharamacy');
                              },
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    getTranslated(context, AppString.home_medicineBuy).toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Palette.dark_blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, 'AddToCart');
                                    },
                                    icon: Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Palette.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.science_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.popAndPushNamed(context, 'Laboratory');
                              },
                              title: Text(
                                'Find Laboratories',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.local_hospital_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.popAndPushNamed(context, 'Hospitals');
                              },
                              title: Text(
                                'Find Hospitals',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.receipt_long_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                    ? Navigator.popAndPushNamed(context, 'MedicineOrder')
                                    : FormHelper.showMessage(
                                        context,
                                        getTranslated(context, AppString.home_medicineBuy_alert_title).toString(),
                                        getTranslated(context, AppString.home_medicineBuy_alert_text).toString(),
                                        getTranslated(context, AppString.cancel).toString(),
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                        buttonText2: getTranslated(context, AppString.login).toString(),
                                        isConfirmationDialog: true,
                                        onPressed2: () {
                                          Navigator.pushNamed(context, 'SignIn');
                                        },
                                      );
                              },
                              title: Text(
                                getTranslated(context, AppString.home_orderHistory).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.health_and_safety_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.popAndPushNamed(context, 'HealthTips');
                              },
                              title: Text(
                                getTranslated(context, AppString.home_healthTips).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.local_offer_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.popAndPushNamed(context, 'Offer');
                              },
                              title: Text(
                                getTranslated(context, AppString.home_offers).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                              child: Text(
                                getTranslated(context, AppString.home_courses_section).toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Palette.dark_grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.school_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.popAndPushNamed(context, 'Courses');
                              },
                              title: Text(
                                getTranslated(context, AppString.home_courses).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.notifications_none_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                    ? Navigator.popAndPushNamed(context, 'Notifications')
                                    : FormHelper.showMessage(
                                        context,
                                        getTranslated(context, AppString.home_notification_alert_title).toString(),
                                        getTranslated(context, AppString.home_notification_alert_text).toString(),
                                        getTranslated(context, AppString.cancel).toString(),
                                        () {
                                          Navigator.of(context).pop();
                                        },
                                        buttonText2: getTranslated(context, AppString.login).toString(),
                                        isConfirmationDialog: true,
                                        onPressed2: () {
                                          Navigator.pushNamed(context, 'SignIn');
                                        },
                                      );
                              },
                              title: Text(
                                getTranslated(context, AppString.home_notification).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.settings_outlined, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              onTap: () {
                                Navigator.popAndPushNamed(context, 'Setting');
                              },
                              title: Text(
                                getTranslated(context, AppString.home_settings).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Palette.dark_blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            ListTile(
                              leading: Icon(Icons.logout, color: Palette.blue),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              tileColor: Palette.white,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              title: SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                  ? GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              title: Row(
                                                children: [
                                                  Container(
                                                    height: 38,
                                                    width: 38,
                                                    decoration: BoxDecoration(
                                                      color: Palette.blue.withOpacity(0.12),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Icon(Icons.logout, color: Palette.blue, size: 20),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      getTranslated(context, AppString.home_logout_alert_title).toString(),
                                                      style: TextStyle(
                                                        color: Palette.dark_blue,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                getTranslated(context, AppString.home_logout_alert_text).toString(),
                                                style: TextStyle(
                                                  color: Palette.dark_grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(dialogContext).pop();
                                                  },
                                                  child: Text(
                                                    getTranslated(context, AppString.cancel).toString(),
                                                    style: TextStyle(color: Palette.dark_grey, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(dialogContext).pop();
                                                    logoutUser();
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Palette.blue,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    getTranslated(context, AppString.home_logout_alert_title).toString(),
                                                    style: TextStyle(color: Palette.white, fontWeight: FontWeight.w600),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Text(
                                        getTranslated(context, AppString.home_logout).toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Palette.dark_blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      '',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Palette.dark_blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            /// AppBar ///
            appBar: PreferredSize(
              preferredSize: Size(width, 120),
              child: SafeArea(
                top: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            child: TextButton(
                              onPressed: () {
                                _passIsWhere();
                                SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                    ? Navigator.pushNamed(context, 'ShowLocation')
                                    : SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                        ? Navigator.popAndPushNamed(context, 'MedicineOrder')
                                        : FormHelper.showMessage(
                                            context,
                                            getTranslated(context, AppString.home_selectAddress_alert_title).toString(),
                                            getTranslated(context, AppString.home_selectAddress_alert_text).toString(),
                                            getTranslated(context, AppString.cancel).toString(),
                                            () {
                                              Navigator.of(context).pop();
                                            },
                                            buttonText2: getTranslated(context, AppString.login).toString(),
                                            isConfirmationDialog: true,
                                            onPressed2: () {
                                              Navigator.pushNamed(context, 'SignIn');
                                            },
                                          );
                              },
                              child: _address == null || _address == ""
                                  ? Container(
                                      width: width * 0.6,
                                      child: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        text: TextSpan(
                                          children: [
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Container(
                                                  height: 20,
                                                  width: 20,
                                                  child: SvgPicture.asset(
                                                    'assets/icons/location.svg',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextSpan(
                                              text: getTranslated(context, AppString.home_selectAddress).toString(),
                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 15),
                                            ),
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                                child: Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 25,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: width * 0.6,
                                      child: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        text: TextSpan(
                                          children: [
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Container(
                                                  height: 20,
                                                  width: 20,
                                                  child: SvgPicture.asset(
                                                    'assets/icons/location.svg',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            TextSpan(
                                              text: '$_address',
                                              style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 15),
                                            ),
                                            WidgetSpan(
                                              alignment: PlaceholderAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                                child: Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 25,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(right: 10, left: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, 'AddToCart')
                                            .then((_) => _loadCartCount());
                                      },
                                      icon: Icon(
                                        Icons.shopping_cart_outlined,
                                        color: Palette.blue,
                                      ),
                                    ),
                                    if (_cartItemCount > 0)
                                      Positioned(
                                        right: 8,
                                        top: 8,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.redAccent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                IconButton(
                                  onPressed: () {
                                    _scaffoldKey.currentState!.openDrawer();
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/icons/menu.svg',
                                    height: 15,
                                    width: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.black.withOpacity(0.1),
                              blurRadius: 5,
                            )
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TextField(
                            textCapitalization: TextCapitalization.words,
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: onSearchTextChanged,
                            decoration: InputDecoration(
                              hintText: getTranslated(context, AppString.home_searchDoctor).toString(),
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: Palette.dark_blue,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(12),
                                child: SvgPicture.asset(
                                  'assets/icons/SearchIcon.svg',
                                  height: 15,
                                  width: 15,
                                ),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: refresh,
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).requestFocus(new FocusNode());
                },
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                        Care360NearbyCareHero(
                          onExplore: () => Navigator.pushNamed(context, 'MapView'),
                        ),
                        if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true &&
                            SharedPreferenceHelper.peekSecureString(Preferences.auth_token) != null)
                          Care360PartnerShowcase(slides: _partnerSlides()),
                        /// Upcoming Appointment ///
                        upcomingAppointment.length != 0
                            ? Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                                        alignment: AlignmentDirectional.topStart,
                                        child: Column(
                                          children: [
                                            Text(
                                              getTranslated(context, AppString.home_upcomingAppointment).toString(),
                                              style: TextStyle(
                                                fontSize: width * 0.04,
                                                color: Palette.dark_blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(context, 'Appointment');
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(top: 15, left: 20, right: 20),
                                          alignment: AlignmentDirectional.topStart,
                                          child: Column(
                                            children: [
                                              Text(
                                                getTranslated(context, AppString.home_viewAll).toString(),
                                                style: TextStyle(fontSize: width * 0.035, color: Palette.blue),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(15),
                                      ),
                                      child: Stack(
                                        children: <Widget>[
                                          CarouselSlider(
                                            options: CarouselOptions(
                                              height: 210,
                                              viewportFraction: 1.0,
                                              onPageChanged: (index, index1) {
                                                setState(
                                                  () {
                                                    current = index;
                                                  },
                                                );
                                              },
                                            ),
                                            items: upcomingAppointment.map((appointmentData) {
                                              final appointmentStatus = (appointmentData.appointmentStatus ?? '').toString();
                                              final appointmentStatusUpper = appointmentStatus.toUpperCase();
                                              var statusColor = Palette.green.withOpacity(0.5);
                                              if (appointmentStatusUpper == getTranslated(context, AppString.home_pending).toString()) {
                                                statusColor = Palette.dark_blue;
                                              } else if (appointmentStatusUpper == getTranslated(context, AppString.home_cancel).toString()) {
                                                statusColor = Palette.red;
                                              } else if (appointmentStatusUpper == getTranslated(context, AppString.home_approve).toString()) {
                                                statusColor = Palette.green.withOpacity(0.5);
                                              }
                                              return Builder(
                                                builder: (BuildContext context) {
                                                  final doctorName = appointmentData.doctor?.name ?? '-';
                                                  final treatmentName = appointmentData.doctor?.treatment?.name;
                                                  final visitType = appointmentData.visitType;
                                                  return Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () {
                                                          if (appointmentData.id != null) {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => AppointmentDetailScreen(
                                                                  appointmentId: appointmentData.id!,
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        borderRadius: BorderRadius.circular(20),
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            color: Palette.white,
                                                            borderRadius: BorderRadius.circular(20),
                                                            border: Border.all(color: Palette.dash_line),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Palette.dark_blue.withOpacity(0.06),
                                                                blurRadius: 16,
                                                                offset: Offset(0, 6),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Padding(
                                                                padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                                                                child: Row(
                                                                  children: [
                                                                    Container(
                                                                      width: 52,
                                                                      height: 52,
                                                                      decoration: BoxDecoration(
                                                                        borderRadius: BorderRadius.circular(16),
                                                                        border: Border.all(
                                                                          color: Palette.blue.withOpacity(0.2),
                                                                          width: 1.5,
                                                                        ),
                                                                      ),
                                                                      child: ClipRRect(
                                                                        borderRadius: BorderRadius.circular(14),
                                                                        child: (appointmentData.doctor?.fullImage != null &&
                                                                                appointmentData.doctor!.fullImage!.isNotEmpty)
                                                                            ? CachedNetworkImage(
                                                                                imageUrl: appointmentData.doctor!.fullImage!,
                                                                                fit: BoxFit.cover,
                                                                                placeholder: (_, __) => Container(
                                                                                      color: Palette.dark_white,
                                                                                      child: Center(
                                                                                        child: SizedBox(
                                                                                          height: 16,
                                                                                          width: 16,
                                                                                          child: CircularProgressIndicator(
                                                                                            strokeWidth: 2,
                                                                                            color: Palette.blue,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                errorWidget: (_, __, ___) => Container(
                                                                                      color: Palette.dark_white,
                                                                                      child: Icon(Icons.person, color: Palette.grey, size: 26),
                                                                                    ),
                                                                              )
                                                                            : Container(
                                                                                color: Palette.dark_white,
                                                                                child: Icon(Icons.person, color: Palette.grey, size: 26),
                                                                              ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(width: 14),
                                                                    Expanded(
                                                                      child: Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            doctorName,
                                                                            style: TextStyle(
                                                                              fontSize: 15,
                                                                              color: Palette.dark_blue,
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                            overflow: TextOverflow.ellipsis,
                                                                            maxLines: 1,
                                                                          ),
                                                                          if (treatmentName != null && treatmentName.isNotEmpty) ...[
                                                                            SizedBox(height: 2),
                                                                            Text(
                                                                              treatmentName,
                                                                              style: TextStyle(fontSize: 12, color: Palette.grey),
                                                                              maxLines: 1,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          ],
                                                                          if (appointmentData.hospital?.name != null) ...[
                                                                            SizedBox(height: 2),
                                                                            Row(
                                                                              children: [
                                                                                Icon(Icons.local_hospital_rounded, size: 12, color: Palette.grey),
                                                                                SizedBox(width: 4),
                                                                                Expanded(
                                                                                  child: Text(
                                                                                    appointmentData.hospital!.name!,
                                                                                    style: TextStyle(fontSize: 11, color: Palette.grey),
                                                                                    maxLines: 1,
                                                                                    overflow: TextOverflow.ellipsis,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Container(
                                                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                                      decoration: BoxDecoration(
                                                                        color: statusColor.withOpacity(0.1),
                                                                        borderRadius: BorderRadius.circular(20),
                                                                      ),
                                                                      child: Text(
                                                                        appointmentStatusUpper.isNotEmpty ? appointmentStatusUpper : '-',
                                                                        style: TextStyle(
                                                                          fontSize: 11,
                                                                          color: statusColor,
                                                                          fontWeight: FontWeight.w700,
                                                                          letterSpacing: 0.3,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(height: 12),
                                                              Container(height: 1, color: Palette.dash_line),
                                                              Padding(
                                                                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                                                                child: Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child: Container(
                                                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                                        decoration: BoxDecoration(
                                                                          color: Palette.dark_white,
                                                                          borderRadius: BorderRadius.circular(12),
                                                                          border: Border.all(color: Palette.dash_line),
                                                                        ),
                                                                        child: Row(
                                                                          children: [
                                                                            Icon(Icons.calendar_today_rounded, size: 14, color: Palette.blue),
                                                                            SizedBox(width: 6),
                                                                            Flexible(
                                                                              child: Text(
                                                                                '${appointmentData.date ?? '-'}  ${appointmentData.time ?? '-'}',
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  color: Palette.dark_blue,
                                                                                  fontWeight: FontWeight.w600,
                                                                                ),
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(width: 10),
                                                                    Expanded(
                                                                      child: Container(
                                                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                                                        decoration: BoxDecoration(
                                                                          color: Palette.dark_white,
                                                                          borderRadius: BorderRadius.circular(12),
                                                                          border: Border.all(color: Palette.dash_line),
                                                                        ),
                                                                        child: Row(
                                                                          children: [
                                                                            Icon(Icons.person_outline_rounded, size: 14, color: Palette.blue),
                                                                            SizedBox(width: 6),
                                                                            Flexible(
                                                                              child: Text(
                                                                                appointmentData.patientName ?? '-',
                                                                                style: TextStyle(
                                                                                  fontSize: 12,
                                                                                  color: Palette.dark_blue,
                                                                                  fontWeight: FontWeight.w600,
                                                                                ),
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    if (visitType != null && visitType.isNotEmpty) ...[
                                                                      SizedBox(width: 8),
                                                                      Container(
                                                                        height: 32,
                                                                        width: 32,
                                                                        decoration: BoxDecoration(
                                                                          color: Palette.blue.withOpacity(0.1),
                                                                          borderRadius: BorderRadius.circular(10),
                                                                        ),
                                                                        child: Icon(
                                                                          visitType == 'home_visit' ? Icons.home_rounded : Icons.videocam_rounded,
                                                                          size: 16,
                                                                          color: Palette.blue,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(height: 2),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SizedBox(),

                        SizedBox(
                          height: 4,
                        ),

                        // Single patient-only placement above; no duplicate
                        // autoplay banner below the appointment summary.
                        const SizedBox(height: 10),

                        /// Treatments (Categories) ///
                        Column(
                          children: [
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                    ),
                                    alignment: AlignmentDirectional.topStart,
                                    child: Row(
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.home_treatments).toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Palette.dark_blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, 'Treatment');
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: 20, left: 20),
                                      child: Text(
                                        getTranslated(context, AppString.home_viewAll).toString(),
                                        style: TextStyle(fontSize: width * 0.035, color: Palette.blue),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            treatmentList.length != 0
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 15),
                                    child: Container(
                                    margin: EdgeInsets.only(top: 5, bottom: 0),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 4,
                                        mainAxisSpacing: 6,
                                        crossAxisSpacing: 6,
                                        // Make each card a bit shorter vertically
                                        childAspectRatio: 1.05,
                                      ),
                                      itemCount: 8 <= treatmentList.length ? 8 : treatmentList.length,
                                      itemBuilder: (context, index) {
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => TreatmentSpecialist(
                                                  id: treatmentList[index].id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Palette.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Palette.black.withOpacity(0.08),
                                                  blurRadius: 6,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: 34,
                                                  child: Padding(
                                                    padding: EdgeInsets.only(top: 6, left: 4, right: 4),
                                                    child: CachedNetworkImage(
                                                      imageUrl: treatmentList[index].fullImage!,
                                                      fit: BoxFit.contain,
                                                      placeholder: (context, url) => SpinKitFadingCircle(
                                                        color: Palette.blue,
                                                        size: 18,
                                                      ),
                                                      errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.contain),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.fromLTRB(4, 2, 4, 1),
                                                  child: Text(
                                                    treatmentList[index].name!,
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Palette.dark_blue,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  )
                                : Center(
                                    child: Container(
                                      height: 100,
                                      width: width,
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        'No Data Found',
                                        style: TextStyle(fontSize: width * 0.035, color: Palette.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                          ],
                        ),

                        SizedBox(
                          height: 10,
                        ),

                        /// Doctor Specialist List ///
                        Column(
                          children: [
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
                                    alignment: AlignmentDirectional.topStart,
                                    child: Row(
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.home_specialist).toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Palette.dark_blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, 'Specialist');
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: width * 0.04, left: width * 0.04),
                                      child: Text(
                                        getTranslated(context, AppString.home_viewAll).toString(),
                                        style: TextStyle(fontSize: width * 0.035, color: Palette.blue),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: height * 0.24,
                              width: width * 1,
                              margin: EdgeInsets.symmetric(horizontal: width * 0.03),
                              child: _searchResult.length > 0 || _search.text.isNotEmpty
                                  ? Care360HorizontalCards(
                                      itemCount: _searchResult.length,
                                      itemBuilder: (context, index) {
                                            favoriteDoctor.clear();
                                            for (int i = 0; i < _searchResult.length; i++) {
                                              _searchResult[i].isFavorite == false ? favoriteDoctor.add(false) : favoriteDoctor.add(true);
                                            }
                                            final doctor = _searchResult[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => DoctorDetail(
                                                      id: doctor.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: _buildHomeDoctorCard(doctor, width, height, index),
                                            );
                                          },
                                    )
                                  : doctorList.length > 0
                                      ? Care360HorizontalCards(
                                          itemCount: 3 <= doctorList.length ? 3 : doctorList.length,
                                          itemBuilder: (context, index) {
                                                favoriteDoctor.clear();
                                                for (int i = 0; i < doctorList.length; i++) {
                                                  doctorList[i].isFavorite == false ? favoriteDoctor.add(false) : favoriteDoctor.add(true);
                                                }

                                            final doctor = doctorList[index];
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => DoctorDetail(
                                                      id: doctor.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: _buildHomeDoctorCard(doctor, width, height, index),
                                            );
                                              },
                                        )
                                      : Center(
                                          child: Container(
                                            child: Text(
                                              'No Data Found',
                                              style: TextStyle(fontSize: width * 0.04, color: Palette.grey),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                            ),
                          ],
                        ),

                        /// Providers List ///
                        if (providerList.isNotEmpty)
                          Column(
                            children: [
                              Container(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
                                      alignment: AlignmentDirectional.topStart,
                                      child: Row(
                                        children: [
                                          Text(
                                            'Providers',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Palette.dark_blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, 'FindProviders');
                                      },
                                      child: Container(
                                        margin: EdgeInsets.only(right: width * 0.04, left: width * 0.04),
                                        child: Text(
                                          getTranslated(context, AppString.home_viewAll).toString(),
                                          style: TextStyle(fontSize: width * 0.035, color: Palette.blue),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                height: height * 0.24,
                                width: width * 1,
                                margin: EdgeInsets.symmetric(horizontal: width * 0.03),
                                child: Care360HorizontalCards(
                                  itemCount: providerList.length > 8 ? 8 : providerList.length,
                                  itemBuilder: (context, index) {
                                        final provider = providerList[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProviderDetail(id: provider.id),
                                              ),
                                            );
                                          },
                                          child: _buildHomeProviderCard(provider, width, height),
                                        );
                                      },
                                ),
                              ),
                            ],
                          ),

                        SizedBox(
                          height: 10,
                        ),

                        Column(
                          children: [
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    margin: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
                                    alignment: AlignmentDirectional.topStart,
                                    child: Row(
                                      children: [
                                        Text(
                                          'Pharmacies',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Palette.dark_blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, 'AllPharamacy');
                                    },
                                    child: Container(
                                      margin: EdgeInsets.only(right: width * 0.04, left: width * 0.04),
                                      child: Text(
                                        getTranslated(context, AppString.home_viewAll).toString(),
                                        style: TextStyle(fontSize: width * 0.035, color: Palette.blue),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pharmacyList.length != 0
                                ? Container(
                                    height: 210,
                                    width: width,
                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    child: ListView.builder(
                                      itemCount: 7 <= pharmacyList.length ? 7 : pharmacyList.length,
                                      physics: BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, index) {
                                        final pharmacy = pharmacyList[index];
                                        final description = (pharmacy.description ?? "").replaceAll(RegExp(r'<[^>]*>'), '').trim();
                                        final address = (pharmacy.address ?? "").trim();
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PharamacyDetail(id: pharmacy.id),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 200,
                                            child: Card(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.0),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                    child: CachedNetworkImage(
                                                      alignment: Alignment.center,
                                                      imageUrl: pharmacy.fullImage ?? "",
                                                      height: 120,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                                      errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          pharmacy.name ?? "",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Palette.dark_blue,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (description.isNotEmpty) ...[
                                                          SizedBox(height: 4),
                                                          Text(
                                                            description,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Palette.grey,
                                                            ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                        if (address.isNotEmpty) ...[
                                                          SizedBox(height: 4),
                                                          Text(
                                                            address,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Palette.grey,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Center(
                                    child: Container(
                                      height: 125,
                                      width: width,
                                      alignment: AlignmentDirectional.center,
                                      child: Text(
                                        'No Data Found',
                                        style: TextStyle(fontSize: width * 0.04, color: Palette.grey),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                          ],
                        ),

                        SizedBox(
                          height: 10,
                        ),

                        /// Offer ///
                        offerList.length != 0
                            ? Column(
                                children: [
                                  Container(
                                    alignment: AlignmentDirectional.topStart,
                                    margin: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
                                    child: Column(
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.home_offers).toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Palette.dark_blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: 200,
                                    width: width * 1,
                                    child: ListView.builder(
                                      itemCount: offerList.length,
                                      physics: BouncingScrollPhysics(),
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                          child: Container(
                                            height: 160,
                                            width: 175,
                                            child: Card(
                                              color: index % 2 == 0 ? Palette.light_blue.withOpacity(0.9) : Palette.offer_card.withOpacity(0.9),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10.0),
                                              ),
                                              child: Column(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                                    child: Container(
                                                      height: 40,
                                                      margin: EdgeInsets.symmetric(vertical: 5),
                                                      child: Center(
                                                        child: Text(
                                                          offerList[index].name!,
                                                          style: TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                                                          textAlign: TextAlign.center,
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                                                    child: Column(
                                                      children: [
                                                        DottedLine(
                                                          direction: Axis.horizontal,
                                                          lineLength: double.infinity,
                                                          lineThickness: 1.0,
                                                          dashLength: 3.0,
                                                          dashColor: index % 2 == 0 ? Palette.light_blue.withOpacity(0.9) : Palette.offer_card.withOpacity(0.9),
                                                          dashRadius: 0.0,
                                                          dashGapLength: 1.0,
                                                          dashGapColor: Palette.transparent,
                                                          dashGapRadius: 0.0,
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  if (offerList[index].discountType == "amount" && offerList[index].isFlat == 0)
                                                    Container(
                                                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                      child: Text(
                                                        getTranslated(context, AppString.home_flat).toString() + ' ' + SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + offerList[index].discount.toString(),
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Palette.dark_blue,
                                                        ),
                                                      ),
                                                    ),
                                                  if (offerList[index].discountType == "percentage" && offerList[index].isFlat == 0)
                                                    Container(
                                                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                      // alignment: Alignment.topLeft,
                                                      child: Text(
                                                        offerList[index].discount.toString() + getTranslated(context, AppString.home_discount).toString(),
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 2,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Palette.dark_blue,
                                                        ),
                                                      ),
                                                    ),
                                                  if (offerList[index].discountType == "amount" && offerList[index].isFlat == 1)
                                                    Container(
                                                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                      child: Text(
                                                        getTranslated(context, AppString.home_flat).toString() + SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + offerList[index].flatDiscount.toString(),
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.ellipsis,
                                                        maxLines: 2,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: Palette.dark_blue,
                                                        ),
                                                      ),
                                                    ),
                                                  Container(
                                                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(color: Palette.white, borderRadius: BorderRadius.circular(10)),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(8),
                                                      child: SelectableText(
                                                        offerList[index].offerCode!,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          // fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Container(),
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

  Future<BaseModel<Treatments>> callApiTreatment() async {
    Treatments response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).treatmentsRequest();
      setState(() {
        loading = false;
        if (response.success == true) {
          setState(() {
            treatmentList.addAll(response.data!);
          });
        }
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<pharmacy_model.pharmacyModel>> callApiPharmacy() async {
    pharmacy_model.pharmacyModel response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).pharmacyRequest(_lat, _lang);
      setState(() {
        loading = false;
        if (response.success == true) {
          pharmacyList.clear();
          final list = response.data ?? [];
          list.sort((a, b) {
            final da = _distanceKmForPharmacy(a) ?? double.infinity;
            final db = _distanceKmForPharmacy(b) ?? double.infinity;
            return da.compareTo(db);
          });
          pharmacyList.addAll(list);
        }
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  double? _distanceKmForPharmacy(pharmacy_model.Data p) {
    final dFromApi = p.distanceKm != null ? double.tryParse(p.distanceKm!.trim()) : null;
    if (dFromApi != null && !dFromApi.isNaN) return dFromApi;
    if (p.lat == null || p.lng == null) return null;
    final userLat = double.tryParse((_lat ?? '').toString());
    final userLng = double.tryParse((_lang ?? '').toString());
    if (userLat == null || userLng == null) return null;
    const earthRadiusKm = 6371.0;
    final dLat = (p.lat! - userLat) * (pi / 180.0);
    final dLon = (p.lng! - userLng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * (pi / 180.0)) *
            cos(p.lat! * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<BaseModel<Doctors>> callApiDoctorList() async {
    Doctors response;
    Map<String, dynamic> body = {
      "lat": _lat,
      "lang": _lang,
    };
    setState(() {
      loading = true;
    });
    try {
      SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true ? response = await RestClient(RetroApi().dioData()).doctorList(body) : response = await RestClient(RetroApi2().dioData2()).doctorList(body);
      setState(() {
        loading = false;
        doctorList.clear();
        final list = response.data ?? [];
        list.sort((a, b) {
          final da = _distanceKmForDoctor(a) ?? double.infinity;
          final db = _distanceKmForDoctor(b) ?? double.infinity;
          return da.compareTo(db);
        });
        doctorList.addAll(list);
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  String? _formatDistanceLabel(String? distanceKm) {
    if (distanceKm == null) return null;
    final trimmed = distanceKm.trim();
    if (trimmed.isEmpty || trimmed == 'null') return null;
    final value = double.tryParse(trimmed);
    if (value == null) return null;
    if (value < 1.0) {
      final meters = (value * 1000).round();
      return '$meters m away';
    }
    return '${value.toStringAsFixed(1)} km away';
  }

  double? _distanceKmForDoctor(DoctorModel doctor) {
    if (doctor.lat == null || doctor.lng == null) return null;
    final userLat = double.tryParse((_lat ?? '').toString());
    final userLng = double.tryParse((_lang ?? '').toString());
    if (userLat == null || userLng == null) return null;
    const earthRadiusKm = 6371.0;
    final dLat = (doctor.lat! - userLat) * (pi / 180.0);
    final dLon = (doctor.lng! - userLng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * (pi / 180.0)) *
            cos(doctor.lat! * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Widget _buildHomeDoctorCard(DoctorModel doctor, double width, double height, int index) {
    num? ratingValue;
    if (doctor.rate is num) {
      ratingValue = doctor.rate as num;
    } else if (doctor.rate != null) {
      ratingValue = num.tryParse(doctor.rate.toString());
    }
    String? distanceLabel = _formatDistanceLabel(doctor.distanceKm);
    if (distanceLabel == null) {
      final distanceKm = _distanceKmForDoctor(doctor);
      if (distanceKm != null) {
        distanceLabel = _formatDistanceLabel(distanceKm.toString());
      }
    }
    final bool showRating = ratingValue != null;
    final bool showDistance = distanceLabel != null;

    return Container(
      width: width * 0.4,
      margin: EdgeInsets.symmetric(horizontal: width * 0.025),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Palette.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: height * 0.11,
                    height: height * 0.11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.dark_white,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        alignment: Alignment.center,
                        imageUrl: doctor.fullImage ?? "",
                        fit: BoxFit.cover,
                        placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                        errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg"),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Palette.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Palette.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        onPressed: () {
                          if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
                            setState(() {
                              favoriteDoctor[index] = !favoriteDoctor[index];
                              doctorID = doctor.id;
                              callApiFavoriteDoctor();
                            });
                          } else {
                            Fluttertoast.showToast(
                              msg: getTranslated(context, AppString.home_pleaseLogin_toast).toString(),
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Palette.blue,
                              textColor: Palette.white,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.favorite_outlined,
                          color: favoriteDoctor[index] ? Palette.red : Palette.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                doctor.name ?? "",
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Palette.dark_blue,
                ),
              ),
              SizedBox(height: 4),
              Text(
                doctor.treatment != null ? doctor.treatment!.name.toString() : getTranslated(context, AppString.home_notAvailable).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (showRating || showDistance)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showRating)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Palette.blue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4),
                            Text(
                              (ratingValue!.toDouble()).toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Palette.dark_blue,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(width: 0),
                    if (showDistance)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Palette.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            distanceLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Palette.grey,
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(width: 0),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeProviderCard(ProviderModel provider, double width, double height) {
    num? ratingValue;
    if (provider.rate is num) {
      ratingValue = provider.rate as num;
    } else if (provider.rate != null) {
      ratingValue = num.tryParse(provider.rate.toString());
    }
    // Always show a rating, defaulting to 0.0 when no value is returned.
    ratingValue ??= 0;
    final String? distanceLabel = _formatDistanceLabel(provider.distanceKm);
    final bool showRating = true;
    final bool showDistance = distanceLabel != null;

    return Container(
      width: width * 0.4,
      margin: EdgeInsets.symmetric(horizontal: width * 0.025),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Palette.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: height * 0.11,
                height: height * 0.11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.dark_white,
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    alignment: Alignment.center,
                    imageUrl: provider.fullImage ?? provider.image ?? "",
                    fit: BoxFit.cover,
                    placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                    errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg"),
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text(
                provider.name ?? '',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Palette.dark_blue,
                ),
              ),
              SizedBox(height: 4),
              Text(
                provider.providerType?.name ?? getTranslated(context, AppString.home_notAvailable).toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (showRating || showDistance)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (showRating)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Palette.blue.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 4),
                            Text(
                              (ratingValue!.toDouble()).toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Palette.dark_blue,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(width: 0),
                    if (showDistance)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Palette.grey,
                          ),
                          SizedBox(width: 4),
                          Text(
                            distanceLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Palette.grey,
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(width: 0),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<BaseModel<Providers>> callApiProviders() async {
    Providers response;
    final Map<String, dynamic> body = {
      "lat": _lat,
      "lang": _lang,
      "limit": 8,
    };
    try {
      response = await RestClient(RetroApi2().dioData2()).providersRequest(body);
      setState(() {
        providerList.clear();
        final list = response.data ?? [];
        list.sort((a, b) {
          final da = _distanceKmForProvider(a) ?? double.infinity;
          final db = _distanceKmForProvider(b) ?? double.infinity;
          return da.compareTo(db);
        });
        providerList.addAll(list);
      });
    } catch (error) {
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  double? _distanceKmForProvider(ProviderModel provider) {
    final dFromApi = provider.distanceKm != null ? double.tryParse(provider.distanceKm!.trim()) : null;
    if (dFromApi != null && !dFromApi.isNaN) return dFromApi;
    if (provider.lat == null || provider.lng == null) return null;
    final userLat = double.tryParse((_lat ?? '').toString());
    final userLng = double.tryParse((_lang ?? '').toString());
    if (userLat == null || userLng == null) return null;
    const earthRadiusKm = 6371.0;
    final dLat = (provider.lat! - userLat) * (pi / 180.0);
    final dLon = (provider.lng! - userLng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * (pi / 180.0)) *
            cos(provider.lat! * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  // Logout Api //
  Future logoutUser() async {
    await SharedPreferenceHelper.clearSecure();
    SharedPreferenceHelper.clearPref();
    await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, false);
    authProvider!.handleSignOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (BuildContext context) => Home()),
      ModalRoute.withName('SplashScreen'),
    );
  }

  Future<BaseModel<UserDetail>> callApiForUserDetail() async {
    UserDetail response;
    if (!_hasAuthToken()) {
      return BaseModel();
    }
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).userDetailRequest();
      setState(() {
        loading = false;
        name = response.name;
        email = response.email;
        phoneNo = response.phone;
        image = response.fullImage;
        _passDetail();
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  /// Only approved external HTTPS destinations enter the public carousel.
  /// No patient, appointment or location context is sent to partners.
  List<Care360PartnerSlide> _partnerSlides() {
    final slides = <Care360PartnerSlide>[];
    for (final item in banner) {
      if (item.status == 0) continue;
      final url = Care360PartnerSlide.safeDestination(item.link);
      if (url == null) continue;
      final title = (item.name ?? '').trim();
      slides.add(Care360PartnerSlide(
        title: title.isEmpty ? 'Featured service' : title,
        subtitle: (item.desc ?? '').trim().isEmpty
            ? 'Explore this featured partner' : item.desc!.trim(),
        url: url,
        imageUrl: item.fullImage,
        sponsored: item.isSponsored,
      ));
    }
    return slides;
  }

  Future<BaseModel<Banners>> callApiBanner() async {
    try {
      final response = await RestClient(RetroApi2().dioData2()).bannerRequest();
      if (mounted) {
        setState(() {
          // Refresh replaces old campaigns; it never duplicates stale slides.
          banner = response.data ?? <Add>[];
        });
      }
      return BaseModel()..data = response;
    } catch (error) {
      // Preserve the existing valid banners on a temporary network failure.
      // Never log full error bodies containing private URLs or credentials.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
  }

  Future<BaseModel<FavoriteDoctor>> callApiFavoriteDoctor() async {
    FavoriteDoctor response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).favoriteDoctorRequest(doctorID);
      setState(() {
        loading = false;
        Fluttertoast.showToast(
          msg: '${response.msg}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Palette.blue,
          textColor: Palette.white,
        );
        doctorList.clear();
        callApiDoctorList();
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<DisplayOffer>> callApIDisplayOffer() async {
    DisplayOffer response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).displayOfferRequest();
      setState(() {
        loading = false;
        offerList.addAll(response.data!);
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<Appointments>> callApiAppointment() async {
    if (!mounted || !_hasAuthToken() || _appointmentsInFlight) {
      return BaseModel<Appointments>();
    }
    _appointmentsInFlight = true;
    try {
      final response = await RestClient(RetroApi().dioData())
          .appointmentsRequest();
      if (!mounted || !_hasAuthToken()) {
        return BaseModel<Appointments>()..data = response;
      }
      if (response.success == true) {
        setState(() {
          // Periodic refresh replaces existing items. Appending here used
          // to duplicate the same appointment every 10 minutes.
          upcomingAppointment
            ..clear()
            ..addAll(response.data?.upcomingAppointment ??
                <UpcomingAppointment>[]);
        });
      }
      return BaseModel<Appointments>()..data = response;
    } catch (error) {
      // A failed refresh retains already loaded appointments.
      return BaseModel<Appointments>()
        ..setException(ServerError.withError(error: error));
    } finally {
      _appointmentsInFlight = false;
    }
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    doctorList.forEach((appointmentData) {
      if (appointmentData.name!.toLowerCase().contains(text.toLowerCase())) _searchResult.add(appointmentData);
    });
    setState(() {});
  }

  Future<BaseModel<DetailSetting>> callApiSetting() async {
    DetailSetting response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).settingRequest();
      final data = response.data;
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        loading = false;
        if (data == null) return;
        final isLoggedIn = SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true;
        if (data.mapKey != null && data.mapKey.toString() != "null") {
          SharedPreferenceHelper.setString(Preferences.map_key_value, data.mapKey.toString());
        }
        if (data.patientAppId != null && data.patientAppId != "null") {
          SharedPreferenceHelper.setString(Preferences.patientAppId, data.patientAppId!);
        }
        if (data.currencySymbol != null && data.currencySymbol != "null") {
          SharedPreferenceHelper.setString(Preferences.currency_symbol, data.currencySymbol!);
        }
        if (data.currencyCode != null && data.currencyCode != "null") {
          SharedPreferenceHelper.setString(Preferences.currency_code, data.currencyCode!);
        }
        if (data.cod.toString() != "null") {
          SharedPreferenceHelper.setString(Preferences.cod, data.cod.toString());
        }
        if (data.stripe.toString() != "null") {
          SharedPreferenceHelper.setString(Preferences.stripe, data.stripe.toString());
        }
        if (data.paypal.toString() != "null") {
          SharedPreferenceHelper.setString(Preferences.paypal, data.paypal.toString());
        }
        if (data.razor.toString() != "null") {
          SharedPreferenceHelper.setString(Preferences.razor, data.razor.toString());
        }
        if (data.flutterwave.toString() != "null") {
          SharedPreferenceHelper.setString(Preferences.flutterWave, data.flutterwave.toString());
        }
        if (data.payStack.toString() != "null") {
          SharedPreferenceHelper.setString(Preferences.payStack, data.payStack.toString());
        }
        if (isLoggedIn) {
          if (data.paypalClientId.toString() != "null") {
            SharedPreferenceHelper.setString(Preferences.paypal_Client_Id, data.paypalClientId.toString());
          }
          if (data.stripePublicKey != null && data.stripePublicKey != "null") {
            SharedPreferenceHelper.setString(Preferences.stripe_public_key, data.stripePublicKey!);
          }
          if (data.paypalSandboxKey != null) {
            SharedPreferenceHelper.setString(Preferences.paypal_sandbox_key, data.paypalSandboxKey!);
          }
          if (data.paypalProductionKey != null) {
            SharedPreferenceHelper.setString(Preferences.paypal_production_key, data.paypalProductionKey!);
          }
          if (data.razorKey != null && data.razorKey != "null") {
            SharedPreferenceHelper.setString(Preferences.razor_key, data.razorKey!);
          }
          if (data.flutterwaveKey != null && data.flutterwaveKey != "null") {
            SharedPreferenceHelper.setString(Preferences.flutterWave_key, data.flutterwaveKey!);
          }
          if (data.payStackPublicKey != null && data.payStackPublicKey != "null") {
            SharedPreferenceHelper.setString(Preferences.payStack_public_key, data.payStackPublicKey!);
          }
          if (data.agoraAppId != null) {
            SharedPreferenceHelper.setString(Preferences.agoraAppId, data.agoraAppId!);
          }
        } else {
          if (data.isLiveKey.toString() != "null") {
            SharedPreferenceHelper.setString(Preferences.isLiveKey, data.isLiveKey.toString());
          }
        }
      });
    } catch (error) {
      setState(() {
        loading = false;
      });
      // Never log exception bodies containing patient data, query URLs or tokens.
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> refresh() async {
    setState(() {
      callApiDoctorList();
    });
  }

  Future<void> getOneSingleToken() async {
    try {
      OneSignal.Notifications.addClickListener((event) async {
        if (event.result.actionId == "") {
        } else if (event.result.actionId == "decline") {
          setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoCall(
                  doctorId: event.notification.additionalData!["id"],
                  flag: "Cut",
                ),
              ),
            );
          });
          setState(() {});
        } else if (event.result.actionId == "accept") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCall(
                doctorId: event.notification.additionalData!["id"],
                flag: "InComming",
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PhoneScreen(event.notification.additionalData)),
          );
        }
      });
    } catch (e) {}
  }
}
