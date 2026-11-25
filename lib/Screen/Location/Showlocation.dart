import 'package:doctro_patient/Screen/Location/AddLocation.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Bookappointment.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/model/common_response.dart';
import 'package:doctro_patient/model/show_address_model.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../database/form_helper.dart';
import '../Payment/MedicinePayment.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../localization/localization_constant.dart';
import '../Screens/Home.dart';

class ShowLocation extends StatefulWidget {
  final bool discoveryMode;
  const ShowLocation({super.key, this.discoveryMode = false});
  @override
  _ShowLocationState createState() => _ShowLocationState();
}

class _ShowLocationState extends State<ShowLocation> {
  List<ShowAddressData> showAddress = [];

  bool loading = false;
  bool _selectingAddress = false;
  bool _addingAddress = false;

  int id = 0;

  String? _address = "";
  String? _lat = "";
  String? _lang = "";
  int? _addressId;
  int? addressId = 0;

  String? isWhere = "";

  late LocationData _locationData;
  Location location = new Location();

  double currentLat = 0.0;
  double currentLong = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    if (!widget.discoveryMode) getIsWhere();
  }

  Future<void> _loadAddresses() async {
    final hasToken = await _ensureAuthToken();
    if (!hasToken) {
      Fluttertoast.showToast(
        msg: "Please login again",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      if (mounted) {
        if (widget.discoveryMode) { Navigator.pop(context, false); return; }
        Navigator.pushReplacementNamed(context, "SignIn");
      }
      return;
    }
    callApiShowAddress();
  }

  _passAddress(selectAddress, selectLat, selectLang) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _address = selectAddress;
      _lat = selectLat;
      _lang = selectLang;
      _addressId = addressId;
      prefs.setString('Address', _address!);
      prefs.setString('lat', _lat!);
      prefs.setString('lang', _lang!);
      prefs.setInt('addressId', _addressId!);
    });
  }

  Future<void> _setDefaultAddress(ShowAddressData address) async {
    if (address.id == null || address.address == null || address.lat == null || address.lang == null) return;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('Address', address.address!);
    prefs.setString('lat', address.lat!);
    prefs.setString('lang', address.lang!);
    prefs.setInt('addressId', address.id!);
    prefs.setInt(Preferences.default_address_id, address.id!);
    prefs.setString(Preferences.default_lat, address.lat!);
    prefs.setString(Preferences.default_lang, address.lang!);
    prefs.setString(Preferences.default_Address, address.address!);
    setState(() {
      _address = address.address;
      _lat = address.lat;
      _lang = address.lang;
      _addressId = address.id;
    });
    Fluttertoast.showToast(
      msg: getTranslated(context, AppString.showLocation_defaultSet) ?? 'Default address set.',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  getIsWhere() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isWhere = prefs.getString('isWhere');
    });
    _locationData = await location.getLocation();
    currentLat = _locationData.latitude!;
    currentLong = _locationData.longitude!;
  }

  Future<bool> onWillPop() {
    if (widget.discoveryMode) return Future.value(true);
    if (isWhere == "BookAppointment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookAppointment(
            id: int.parse(SharedPreferenceHelper.getString('doctorId')!),
          ),
        ),
      );
    }
    if (isWhere == "MedicinePayment") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MedicinePayment(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Home(),
        ),
      );
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;

    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Palette.white,
          elevation: 2,
          leading: GestureDetector(
            onTap: () {
              if (widget.discoveryMode) { Navigator.pop(context, false); return; }
              if (isWhere == "BookAppointment") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointment(
                      id: int.parse(SharedPreferenceHelper.getString('doctorId')!),
                    ),
                  ),
                );
              }
              if (isWhere == "MedicinePayment") {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MedicinePayment(),
                  ),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Home(),
                  ),
                );
              }
            },
            child: Container(
              child: Icon(
                Icons.arrow_back_ios,
                color: Palette.black,
                size: 20,
              ),
            ),
          ),
          title: Text(
            getTranslated(context, AppString.showLocation_title).toString(),
            style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold, color: Palette.dark_blue),
          ),
          actions: [
            InkWell(
              onTap: () async {
                if (widget.discoveryMode) {
                  if (loading || _addingAddress || _selectingAddress) return;
                  _addingAddress = true;
                  try {
                    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddLocation(returnToPicker: true, currentLong: currentLong, currentLat: currentLat)));
                    if (mounted && added == true) await _loadAddresses();
                  } finally { _addingAddress = false; }
                  return;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddLocation(currentLong: currentLong, currentLat: currentLat),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Palette.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: AlignmentDirectional.center,
                  child: Text(
                    '+ ' + getTranslated(context, AppString.showLocation_addAddress).toString(),
                    style: TextStyle(fontSize: width * 0.032, color: Palette.blue, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          ],
        ),
        body: ModalProgressHUD(
          inAsyncCall: loading,
          opacity: 0.5,
          progressIndicator: SpinKitFadingCircle(
            color: Palette.blue,
            size: 50.0,
          ),
          child: Container(
            height: height * 1,
            color: Palette.dark_white,
            child: showAddress.length != 0
                ? ListView(
                    scrollDirection: Axis.vertical,
                    children: [
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: showAddress.length,
                        itemBuilder: (context, index) {
                          addressId = showAddress[index].id;
                          final isDefault = SharedPreferenceHelper.getInt(Preferences.default_address_id) == showAddress[index].id;
                          return InkWell(
                            onTap: () async {
                              if (widget.discoveryMode) {
                                if (_selectingAddress || _addingAddress || loading) return;
                                final selected = showAddress[index];
                                if (selected.id == null || selected.address == null || selected.lat == null || selected.lang == null) return;
                                _selectingAddress = true;
                                try {
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('Address', selected.address!);
                                await prefs.setString('lat', selected.lat!);
                                await prefs.setString('lang', selected.lang!);
                                await prefs.setInt('addressId', selected.id!);
                                if (mounted) Navigator.pop(context, true);
                                } finally { _selectingAddress = false; }
                                return;
                              }
                              setState(
                                () {
                                  if (isWhere == "Home") {
                                    _passAddress(showAddress[index].address, showAddress[index].lat, showAddress[index].lang);
                                    Navigator.pushReplacementNamed(context, "Home");
                                  } else if (isWhere == "MedicinePayment") {
                                    _passAddress(showAddress[index].address, showAddress[index].lat, showAddress[index].lang);
                                    Navigator.pushReplacementNamed(context, "MedicinePayment");
                                  } else if (isWhere == "BookAppointment") {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BookAppointment(
                                          id: int.parse(SharedPreferenceHelper.getString('doctorId')!),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Container(
                                padding: EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Palette.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Palette.black.withOpacity(0.06),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Palette.blue.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        size: 20,
                                        color: Palette.blue,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: showAddress[index].label != null
                                                    ? Text(
                                                        showAddress[index].label!,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: Palette.dark_blue,
                                                        ),
                                                      )
                                                    : Text(
                                                        getTranslated(context, AppString.showLocation_label).toString(),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: Palette.dark_blue,
                                                        ),
                                                      ),
                                              ),
                                              if (isDefault)
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Palette.blue.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    getTranslated(context, AppString.showLocation_default).toString(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Palette.blue,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            showAddress[index].address!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.start,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Palette.dark_grey,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          if (!isDefault)
                                            InkWell(
                                              onTap: () => _setDefaultAddress(showAddress[index]),
                                              child: Text(
                                                getTranslated(context, AppString.showLocation_setDefault).toString(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Palette.blue,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: Palette.red.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          FormHelper.showMessage(
                                            context,
                                            getTranslated(context, AppString.showLocation_removeAddress_alert_title).toString(),
                                            getTranslated(context, AppString.showLocation_removeAddress_alert_text).toString(),
                                            getTranslated(context, AppString.No).toString(),
                                            () {
                                              Navigator.of(context).pop();
                                            },
                                            buttonText2: getTranslated(context, AppString.Yes).toString(),
                                            isConfirmationDialog: true,
                                            onPressed2: () {
                                              callApiForDeleteAddress(showAddress[index].id);
                                              Navigator.of(context).pop();
                                            },
                                          );
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: Palette.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  )
                : Container(
                    width: width,
                    child: Center(
                      child: Text(
                        getTranslated(context, AppString.showLocation_noAddress).toString(),
                        style: TextStyle(
                          fontSize: width * 0.04,
                          color: Palette.dark_blue,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<ShowAddress>> callApiShowAddress() async {
    ShowAddress response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).showAddressRequest();
      if (!mounted) return BaseModel()..data = response;
      showAddress.clear();

      if (response.success == true) {
        setState(() {
          loading = false;
          showAddress.addAll(response.data ?? []);
        });
        if (showAddress.length == 0) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setString('Address', "");
        }
      }
    } catch (error, stacktrace) {
      if (mounted) setState(() { loading = false; });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    } finally {
      if (mounted) setState(() { loading = false; });
    }
    return BaseModel()..data = response;
  }

  bool _hasAuthToken() {
    return SharedPreferenceHelper.getBoolean(Preferences.has_auth_token);
  }

  Future<bool> _ensureAuthToken() async {
    if (_hasAuthToken()) {
      return true;
    }
    final token = await SharedPreferenceHelper.getSecureString(Preferences.auth_token);
    final hasToken = token != null && token.isNotEmpty && token != "N_A" && token != "null";
    if (hasToken) {
      await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, true);
      return true;
    }
    await SharedPreferenceHelper.setBoolean(Preferences.has_auth_token, false);
    return false;
  }

  Future<BaseModel<CommonResponse>> callApiForDeleteAddress(addressId) async {
    CommonResponse response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).deleteAddressRequest(addressId);
      if (response.success == true) {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getInt(Preferences.default_address_id) == addressId) {
          await prefs.remove(Preferences.default_address_id);
          await prefs.remove(Preferences.default_lat);
          await prefs.remove(Preferences.default_lang);
          await prefs.remove(Preferences.default_Address);
        }
        setState(() {
          loading = false;
          Fluttertoast.showToast(
            msg: response.msg!,
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Palette.blue,
            textColor: Palette.white,
          );
          callApiShowAddress();
        });
      }
    } catch (error, stacktrace) {
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}
