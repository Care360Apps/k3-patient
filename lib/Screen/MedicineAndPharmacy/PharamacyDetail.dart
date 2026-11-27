import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/MedicineDescription.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/model/pharmacys_details_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' hide Marker;
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:doctro_patient/nearby/maplibre_marker_adapter.dart';
import 'package:doctro_patient/nearby/maplibre_nearby_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../localization/localization_constant.dart';

class PharamacyDetail extends StatefulWidget {
  final int? id;

  PharamacyDetail({this.id});

  @override
  _PharamacyDetailState createState() => _PharamacyDetailState();
}

class _PharamacyDetailState extends State<PharamacyDetail> with TickerProviderStateMixin {
  bool loading = false;

  TabController? _tabController;

  int? id = 0;
  String? pharamacyImage = "";
  String? pharamacyName = "";
  String? pharamacyPhone = "";
  String? pharamacyEmail = "";
  String? pharamacyDescription = "";
  String? pharamacyStartTime = "";
  String? pharamacyEndTime = "";
  String? pharamacyAddress = "";
  int? isShipping;
  String? pharmacyLat = "";
  String? pharmacyLang = "";

  List<String?> minValue = [];
  List<String?> maxValue = [];
  List<String?> charges = [];

  List<Medicine> medicines = [];
  TextEditingController _search = TextEditingController();
  List<Medicine> _searchResult = [];

  int? pharamacyId;

  void initState() {
    id = widget.id;
    callApiPharamacyDetail();
    _tabController = new TabController(vsync: this, length: 2);
    super.initState();
    _passPharamacyId();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  _passPharamacyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      pharamacyId = id;
      prefs.setInt('pharamacyId', pharamacyId!);
    });
  }

  _passShippingStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt('ShippingStatus', isShipping!);
      prefs.setString('pharmacyLat', pharmacyLat!);
      prefs.setString('pharmacyLang', pharmacyLang!);
      prefs.setStringList('minValue', minValue as List<String>);
      prefs.setStringList('maxValue', maxValue as List<String>);
      prefs.setStringList('charges', charges as List<String>);
    });
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    final parsedLat = double.tryParse(pharmacyLat ?? "");
    final parsedLng = double.tryParse(pharmacyLang ?? "");
    final hasCoords = parsedLat != null && parsedLng != null;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Palette.white,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Palette.dark_blue,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            getTranslated(context, AppString.pharmacy_detail_title).toString(),
            style: TextStyle(
              fontSize: 20,
              color: Palette.dark_blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'AddToCart');
                },
                icon: (Icon(
                  Icons.shopping_cart_outlined,
                  color: Palette.blue,
                )),
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
          child: SingleChildScrollView(
            child: Container(
              child: Column(
                children: [
                  Container(
                    height: 240,
                    width: width * 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Palette.black,
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage('$pharamacyImage'),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Palette.black.withOpacity(0.35),
                                Palette.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Palette.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Palette.black.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$pharamacyName',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Palette.dark_blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                if ((pharamacyPhone ?? "").isNotEmpty)
                                  Row(
                                    children: [
                                      Icon(Icons.phone, size: 18, color: Palette.blue),
                                      SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          pharamacyPhone ?? "",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 14, color: Palette.dark_blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                if ((pharamacyEmail ?? "").isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.email, size: 18, color: Palette.blue),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            pharamacyEmail ?? "",
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 14, color: Palette.dark_blue),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Palette.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.black.withOpacity(0.08),
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TabBar(
                        labelColor: Palette.white,
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Palette.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tabs: [
                          Tab(
                            text: getTranslated(context, AppString.pharamacy_about).toString(),
                          ),
                          Tab(
                            text: getTranslated(context, AppString.pharamacy_product).toString(),
                          )
                        ],
                        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        unselectedLabelColor: Palette.dark_blue,
                      ),
                    ),
                  ),
                  Container(
                    height: height * 0.75,
                    width: width * 1,
                    child: TabBarView(
                      physics: AlwaysScrollableScrollPhysics(),
                      controller: _tabController,
                      children: [
                        SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 12),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Palette.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Palette.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getTranslated(context, AppString.pharamacy_about).toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Palette.dark_blue,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    pharamacyDescription != null
                                        ? Html(
                                            data: '$pharamacyDescription',
                                          )
                                        : Html(
                                            data: getTranslated(context, "noDetail").toString(),
                                          ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Palette.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Palette.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getTranslated(context, AppString.pharamacy_openingHours).toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Palette.dark_blue,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.pharamacy_monday_saturday).toString(),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Palette.grey),
                                        ),
                                        Text(
                                          '$pharamacyStartTime - $pharamacyEndTime',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Palette.grey),
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.pharamacy_sunday).toString(),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Palette.grey),
                                        ),
                                        Text(
                                          getTranslated(context, AppString.pharamacy_close).toString(),
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Palette.grey),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 16),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Palette.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Palette.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      getTranslated(context, AppString.pharamacy_address).toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Palette.dark_blue,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '$pharamacyAddress',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Palette.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasCoords) ...[
                                      SizedBox(height: 12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AbsorbPointer(
                                          child: SizedBox(
                                            height: 160,
                                            child: MapLibreNearbyMap(
                                              latitude: parsedLat ?? 0,
                                              longitude: parsedLng ?? 0,
                                              zoom: 14,
                                              pins: [
                                                NearbyMapPin(id: 'pharmacy', latitude: parsedLat ?? 0,
                                                  longitude: parsedLng ?? 0, title: 'Pharmacy'),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),

                        // tab 2 - Products with search
                        Column(
                          children: [
                            SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                      hintText: getTranslated(context, AppString.pharamacy_searchMedicine).toString(),
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
                            SizedBox(height: 8),
                            Expanded(
                              child: ( _searchResult.isNotEmpty || _search.text.isNotEmpty )
                                  ? (_searchResult.isNotEmpty
                                      ? _buildMedicineGrid(_searchResult)
                                      : Center(
                                          child: Text(
                                            getTranslated(context, AppString.pharamacy_medicineNotAvailable).toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Palette.dark_blue,
                                            ),
                                          ),
                                        ))
                                  : (medicines.isNotEmpty
                                      ? _buildMedicineGrid(medicines)
                                      : Center(
                                          child: Text(
                                            getTranslated(context, AppString.pharamacy_medicineNotAvailable).toString(),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Palette.dark_blue,
                                            ),
                                          ),
                                        )),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<PharmacyDetailsModel>> callApiPharamacyDetail() async {
    PharmacyDetailsModel response;

    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).pharmacyDetailRequest(id);
      setState(() {
        loading = false;
        if (response.success == true) {
          setState(
            () {
              loading = false;
              pharamacyImage = response.data!.fullImage;
              pharamacyName = response.data!.name;
              pharamacyPhone = response.data!.phone;
              pharamacyEmail = response.data!.email;
              pharamacyDescription = response.data!.description;
              pharamacyStartTime = response.data!.startTime;
              pharamacyEndTime = response.data!.endTime;
              pharamacyAddress = response.data!.address;
              medicines.addAll(response.data!.medicine!);
              isShipping = response.data!.isShipping;
              pharmacyLat = response.data!.lat;
              pharmacyLang = response.data!.lang;

              if ('$isShipping' == 1.toString()) {
                var convertCharges = json.decode(response.data!.deliveryCharges!);
                minValue.clear();
                maxValue.clear();
                charges.clear();
                for (int i = 0; i < convertCharges.length; i++) {
                  minValue.add(convertCharges[i]['min_value']);
                  maxValue.add(convertCharges[i]['max_value']);
                  charges.add(convertCharges[i]['charges']);
                  _passShippingStatus();
                }
                _passShippingStatus();
              }
            },
          );
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

  Widget _buildMedicineGrid(List<Medicine> items) {
    return GridView.builder(
      itemCount: items.length,
      physics: BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // Slightly taller to accommodate description lines
        childAspectRatio: 0.80,
      ),
      itemBuilder: (context, index) {
        final medicine = items[index];
        // Strip basic HTML tags/entities so the card shows plain text only.
        final rawDescription = (medicine.description ?? "").trim();
        final String description = rawDescription
            .replaceAll(RegExp(r'<[^>]*>'), ' ')
            .replaceAll(RegExp(r'&nbsp;?', caseSensitive: false), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MedicineDescription(id: medicine.id),
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
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    imageUrl: medicine.fullImage ?? "",
                    placeholder: (context, url) => SpinKitFadingCircle(
                      color: Palette.blue,
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      "assets/images/no_image.jpg",
                      height: 110,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name ?? "",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 14,
                          color: Palette.dark_blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Palette.grey,
                          ),
                        ),
                      ],
                      SizedBox(height: 4),
                      Text(
                        SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + medicine.pricePrStrip.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Palette.dark_blue,
                          fontWeight: FontWeight.w600,
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

  void onSearchTextChanged(String text) {
    _searchResult.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    medicines.forEach((medicine) {
      final name = (medicine.name ?? '').toLowerCase();
      if (name.contains(text.toLowerCase())) {
        _searchResult.add(medicine);
      }
    });

    setState(() {});
  }
}
