import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/model/providers_model.dart';
import 'package:doctro_patient/Screen/Provider/ProviderDetail.dart';
import 'package:doctro_patient/Screen/Location/Showlocation.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Chat/loading_view.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/prefConstatnt.dart';
import '../../localization/localization_constant.dart';

class FindProvidersScreen extends StatefulWidget {
  @override
  _FindProvidersScreenState createState() => _FindProvidersScreenState();
}

class _FindProvidersScreenState extends State<FindProvidersScreen> {
  bool loading = false;
  String? _address = "";
  String? _lat = "";
  String? _lang = "";
  String? _liveLat = "";
  String? _liveLang = "";
  bool useLiveLocation = false;

  List<ProviderModel> providerList = [];
  TextEditingController _search = TextEditingController();
  List<ProviderModel> _searchResult = [];

  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final resolvedLat = _resolveCoordinate(prefs.getString('lat')) ?? _resolveCoordinate(prefs.getString('latLive'));
    final resolvedLang = _resolveCoordinate(prefs.getString('lang')) ?? _resolveCoordinate(prefs.getString('langLive'));
    setState(() {
      _address = prefs.getString('Address');
      _lat = resolvedLat ?? "";
      _lang = resolvedLang ?? "";
      _liveLat = _resolveCoordinate(prefs.getString('latLive')) ?? "";
      _liveLang = _resolveCoordinate(prefs.getString('langLive')) ?? "";
    });
    callApiProviders();
  }

  Future<bool> onWillPop() {
    Navigator.pushReplacementNamed(context, 'Home');
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
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
                        icon: Icon(Icons.arrow_back_ios, size: 22),
                        onPressed: () => Navigator.pushReplacementNamed(context, 'Home'),
                      ),
                      Expanded(
                        child: Text(
                          getTranslated(context, AppString.home_find_providers) ?? 'Find Providers',
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
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ShowLocation()),
                      );
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
                          SvgPicture.asset('assets/icons/location.svg', height: 18, width: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _locationLabel(),
                              style: TextStyle(fontSize: 14, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Palette.blue),
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
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
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
                          hintText: getTranslated(context, AppString.provider_search_hint) ?? 'Search providers...',
                          hintStyle: TextStyle(fontSize: 14, color: Palette.dark_blue.withOpacity(0.7)),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: SvgPicture.asset('assets/icons/SearchIcon.svg', height: 15, width: 15),
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
          onRefresh: callApiProviders,
          child: ModalProgressHUD(
            child: _searchResult.isNotEmpty || _search.text.isNotEmpty
                ? (_searchResult.isNotEmpty
                    ? _buildProviderGrid(_searchResult, width, height)
                    : _emptyState(width))
                : (providerList.isNotEmpty
                    ? _buildProviderGrid(providerList, width, height)
                    : _emptyState(width)),
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
                ? [BoxShadow(color: Palette.blue.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 3))]
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

  Widget _buildProviderGrid(List<ProviderModel> items, double width, double height) {
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
            final item = items[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProviderDetail(id: item.id),
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
                            imageUrl: item.fullImage ?? item.image ?? "",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => ShimmerIndicator(size: 28),
                            errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg"),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        item.name ?? "",
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                      ),
                      SizedBox(height: 4),
                      Text(
                        item.providerType != null ? item.providerType!.name ?? "" : getTranslated(context, AppString.specialist_notAvailable).toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Palette.grey),
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
                          final String? distanceLabel = _formatDistanceLabel(item.distanceKm);
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

  Widget _emptyState(double width) {
    return Container(
      alignment: AlignmentDirectional.center,
      child: Text(
        getTranslated(context, AppString.home_notFound).toString(),
        style: TextStyle(fontSize: width * 0.04, color: Palette.grey, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<BaseModel<Providers>> callApiProviders() async {
    // When Live is selected but live coords are missing, fall back to saved address so list still loads
    final latToUse = useLiveLocation
        ? (_resolveCoordinate(_liveLat) ?? _resolveCoordinate(_lat))
        : _resolveCoordinate(_lat);
    final langToUse = useLiveLocation
        ? (_resolveCoordinate(_liveLang) ?? _resolveCoordinate(_lang))
        : _resolveCoordinate(_lang);
    if (latToUse == null || langToUse == null) {
      Fluttertoast.showToast(
        msg: getTranslated(context, AppString.home_selectAddress).toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return BaseModel();
    }
    Map<String, dynamic> body = {"lat": latToUse, "lang": langToUse, "limit": 50};
    setState(() => loading = true);
    try {
      final response = await RestClient(RetroApi2().dioData2()).providersRequest(body);
      setState(() {
        loading = false;
        providerList.clear();
        final list = response.data ?? [];
        list.sort((a, b) {
          final da = _distanceKmForProvider(a, latToUse, langToUse) ?? double.infinity;
          final db = _distanceKmForProvider(b, latToUse, langToUse) ?? double.infinity;
          return da.compareTo(db);
        });
        providerList.addAll(list);
      });
      return BaseModel()..data = response;
    } catch (error, stacktrace) {
      setState(() => loading = false);
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
  }

  double? _distanceKmForProvider(ProviderModel p, String? userLatStr, String? userLngStr) {
    final dFromApi = p.distanceKm != null ? double.tryParse(p.distanceKm!.trim()) : null;
    if (dFromApi != null && !dFromApi.isNaN) return dFromApi;
    if (p.lat == null || p.lng == null) return null;
    final userLat = double.tryParse((userLatStr ?? '').toString());
    final userLng = double.tryParse((userLngStr ?? '').toString());
    if (userLat == null || userLng == null) return null;
    const earthRadiusKm = 6371.0;
    final dLat = (p.lat! - userLat) * (pi / 180.0);
    final dLon = (p.lng! - userLng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * (pi / 180.0)) * cos(p.lat! * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  String? _resolveCoordinate(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == "N_A" || trimmed == "null") return null;
    return trimmed;
  }

  String _locationLabel() {
    if (useLiveLocation) return getTranslated(context, AppString.specialist_filter_live).toString();
    if (_address == null || _address!.trim().isEmpty || _address == "N_A") {
      return getTranslated(context, AppString.home_selectAddress).toString();
    }
    return _address!;
  }

  void _applyLocationFilter(bool live) {
    // Allow switching to Live even when live coords are missing; API will use saved address as fallback
    setState(() => useLiveLocation = live);
    callApiProviders();
  }

  void onSearchTextChanged(String text) {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }
    for (var p in providerList) {
      if ((p.name ?? "").toLowerCase().contains(text.toLowerCase())) _searchResult.add(p);
    }
    setState(() {});
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
}
