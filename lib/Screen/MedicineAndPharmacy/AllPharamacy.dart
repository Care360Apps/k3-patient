import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/PharamacyDetail.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/model/pharmacys_model.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:flutter_svg/svg.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../brand/care360_service_intro.dart';
import '../../localization/localization_constant.dart';

class AllPharamacy extends StatefulWidget {
  @override
  _AllPharamacyState createState() => _AllPharamacyState();
}

class _AllPharamacyState extends State<AllPharamacy> {
  bool loading = true;
  bool _loadFailed = false;
  String? address = "";
  String? _lat;
  String? _lang;

  List<Data> pharamacy = [];

  TextEditingController _search = TextEditingController();
  List<Data> _searchResult = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _getAddress();
      if (mounted) await callApiPharamacy();
    } catch (_) {
      if (mounted) setState(() { loading = false; _loadFailed = true; });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(
      () {
        address = prefs.getString('Address');
        _lat = prefs.getString('lat');
        _lang = prefs.getString('lang');
      },
    );
  }

  Future<bool> onWillPop() {
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size(width, 110),
          child: SafeArea(
            top: true,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      address == null || address == ""
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
                                      text: '$address',
                                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: 22,
                        ),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
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
                        controller: _search,
                        textAlign: TextAlign.left,
                        textCapitalization: TextCapitalization.words,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: onSearchTextChanged,
                        decoration: InputDecoration(
                          hintText: getTranslated(context, AppString.allPharamacy_searchPharamacy).toString(),
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
        body: Column(
          children: [
            const Care360ServiceIntro(
              title: 'Pharmacies',
              titleKey: 'care360_service_pharmacies',
              description: 'Find nearby medicine services',
              descriptionKey: 'care360_dir_pharmacies_description',
              icon: Icons.local_pharmacy_outlined,
            ),
            Expanded(child: ModalProgressHUD(
          inAsyncCall: loading,
          opacity: 0.5,
          progressIndicator: SpinKitFadingCircle(
            color: Palette.blue,
            size: 50.0,
          ),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: _loadFailed
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Unable to load pharmacies.'),
                    TextButton(onPressed: loading ? null : _initialize, child: const Text('Retry')),
                  ]))
                : _search.text.trim().isNotEmpty
                ? _searchResult.isNotEmpty
                    ? _buildPharmacyGrid(_searchResult, width)
                    : Center(
                        child: Text(
                          getTranslated(context, AppString.allPharamacy_pharmacyNotFound).toString(),
                          style: TextStyle(fontSize: width * 0.04, color: Palette.grey, fontWeight: FontWeight.bold),
                        ),
                      )
                : pharamacy.isNotEmpty
                    ? _buildPharmacyGrid(pharamacy, width)
                    : Center(
                        child: Text(
                          getTranslated(context, AppString.allPharamacy_pharmacyNotFound).toString(),
                          style: TextStyle(fontSize: width * 0.04, color: Palette.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
          ),
        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyGrid(List<Data> items, double width) {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.88,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final pharmacy = items[index];
        final addressText = (pharmacy.address ?? "").trim();
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PharamacyDetail(id: pharmacy.id),
              ),
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
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
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                      if (addressText.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Palette.grey,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                addressText,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Palette.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PharamacyDetail(id: pharmacy.id),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Palette.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                          ),
                          child: Text(
                            getTranslated(context, AppString.allPharamacy_book_button).toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Palette.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<BaseModel<pharmacyModel>> callApiPharamacy() async {
    pharmacyModel response;

    setState(() {
      loading = true;
      _loadFailed = false;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).pharmacyRequest(_lat, _lang);
      if (!mounted) return BaseModel()..data = response;
      setState(() {
        loading = false;
        _loadFailed = response.success != true;
        if (response.success == true) {
          pharamacy.clear();
          final list = response.data ?? [];
          list.sort((a, b) {
            final da = _distanceKmForPharmacy(a) ?? double.infinity;
            final db = _distanceKmForPharmacy(b) ?? double.infinity;
            return da.compareTo(db);
          });
          pharamacy.addAll(list);
          _searchResult = pharamacy.where((p) => '${p.name ?? ''} ${p.address ?? ''}'.toLowerCase().contains(_search.text.trim().toLowerCase())).toList();
        }
      });
    } catch (error) {
      if (mounted) setState(() {
        loading = false;
        _loadFailed = true;
      });
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  double? _distanceKmForPharmacy(Data p) {
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
        cos(userLat * (pi / 180.0)) * cos(p.lat! * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  onSearchTextChanged(String text) async {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    pharamacy.forEach((appointmentData) {
      if ('${appointmentData.name ?? ''} ${appointmentData.address ?? ''}'.toLowerCase().contains(text.trim().toLowerCase())) _searchResult.add(appointmentData);
    });

    setState(() {});
  }
}
