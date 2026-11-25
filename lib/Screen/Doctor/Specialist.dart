import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/Screen/Doctor/doctordetail.dart';
import 'package:doctro_patient/Screen/Location/Showlocation.dart';
import 'package:doctro_patient/model/doctors_model.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../../Chat/loading_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/prefConstatnt.dart';
import '../../localization/localization_constant.dart';
import '../../model/favorite_doctor_model.dart';

class Specialist extends StatefulWidget {
  @override
  _SpecialistState createState() => _SpecialistState();
}

class _SpecialistState extends State<Specialist> {
  bool loading = false;
  String? _address = "";
  String? _lat = "";
  String? _lang = "";
  String? _liveLat = "";
  String? _liveLang = "";
  int _discoveryRequest = 0;
  bool useLiveLocation = false;

  List<DoctorModel> doctorList = [];

  List<bool> favoriteDoctor = [];
  List<bool> searchFavoriteDoctor = [];
  int? doctorID = 0;

  TextEditingController _search = TextEditingController();
  List<DoctorModel> _searchResult = [];

  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final resolvedLat = _resolveCoordinate(prefs.getString('lat')) ?? _resolveCoordinate(prefs.getString('latLive'));
    final resolvedLang = _resolveCoordinate(prefs.getString('lang')) ?? _resolveCoordinate(prefs.getString('langLive'));
    setState(
      () {
        _address = (prefs.getString('Address'));
        _lat = resolvedLat ?? "";
        _lang = resolvedLang ?? "";
        _liveLat = _resolveCoordinate(prefs.getString('latLive')) ?? "";
        _liveLang = _resolveCoordinate(prefs.getString('langLive')) ?? "";
      },
    );
    callApiDoctorList();
  }

  Future<bool> onWillPop() {
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
        backgroundColor: Palette.dark_white,
        appBar: PreferredSize(
          preferredSize: Size(width, 210),
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          getTranslated(context, AppString.home_book_appointment).toString(),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Palette.dark_blue),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const ShowLocation(discoveryMode: true)),
                      );
                      if (!mounted || changed != true) return;
                      setState(() => useLiveLocation = false);
                      await _getAddress();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Palette.white,
                        borderRadius: BorderRadius.circular(18),
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
                          SvgPicture.asset(
                            'assets/icons/location.svg',
                            height: 18,
                            width: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationLabel(),
                              style: TextStyle(fontSize: 14, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Palette.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildLocationFilterChip(
                        label: getTranslated(context, AppString.specialist_filter_saved).toString(),
                        selected: !useLiveLocation,
                        onTap: () => _applyLocationFilter(false),
                      ),
                      SizedBox(width: 10),
                      _buildLocationFilterChip(
                        label: getTranslated(context, AppString.specialist_filter_live).toString(),
                        selected: useLiveLocation,
                        onTap: () => _applyLocationFilter(true),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Palette.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: _search,
                        textCapitalization: TextCapitalization.words,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: onSearchTextChanged,
                        decoration: InputDecoration(
                          hintText: getTranslated(context, AppString.specialist_searchDoctor_hint).toString(),
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Palette.dark_blue.withOpacity(0.7),
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
          onRefresh: callApiDoctorList,
          child: ModalProgressHUD(
            child: _searchResult.length > 0 || _search.text.isNotEmpty
                ? _searchResult.length != 0
                    ? _buildDoctorGrid(_searchResult, width, height, true)
                    : Container(
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          getTranslated(context, AppString.specialist_doctorNotFound).toString(),
                          style: TextStyle(fontSize: width * 0.04, color: Palette.grey, fontWeight: FontWeight.bold),
                        ),
                      )
                : doctorList.length != 0
                    ? _buildDoctorGrid(doctorList, width, height, false)
                    : Container(
                        alignment: AlignmentDirectional.center,
                        child: Text(
                          getTranslated(context, AppString.specialist_doctorNotFound).toString(),
                          style: TextStyle(fontSize: width * 0.04, color: Palette.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
            inAsyncCall: loading,
            opacity: 0.5,
            progressIndicator: ShimmerIndicator(size: 56),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFilterChip({required String label, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Palette.blue : Palette.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.blue.withOpacity(0.2)),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Palette.blue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Palette.white : Palette.dark_blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorGrid(List<DoctorModel> items, double width, double height, bool isSearch) {
    _prepareFavorites(items, isSearch);
    return ListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 20),
      children: [
        GridView.builder(
          physics: NeverScrollableScrollPhysics(),
          itemCount: items.length,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // Make cards a bit shorter vertically to reduce bottom empty space
            childAspectRatio: 0.92,
          ),
          itemBuilder: (context, index) {
            final favoriteList = isSearch ? searchFavoriteDoctor : favoriteDoctor;
            final item = items[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorDetail(
                      id: item.id,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
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
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                                imageUrl: item.fullImage ?? "",
                                fit: BoxFit.cover,
                                placeholder: (context, url) => ShimmerIndicator(size: 28),
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
                                      favoriteList[index] = !favoriteList[index];
                                      doctorID = item.id;
                                      callApiFavoriteDoctor();
                                    });
                                  } else {
                                    Fluttertoast.showToast(
                                      msg: getTranslated(context, AppString.specialist_pleaseLogin_toast).toString(),
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor: Palette.blue,
                                      textColor: Palette.white,
                                    );
                                  }
                                },
                                icon: Icon(
                                  Icons.favorite_outlined,
                                  color: favoriteList[index] ? Palette.red : Palette.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        item.name ?? "",
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
                        item.treatment != null ? item.treatment!.name.toString() : getTranslated(context, AppString.specialist_notAvailable).toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Palette.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          num? ratingValue;
                          if (item.rate is num) {
                            ratingValue = item.rate as num;
                          } else if (item.rate != null) {
                            ratingValue = num.tryParse(item.rate.toString());
                          }
                          String? distanceLabel = _formatDistanceLabel(item.distanceKm);
                          if (distanceLabel == null) {
                            final distanceKm = _distanceKmForDoctor(item);
                            if (distanceKm != null) {
                              distanceLabel = _formatDistanceLabel(distanceKm.toString());
                            }
                          }
                          final bool showRating = ratingValue != null;
                          final bool showDistance = distanceLabel != null;

                          if (!showRating && !showDistance) {
                            return SizedBox.shrink();
                          }

                          return Row(
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<BaseModel<Doctors>> callApiDoctorList() async {
    if (!mounted) return BaseModel();
    final request = ++_discoveryRequest;
    Doctors response;
    // When Live is selected but live coords are missing, fall back to saved address so list still loads
    final latToUse = useLiveLocation
        ? (_resolveCoordinate(_liveLat) ?? _resolveCoordinate(_lat))
        : _resolveCoordinate(_lat);
    final langToUse = useLiveLocation
        ? (_resolveCoordinate(_liveLang) ?? _resolveCoordinate(_lang))
        : _resolveCoordinate(_lang);
    if (latToUse == null || langToUse == null) {
      setState(() => loading = false);
      Fluttertoast.showToast(
        msg: getTranslated(context, AppString.home_selectAddress).toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return BaseModel();
    }
    Map<String, dynamic> body = {
      "lat": latToUse,
      "lang": langToUse,
    };
    setState(() {
      loading = true;
    });
    try {
      SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true ? response = await RestClient(RetroApi().dioData()).doctorList(body) : response = await RestClient(RetroApi2().dioData2()).doctorList(body);
      if (!mounted || request != _discoveryRequest) return BaseModel()..data = response;
      setState(() {
        loading = false;
        if (response.success == true) {
          setState(() {
            doctorList.clear();
            loading = false;
            final list = response.data ?? [];
            list.sort((a, b) {
              final da = _distanceKmForDoctorWith(a, latToUse, langToUse) ?? double.infinity;
              final db = _distanceKmForDoctorWith(b, latToUse, langToUse) ?? double.infinity;
              return da.compareTo(db);
            });
            doctorList.addAll(list);
            _searchResult = doctorList.where((item) => (item.name ?? '').toLowerCase().contains(_search.text.toLowerCase())).toList();
          });
        }
      });
    } catch (error, stacktrace) {
      if (!mounted || request != _discoveryRequest) return BaseModel()..setException(ServerError.withError(error: error));
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  String? _resolveCoordinate(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == "N_A" || trimmed == "null") return null;
    return trimmed;
  }

  double? _distanceKmForDoctor(DoctorModel doctor) {
    return _distanceKmForDoctorWith(doctor, _lat, _lang);
  }

  double? _distanceKmForDoctorWith(DoctorModel doctor, String? userLatStr, String? userLngStr) {
    final dFromApi = doctor.distanceKm != null ? double.tryParse(doctor.distanceKm!.trim()) : null;
    if (dFromApi != null && !dFromApi.isNaN) return dFromApi;
    if (doctor.lat == null || doctor.lng == null) return null;
    final userLat = double.tryParse((userLatStr ?? '').toString());
    final userLng = double.tryParse((userLngStr ?? '').toString());
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

  String _locationLabel() {
    if (useLiveLocation) {
      return getTranslated(context, AppString.specialist_filter_live).toString();
    }
    if (_address == null || _address!.trim().isEmpty || _address == "N_A") {
      return getTranslated(context, AppString.home_selectAddress).toString();
    }
    return _address!;
  }

  void _applyLocationFilter(bool live) {
    // Allow switching to Live even when live coords are missing; API will use saved address as fallback
    setState(() {
      useLiveLocation = live;
    });
    callApiDoctorList();
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

  void _prepareFavorites(List<DoctorModel> items, bool isSearch) {
    final target = isSearch ? searchFavoriteDoctor : favoriteDoctor;
    target.clear();
    for (final item in items) {
      target.add(item.isFavorite == true);
    }
  }

  Future<BaseModel<FavoriteDoctor>> callApiFavoriteDoctor() async {
    FavoriteDoctor response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).favoriteDoctorRequest(doctorID);
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        loading = false;
        if (response.success == true) {
          setState(
            () {
              Fluttertoast.showToast(
                msg: '${response.msg}',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Palette.blue,
                textColor: Palette.white,
              );
              doctorList.clear();
              callApiDoctorList();
            },
          );
        }
      });
    } catch (error, stacktrace) {
      if (!mounted) return BaseModel()..setException(ServerError.withError(error: error));
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    doctorList.forEach((appointmentData) {
      if ((appointmentData.name ?? '').toLowerCase().contains(text.toLowerCase())) _searchResult.add(appointmentData);
    });

    setState(() {});
  }
}
