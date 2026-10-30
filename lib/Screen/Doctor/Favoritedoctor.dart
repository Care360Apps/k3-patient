import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/model/show_favorite_doctor_model.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../api/retrofit_Api.dart';
import '../../api/network_api.dart';
import 'doctordetail.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';
import '../../model/favorite_doctor_model.dart';

class FavoriteDoctorScreen extends StatefulWidget {
  @override
  _FavoriteDoctorScreenState createState() => _FavoriteDoctorScreenState();
}

class _FavoriteDoctorScreenState extends State<FavoriteDoctorScreen> {
  bool loading = false;

  List<Data> favoriteDoctorList = [];
  int? doctorID = 0;
  String? _lat = "";
  String? _lang = "";

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    callApiFavoriteDoctorList();
  }

  Future<void> _loadUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lat = prefs.getString('lat') ?? prefs.getString('latLive') ?? "";
      _lang = prefs.getString('lang') ?? prefs.getString('langLive') ?? "";
    });
  }

  Future<bool> onWillPop() {
    Navigator.pushReplacementNamed(context, 'Home');
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
      child: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.5,
        progressIndicator: SpinKitFadingCircle(
          color: Palette.blue,
          size: 50.0,
        ),
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 20,
                color: Palette.dark_blue,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, 'Home');
              },
            ),
            centerTitle: true,
            backgroundColor: Palette.white,
            title: Text(
              getTranslated(context, AppString.favoriteDoctor_title).toString(),
              style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
            ),
          ),
          body: favoriteDoctorList.length != 0
              ? SingleChildScrollView(
                  child: InkWell(
                    child: Container(
                      height: height * 0.9,
                      margin: EdgeInsets.only(top: 10, left: 16, right: 16),
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        children: [
                          GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: favoriteDoctorList.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.vertical,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.92,
                            ),
                            itemBuilder: (context, index) {
                              if (favoriteDoctorList.isEmpty) {
                                return Center(
                                  child: Text(
                                    getTranslated(context, AppString.favoriteDoctor_doctorNotAvailable).toString(),
                                  ),
                                );
                              }
                              return _buildFavoriteDoctorCard(context, index);
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                )
              : Container(
                  child: Center(
                    child: Text(
                      getTranslated(context, AppString.favoriteDoctor_noFavoriteDoctor).toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Palette.dark_blue,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Future<BaseModel<ShowFavoriteDoctor>> callApiFavoriteDoctorList() async {
    ShowFavoriteDoctor response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).showFavoriteDoctorRequest();
      setState(() {
        if (response.success == true) {
          loading = false;
          favoriteDoctorList.clear();
          setState(() {
            favoriteDoctorList.addAll(response.data!);
          });
        }
      });
    } catch (error, stacktrace) {
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Widget _buildFavoriteDoctorCard(BuildContext context, int index) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final item = favoriteDoctorList[index];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetail(id: item.id),
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
          padding: EdgeInsets.only(left: 12, top: 10, right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      color: Palette.white,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        alignment: Alignment.center,
                        imageUrl: item.fullImage ?? "",
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
                          setState(() {
                            doctorID = item.id;
                            callApiFavoriteDoctor();
                          });
                        },
                        icon: Icon(Icons.favorite_outlined, color: Palette.red),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
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
              SizedBox(height: 2),
              Text(
                item.treatment != null
                    ? item.treatment!.name.toString()
                    : getTranslated(context, AppString.favoriteDoctor_notAvailable).toString(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Palette.grey),
              ),
              SizedBox(height: 2),
              _buildRatingAndDistanceRow(item, width),
            ],
          ),
        ),
      ),
    );
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

  double? _distanceKmForFavorite(Data doctor) {
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

  Widget _buildRatingAndDistanceRow(Data doctor, double width) {
    num? ratingValue;
    if (doctor.rate is num) {
      ratingValue = doctor.rate as num;
    } else if (doctor.rate != null) {
      ratingValue = num.tryParse(doctor.rate.toString());
    }
    ratingValue ??= 0;

    String? distanceLabel = _formatDistanceLabel(null);
    final distanceKm = _distanceKmForFavorite(doctor);
    if (distanceKm != null) {
      distanceLabel = _formatDistanceLabel(distanceKm.toString());
    }

    final bool showRating = true;
    final bool showDistance = distanceLabel != null;

    if (!showRating && !showDistance) return SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showRating)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Palette.green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: Palette.green),
                SizedBox(width: 4),
                Text(
                  (ratingValue!.toDouble()).toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Palette.green,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox.shrink(),
        if (showDistance)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined, size: 14, color: Palette.grey),
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
        if (response.success == true) {
          setState(() {
            callApiFavoriteDoctorList();
            Fluttertoast.showToast(
              msg: '${response.msg}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
              backgroundColor: Palette.blue,
              textColor: Palette.white,
            );
          });
        }
      });
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
