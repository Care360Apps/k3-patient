import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/Payment/PaypalPaymentScreen.dart';
import 'package:doctro_patient/api/base_model.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/server_error.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/model/common_response.dart';
import 'package:doctro_patient/model/detail_setting_model.dart';
import 'package:doctro_patient/model/lab_test_model.dart';
import 'package:doctro_patient/model/labs_model.dart';
import 'package:doctro_patient/model/time_slot_model.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutterwave_standard/core/flutterwave.dart';
import 'package:flutterwave_standard/models/requests/customer.dart';
import 'package:flutterwave_standard/models/requests/customizations.dart';
import 'package:flutterwave_standard/models/responses/charge_response.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../const/Palette.dart';
import '../../database/form_helper.dart';
import '../../localization/localization_constant.dart';

class Laboratory extends StatefulWidget {
  final String title;
  final IconData icon;

  Laboratory({
    Key? key,
    this.title = 'Find Laboratories',
    this.icon = Icons.science_outlined,
  }) : super(key: key);

  @override
  _LaboratoryState createState() => _LaboratoryState();
}

class _LaboratoryState extends State<Laboratory> {
  bool loading = false;
  List<LabData> labs = [];
  List<LabData> filteredLabs = [];
  final TextEditingController _searchController = TextEditingController();
  bool nearMeOnly = false;
  double nearMeRadiusKm = 10;
  String? userLat = "";
  String? userLng = "";
  String? userAddress = "";

  @override
  void initState() {
    super.initState();
    _loadLocation();
    callApiLabs();
  }

  void _loadLocation() {
    userLat = SharedPreferenceHelper.getString('lat');
    userLng = SharedPreferenceHelper.getString('lang');
    userAddress = SharedPreferenceHelper.getString('Address');
  }

  double? _parseCoordinate(String? value) {
    if (value == null || value.isEmpty || value == "N_A") {
      return null;
    }
    return double.tryParse(value);
  }

  double? _distanceKm(LabData lab) {
    final lat1 = _parseCoordinate(userLat);
    final lng1 = _parseCoordinate(userLng);
    final lat2 = _parseCoordinate(lab.lat);
    final lng2 = _parseCoordinate(lab.lng);
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return null;
    }
    const earthRadiusKm = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    List<LabData> results = labs.where((lab) {
      final name = (lab.name ?? "").toLowerCase();
      final address = (lab.address ?? "").toLowerCase();
      final description = (lab.description ?? "").toLowerCase();
      final matchesQuery = query.isEmpty || name.contains(query) || address.contains(query) || description.contains(query);
      if (!matchesQuery) {
        return false;
      }
      if (!nearMeOnly) {
        return true;
      }
      final distance = _distanceKm(lab);
      return distance != null && distance <= nearMeRadiusKm;
    }).toList();

    final userHasLocation = _parseCoordinate(userLat) != null && _parseCoordinate(userLng) != null;
    if (userHasLocation) {
      results.sort((a, b) {
        final distanceA = _distanceKm(a) ?? double.infinity;
        final distanceB = _distanceKm(b) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      filteredLabs = results;
    });
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Palette.blue : Palette.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Palette.blue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Palette.white : Palette.dark_blue,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Palette.white : Palette.dark_blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<BaseModel<LabsModel>> callApiLabs() async {
    LabsModel response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).labsRequest();
      setState(() {
        if (response.success == true) {
          loading = false;
          labs.clear();
          labs.addAll(response.data ?? []);
        }
      });
      _applyFilters();
    } catch (error, stacktrace) {
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final displayLabs = filteredLabs;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.dark_blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? Center(child: SpinKitFadingCircle(color: Palette.blue))
          : Column(
              children: [
                SizedBox(height: 12),
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
                        controller: _searchController,
                        textAlign: TextAlign.left,
                        textCapitalization: TextCapitalization.words,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (value) {
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: "Search laboratories",
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
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userAddress == null || userAddress == "N_A" || userAddress!.isEmpty ? "Current location" : userAddress!,
                        style: TextStyle(fontSize: 12, color: Palette.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.black.withOpacity(0.08),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildFilterPill(
                              label: "All",
                              selected: !nearMeOnly,
                              icon: Icons.public,
                              onTap: () {
                                setState(() {
                                  nearMeOnly = false;
                                });
                                _applyFilters();
                              },
                            ),
                            SizedBox(width: 6),
                            _buildFilterPill(
                              label: "Near Me",
                              selected: nearMeOnly,
                              icon: Icons.near_me,
                              onTap: () {
                                setState(() {
                                  nearMeOnly = true;
                                });
                                _applyFilters();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: displayLabs.isEmpty
                      ? Center(
                          child: Text(
                            'No Data Found',
                            style: TextStyle(fontSize: width * 0.04, color: Palette.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.92,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: displayLabs.length,
                          itemBuilder: (context, index) {
                            final lab = displayLabs[index];
                            final address = (lab.address ?? "").trim();
                            final description = (lab.description ?? "").trim();
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LabDetailScreen(lab: lab),
                                  ),
                                );
                              },
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
                                        imageUrl: lab.fullImage ?? "",
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                        errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lab.name ?? "",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Palette.dark_blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (address.isNotEmpty) ...[
                                            SizedBox(height: 2),
                                            Text(
                                              address,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Palette.grey,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          SizedBox(height: 2),
                                          Text(
                                            description.isNotEmpty ? description : "No description available",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Palette.grey,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class LabDetailScreen extends StatefulWidget {
  final LabData lab;

  LabDetailScreen({required this.lab});

  @override
  _LabDetailScreenState createState() => _LabDetailScreenState();
}

class _LabDetailScreenState extends State<LabDetailScreen> {
  bool loading = false;
  bool detailLoading = false;
  bool timeslotLoading = false;
  List<LabTestItem> pathology = [];
  List<LabTestItem> radiology = [];
  Set<int> selectedPathology = {};
  Set<int> selectedRadiology = {};
  LabData? labDetail;
  List<DataSlots> timeSlots = [];
  String? detailDateApi;
  String? detailDateDisplay;
  final PageController _galleryController = PageController();
  int _galleryIndex = 0;
  bool canViewTimeslots = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    detailDateApi = DateFormat('yyyy-MM-dd').format(now);
    detailDateDisplay = DateFormat('dd MMM, yyyy').format(now);
    loadTests();
    callApiLabDetail();
    _resolveTimeslotAccess().then((_) {
      if (!mounted) return;
      if (canViewTimeslots) {
        callApiLabTimeslot();
      }
    });
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  loadTests() async {
    setState(() {
      loading = true;
    });
    await Future.wait([
      callApiLabPathology(),
      callApiLabRadiology(),
    ]);
    setState(() {
      loading = false;
    });
  }

  Future<BaseModel<LabTestResponse>> callApiLabPathology() async {
    LabTestResponse response;
    try {
      response = await RestClient(RetroApi2().dioData2()).labPathologyRequest(widget.lab.id);
      if (response.success == true) {
        setState(() {
          pathology.addAll(response.data ?? []);
        });
      }
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<LabTestResponse>> callApiLabRadiology() async {
    LabTestResponse response;
    try {
      response = await RestClient(RetroApi2().dioData2()).labRadiologyRequest(widget.lab.id);
      if (response.success == true) {
        setState(() {
          radiology.addAll(response.data ?? []);
        });
      }
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<LabDetailModel>> callApiLabDetail() async {
    LabDetailModel response;
    setState(() {
      detailLoading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).labDetailRequest(widget.lab.id);
      if (response.success == true) {
        setState(() {
          labDetail = response.data;
          detailLoading = false;
        });
      } else {
        setState(() {
          detailLoading = false;
        });
      }
    } catch (error, stacktrace) {
      setState(() {
        detailLoading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<BaseModel<Timeslot>> callApiLabTimeslot() async {
    Timeslot response;
    if (!canViewTimeslots) {
      setState(() {
        timeslotLoading = false;
      });
      return BaseModel();
    }
    Map<String, dynamic> body = {
      "lab_id": widget.lab.id,
      "date": detailDateApi,
    };
    setState(() {
      timeslotLoading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).labTimeslot(body);
      if (response.success == true) {
        setState(() {
          timeSlots.clear();
          timeSlots.addAll(response.data ?? []);
          timeslotLoading = false;
        });
      } else {
        setState(() {
          timeslotLoading = false;
        });
      }
    } catch (error, stacktrace) {
      setState(() {
        timeslotLoading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> _pickDetailDate() async {
    if (!canViewTimeslots) {
      Fluttertoast.showToast(
        msg: getTranslated(context, AppString.home_pleaseLogin_toast).toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }
    DateTime initial = DateTime.now();
    DateTime first = DateTime.now();
    DateTime last = DateTime.now().add(Duration(days: 60));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        detailDateApi = DateFormat('yyyy-MM-dd').format(picked);
        detailDateDisplay = DateFormat('dd MMM, yyyy').format(picked);
      });
      callApiLabTimeslot();
    }
  }

  double _getCharge(LabTestItem item) {
    return double.tryParse(item.charge ?? "0") ?? 0;
  }

  double get totalAmount {
    double total = 0;
    for (final item in pathology) {
      if (item.id != null && selectedPathology.contains(item.id)) {
        total += _getCharge(item);
      }
    }
    for (final item in radiology) {
      if (item.id != null && selectedRadiology.contains(item.id)) {
        total += _getCharge(item);
      }
    }
    return total;
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Palette.black.withOpacity(0.08),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              color: Palette.dark_blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Palette.grey),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Palette.grey),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final currency = SharedPreferenceHelper.getString(Preferences.currency_symbol);
    final lab = labDetail ?? widget.lab;
    final gallery = lab.labGallery ?? [];
    final description = (lab.description ?? "").trim();
    final phone = (lab.phone ?? "").trim();
    final email = (lab.email ?? "").trim();
    final startTime = (lab.startTime ?? "").trim();
    final endTime = (lab.endTime ?? "").trim();
    return Scaffold(
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
          'Laboratory Details',
          style: TextStyle(
            fontSize: 20,
            color: Palette.dark_blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading && pathology.isEmpty && radiology.isEmpty && timeSlots.isEmpty
          ? Center(child: SpinKitFadingCircle(color: Palette.blue))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: width,
                    height: 240,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: gallery.isNotEmpty
                              ? PageView.builder(
                                  controller: _galleryController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _galleryIndex = index;
                                    });
                                  },
                                  itemCount: gallery.length,
                                  itemBuilder: (context, index) {
                                    return CachedNetworkImage(
                                      alignment: Alignment.center,
                                      imageUrl: gallery[index].fullImage ?? "",
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                      errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                                    );
                                  },
                                )
                              : CachedNetworkImage(
                                  alignment: Alignment.center,
                                  imageUrl: lab.fullImage ?? "",
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                  errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                                ),
                        ),
                        if (gallery.length > 1)
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(gallery.length, (index) {
                                final selected = index == _galleryIndex;
                                return AnimatedContainer(
                                  duration: Duration(milliseconds: 200),
                                  margin: EdgeInsets.symmetric(horizontal: 3),
                                  height: 6,
                                  width: selected ? 20 : 6,
                                  decoration: BoxDecoration(
                                    color: selected ? Palette.white : Palette.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _sectionCard(
                    title: lab.name ?? "",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((lab.address ?? "").isNotEmpty) _infoRow(icon: Icons.location_on, text: lab.address ?? ""),
                        if (phone.isNotEmpty) ...[
                          SizedBox(height: 6),
                          _infoRow(icon: Icons.phone, text: phone),
                        ],
                        if (email.isNotEmpty) ...[
                          SizedBox(height: 6),
                          _infoRow(icon: Icons.email, text: email),
                        ],
                        if (startTime.isNotEmpty || endTime.isNotEmpty) ...[
                          SizedBox(height: 6),
                          _infoRow(
                            icon: Icons.schedule,
                            text: "${startTime.isNotEmpty ? startTime : "--"} - ${endTime.isNotEmpty ? endTime : "--"}",
                          ),
                        ],
                      ],
                    ),
                  ),
                  _sectionCard(
                    title: "About Laboratory",
                    child: Text(
                      description.isNotEmpty ? description : "No description available",
                      style: TextStyle(fontSize: 13, color: Palette.grey),
                    ),
                  ),
                  _sectionCard(
                    title: "Available Time Slots",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              detailDateDisplay ?? "",
                              style: TextStyle(fontSize: 13, color: Palette.grey),
                            ),
                            TextButton(
                              onPressed: _pickDetailDate,
                              child: Text("Change Date"),
                            ),
                          ],
                        ),
                        timeslotLoading
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: SpinKitFadingCircle(color: Palette.blue, size: 30),
                              )
                            : !canViewTimeslots
                                ? Text(
                                    getTranslated(context, AppString.home_pleaseLogin_toast).toString(),
                                    style: TextStyle(color: Palette.grey),
                                  )
                                : timeSlots.isEmpty
                                ? Text("No Timeslot Found", style: TextStyle(color: Palette.grey))
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: List.generate(timeSlots.length, (index) {
                                      final slot = timeSlots[index];
                                      final label = "${slot.startTime} - ${slot.endTime}";
                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Palette.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          label,
                                          style: TextStyle(color: Palette.blue, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    }),
                                  ),
                      ],
                    ),
                  ),
                  if (pathology.isNotEmpty)
                    _sectionCard(
                      title: "Pathology Tests",
                      child: Column(
                        children: pathology.map((item) {
                          final id = item.id ?? 0;
                          final charge = _getCharge(item);
                          return CheckboxListTile(
                            value: selectedPathology.contains(id),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedPathology.add(id);
                                } else {
                                  selectedPathology.remove(id);
                                }
                              });
                            },
                            title: Text(item.name ?? ""),
                            subtitle: Text('$currency$charge'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                  if (radiology.isNotEmpty)
                    _sectionCard(
                      title: "Radiology Tests",
                      child: Column(
                        children: radiology.map((item) {
                          final id = item.id ?? 0;
                          final charge = _getCharge(item);
                          return CheckboxListTile(
                            value: selectedRadiology.contains(id),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedRadiology.add(id);
                                } else {
                                  selectedRadiology.remove(id);
                                }
                              });
                            },
                            title: Text(item.name ?? ""),
                            subtitle: Text('$currency$charge'),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$currency${totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LabBookingScreen(
                    labId: widget.lab.id ?? 0,
                    labName: widget.lab.name ?? "",
                    amount: totalAmount,
                    pathologyIds: selectedPathology.toList(),
                    radiologyIds: selectedRadiology.toList(),
                  ),
                ),
              );
            } else {
              FormHelper.showMessage(
                context,
                getTranslated(context, AppString.doctorDetail_appointmentBook_alert_title).toString(),
                getTranslated(context, AppString.doctorDetail_appointmentBook_alert_text).toString(),
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
            }
          },
          child: Text(
            'Book Now',
            style: TextStyle(fontSize: 16, color: Palette.white),
          ),
        ),
      ),
    );
  }

  Future<void> _resolveTimeslotAccess() async {
    final token = await SharedPreferenceHelper.getSecureString(Preferences.auth_token);
    final isLoggedIn = SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true;
    final hasToken = token != null && token.isNotEmpty && token != "N_A" && token != "null";
    if (mounted) {
      setState(() {
        canViewTimeslots = isLoggedIn && hasToken;
      });
    } else {
      canViewTimeslots = isLoggedIn && hasToken;
    }
  }
}

enum LabPayment { Paypal, Razorpay, Stripe, FlutterWave, PayStack, COD }

class LabBookingScreen extends StatefulWidget {
  final int labId;
  final String labName;
  final double amount;
  final List<int> pathologyIds;
  final List<int> radiologyIds;

  LabBookingScreen({
    required this.labId,
    required this.labName,
    required this.amount,
    required this.pathologyIds,
    required this.radiologyIds,
  });

  @override
  _LabBookingScreenState createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  bool loading = false;
  String? selectedDateApi;
  String? selectedDateDisplay;
  List<DataSlots> timeList = [];
  String? selectTime = "";
  int? timeIndex;

  LabPayment? _payment;
  String? _paymentToken = "";
  String? paymentType = "COD";

  late Razorpay _razorpay;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String genderValue = "Male";

  String? businessName = "";
  String? logo = "";
  int? cod = 0;
  int? stripe = 0;
  int? paypal = 0;
  int? razor = 0;
  int? flutterWave = 0;
  int? payStack = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    final now = DateTime.now();
    selectedDateApi = DateFormat('yyyy-MM-dd').format(now);
    selectedDateDisplay = DateFormat('dd MMM, yyyy').format(now);
    _detailSetting();
    callApiLabTimeslot();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<BaseModel<Timeslot>> callApiLabTimeslot() async {
    Timeslot response;
    Map<String, dynamic> body = {
      "lab_id": widget.labId,
      "date": selectedDateApi,
    };
    setState(() {
      loading = true;
    });
    try {
      setState(() {
        timeList.clear();
      });
      response = await RestClient(RetroApi().dioData()).labTimeslot(body);
      if (response.success == true) {
        setState(() {
          loading = false;
          timeList.addAll(response.data!);
        });
      } else {
        setState(() {
          loading = false;
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

  Future<BaseModel<CommonResponse>> callApiLabBook() async {
    CommonResponse response;
    Map<String, dynamic> body = {
      "lab_id": widget.labId,
      "patient_name": patientNameController.text,
      "age": ageController.text,
      "phone_no": phoneController.text,
      "gender": genderValue,
      "date": selectedDateApi,
      "time": selectTime,
      "payment_type": paymentType,
      "payment_status": _payment == LabPayment.COD ? 0 : 1,
      "payment_token": _payment == LabPayment.COD ? "" : _paymentToken,
      "amount": widget.amount.toStringAsFixed(2),
      "pathology_id": widget.pathologyIds,
      "radiology_id": widget.radiologyIds,
    };
    setState(() {
      Preferences.onLoading(context);
    });
    try {
      response = await RestClient(RetroApi().dioData()).labBook(body);
      if (response.success == true) {
        Preferences.hideDialog(context);
        Fluttertoast.showToast(
          msg: '${response.msg}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
        );
        Navigator.pop(context);
      } else {
        Preferences.hideDialog(context);
      }
    } catch (error, stacktrace) {
      Preferences.hideDialog(context);
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> _pickDate() async {
    DateTime initial = DateTime.now();
    DateTime first = DateTime.now();
    DateTime last = DateTime.now().add(Duration(days: 60));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        selectedDateApi = DateFormat('yyyy-MM-dd').format(picked);
        selectedDateDisplay = DateFormat('dd MMM, yyyy').format(picked);
        selectTime = "";
        timeIndex = null;
      });
      callApiLabTimeslot();
    }
  }

  void openCheckoutRazorPay() async {
    var map = {
      'key': SharedPreferenceHelper.getString(Preferences.razor_key),
      'amount': widget.amount * 100,
      'name': businessName,
      'currency': SharedPreferenceHelper.getString(Preferences.currency_code),
      'image': logo,
      'description': '',
      'prefill': {
        'contact': SharedPreferenceHelper.getString(Preferences.phone),
        'email': SharedPreferenceHelper.getString(FirestoreConstants.email)
      },
    };
    try {
      _razorpay.open(map);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentToken = response.paymentId;
    _paymentToken != "" && _paymentToken!.isNotEmpty
        ? callApiLabBook()
        : Fluttertoast.showToast(msg: "Payment not completed", toastLength: Toast.LENGTH_SHORT);
  }

  void _handlePaymentError(PaymentFailureResponse response) {}

  void _handleExternalWallet(ExternalWalletResponse response) {}

  final Customer customer = Customer(
    name: SharedPreferenceHelper.getString(Preferences.name)!,
    phoneNumber: SharedPreferenceHelper.getString(Preferences.phone)!,
    email: SharedPreferenceHelper.getString(FirestoreConstants.email)!,
  );

  flutterWavePayment(context, payAmount) async {
    final flutterwave = Flutterwave(
      publicKey: SharedPreferenceHelper.getString(Preferences.flutterWave_key)!,
      currency: SharedPreferenceHelper.getString(Preferences.currency_code)!,
      txRef: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: payAmount.toString(),
      customer: customer,
      paymentOptions: "card",
      customization: Customization(title: widget.labName),
      redirectUrl: "https://www.google.com",
      isTestMode: true,
    );
    final ChargeResponse response = await flutterwave.charge(context);
    if (response.transactionId!.isNotEmpty) {
      setState(() {
        _paymentToken = response.transactionId;
        callApiLabBook();
      });
    }
  }

  String _paymentLabel(LabPayment method) {
    switch (method) {
      case LabPayment.Paypal:
        return "Paypal";
      case LabPayment.Razorpay:
        return "Razorpay";
      case LabPayment.Stripe:
        return "Stripe";
      case LabPayment.FlutterWave:
        return "FlutterWave";
      case LabPayment.PayStack:
        return "PayStack";
      case LabPayment.COD:
        return "COD";
    }
  }

  Future<BaseModel<DetailSetting>> _detailSetting() async {
    DetailSetting response;
    try {
      response = await RestClient(RetroApi().dioData()).settingRequest();
      if (response.success == true) {
        setState(() {
          businessName = response.data!.businessName;
          logo = response.data!.logo;
          cod = response.data!.cod;
          stripe = response.data!.stripe;
          paypal = response.data!.paypal;
          flutterWave = response.data!.flutterwave;
          razor = response.data!.razor;
          payStack = response.data!.payStack;
        });
      }
    } catch (error, stacktrace) {
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  Future<void> _handlePayment() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (selectTime == null || selectTime!.isEmpty) {
      Fluttertoast.showToast(msg: "Select time", toastLength: Toast.LENGTH_SHORT);
      return;
    }
    if (_payment == null) {
      Fluttertoast.showToast(msg: "Select payment method", toastLength: Toast.LENGTH_SHORT);
      return;
    }
    paymentType = _paymentLabel(_payment!);
    if (_payment == LabPayment.Paypal) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => PaypalPayment(
            total: widget.amount.toStringAsFixed(2),
            onFinish: (number) async {
              if (number != null && number.toString() != '') {
                setState(() {
                  _paymentToken = number;
                  callApiLabBook();
                });
              }
            },
          ),
        ),
      );
    } else if (_payment == LabPayment.Razorpay) {
      openCheckoutRazorPay();
    } else if (_payment == LabPayment.Stripe) {
      final token = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LabStripeTokenScreen()),
      );
      if (token != null && token.toString().isNotEmpty) {
        setState(() {
          _paymentToken = token;
          callApiLabBook();
        });
      }
    } else if (_payment == LabPayment.FlutterWave) {
      flutterWavePayment(context, widget.amount);
    } else if (_payment == LabPayment.PayStack) {
      Fluttertoast.showToast(msg: getTranslated(context, AppString.payStackLabel).toString() + " is not available");
    } else if (_payment == LabPayment.COD) {
      callApiLabBook();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final currency = SharedPreferenceHelper.getString(Preferences.currency_symbol);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.dark_blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Book Lab",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? Center(child: SpinKitFadingCircle(color: Palette.blue))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.labName,
                      style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: patientNameController,
                      decoration: InputDecoration(labelText: "Patient Name"),
                      validator: (value) => value == null || value.isEmpty ? "Enter patient name" : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Age"),
                      validator: (value) => value == null || value.isEmpty ? "Enter age" : null,
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: "Phone Number"),
                      validator: (value) => value == null || value.isEmpty ? "Enter phone number" : null,
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: genderValue,
                      items: ["Male", "Female", "Other"]
                          .map((value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          genderValue = value ?? "Male";
                        });
                      },
                      decoration: InputDecoration(labelText: "Gender"),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Appointment Date",
                          style: TextStyle(fontSize: 14, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: _pickDate,
                          child: Text(selectedDateDisplay ?? ""),
                        )
                      ],
                    ),
                    SizedBox(height: 6),
                    timeList.isEmpty
                        ? Text("No Timeslot Found", style: TextStyle(color: Palette.grey))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(timeList.length, (index) {
                              final slot = timeList[index];
                              final selected = timeIndex == index;
                              final label = "${slot.startTime} - ${slot.endTime}";
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    timeIndex = index;
                                    selectTime = slot.startTime;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selected ? Palette.blue : Palette.white,
                                    border: Border.all(color: Palette.blue),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(color: selected ? Palette.white : Palette.blue, fontSize: 12),
                                  ),
                                ),
                              );
                            }),
                          ),
                    SizedBox(height: 16),
                    Text(
                      "Payment",
                      style: TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                    ),
                    if (paypal == 1)
                      RadioListTile<LabPayment>(
                        value: LabPayment.Paypal,
                        groupValue: _payment,
                        onChanged: (value) {
                          setState(() {
                            _payment = value;
                          });
                        },
                        title: Text("Paypal"),
                      ),
                    if (razor == 1)
                      RadioListTile<LabPayment>(
                        value: LabPayment.Razorpay,
                        groupValue: _payment,
                        onChanged: (value) {
                          setState(() {
                            _payment = value;
                          });
                        },
                        title: Text("Razorpay"),
                      ),
                    if (stripe == 1)
                      RadioListTile<LabPayment>(
                        value: LabPayment.Stripe,
                        groupValue: _payment,
                        onChanged: (value) {
                          setState(() {
                            _payment = value;
                          });
                        },
                        title: Text("Stripe"),
                      ),
                    if (flutterWave == 1)
                      RadioListTile<LabPayment>(
                        value: LabPayment.FlutterWave,
                        groupValue: _payment,
                        onChanged: (value) {
                          setState(() {
                            _payment = value;
                          });
                        },
                        title: Text("FlutterWave"),
                      ),
                    if (payStack == 1)
                      RadioListTile<LabPayment>(
                        value: LabPayment.PayStack,
                        groupValue: _payment,
                        onChanged: (value) {
                          setState(() {
                            _payment = value;
                          });
                        },
                        title: Text("PayStack"),
                      ),
                    if (cod == 1)
                      RadioListTile<LabPayment>(
                        value: LabPayment.COD,
                        groupValue: _payment,
                        onChanged: (value) {
                          setState(() {
                            _payment = value;
                          });
                        },
                        title: Text(getTranslated(context, AppString.codLabel).toString()),
                      ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$currency${widget.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        height: 50,
        child: ElevatedButton(
          onPressed: _handlePayment,
          child: Text(
            "Pay $currency${widget.amount.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 16, color: Palette.white),
          ),
        ),
      ),
    );
  }
}

class LabStripeTokenScreen extends StatefulWidget {
  @override
  _LabStripeTokenScreenState createState() => _LabStripeTokenScreenState();
}

class _LabStripeTokenScreenState extends State<LabStripeTokenScreen> {
  CardFieldInputDetails? _card;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    setKey();
  }

  Future setKey() async {
    Stripe.publishableKey = SharedPreferenceHelper.getString(Preferences.stripe_public_key)!;
    Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    Stripe.urlScheme = 'flutter stripe';
    await Stripe.instance.applySettings();
  }

  Future<void> _handleCreateTokenPress() async {
    if (_card == null) {
      return;
    }
    setState(() {
      loading = true;
    });
    try {
      final tokenData = await Stripe.instance.createToken(CreateTokenParams.card(params: CardTokenParams(type: TokenType.Card)));
      setState(() {
        loading = false;
      });
      Navigator.pop(context, tokenData.id);
    } catch (e) {
      setState(() {
        loading = false;
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.dark_blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Stripe",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: CardField(
                  autofocus: true,
                  onCardChanged: (card) {
                    setState(() {
                      _card = card;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(15),
                child: ElevatedButton(
                  onPressed: _card?.complete == true && loading == false ? _handleCreateTokenPress : null,
                  child: loading ? ShimmerIndicator(size: 20) : Text("Continue"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HospitalScreen extends StatefulWidget {
  final String title;
  final IconData icon;

  HospitalScreen({
    Key? key,
    this.title = 'Find Hospitals',
    this.icon = Icons.local_hospital_outlined,
  }) : super(key: key);

  @override
  _HospitalScreenState createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  bool loading = false;
  List<HospitalData> hospitals = [];
  List<HospitalData> filteredHospitals = [];
  final TextEditingController _searchController = TextEditingController();
  bool nearMeOnly = false;
  double nearMeRadiusKm = 10;
  String? userLat = "";
  String? userLng = "";
  String? userAddress = "";

  @override
  void initState() {
    super.initState();
    _loadLocation();
    callApiHospitals();
  }

  void _loadLocation() {
    userLat = SharedPreferenceHelper.getString('lat');
    userLng = SharedPreferenceHelper.getString('lang');
    userAddress = SharedPreferenceHelper.getString('Address');
  }

  double? _parseCoordinate(String? value) {
    if (value == null || value.isEmpty || value == "N_A") {
      return null;
    }
    return double.tryParse(value);
  }

  double? _distanceKm(HospitalData hospital) {
    final lat1 = _parseCoordinate(userLat);
    final lng1 = _parseCoordinate(userLng);
    final lat2 = _parseCoordinate(hospital.lat);
    final lng2 = _parseCoordinate(hospital.lng);
    if (lat1 == null || lng1 == null || lat2 == null || lng2 == null) {
      return null;
    }
    const earthRadiusKm = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    List<HospitalData> results = hospitals.where((hospital) {
      final name = (hospital.name ?? "").toLowerCase();
      final address = (hospital.address ?? "").toLowerCase();
      final facility = (hospital.facility ?? "").toLowerCase();
      final matchesQuery = query.isEmpty || name.contains(query) || address.contains(query) || facility.contains(query);
      if (!matchesQuery) {
        return false;
      }
      if (!nearMeOnly) {
        return true;
      }
      final distance = _distanceKm(hospital);
      return distance != null && distance <= nearMeRadiusKm;
    }).toList();

    final userHasLocation = _parseCoordinate(userLat) != null && _parseCoordinate(userLng) != null;
    if (userHasLocation) {
      results.sort((a, b) {
        final distanceA = _distanceKm(a) ?? double.infinity;
        final distanceB = _distanceKm(b) ?? double.infinity;
        return distanceA.compareTo(distanceB);
      });
    }

    setState(() {
      filteredHospitals = results;
    });
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Palette.blue : Palette.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Palette.blue.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Palette.white : Palette.dark_blue,
              ),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Palette.white : Palette.dark_blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<BaseModel<HospitalsModel>> callApiHospitals() async {
    HospitalsModel response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).hospitalsRequest();
      setState(() {
        if (response.success == true) {
          loading = false;
          hospitals.clear();
          hospitals.addAll(response.data ?? []);
        }
      });
      _applyFilters();
    } catch (error, stacktrace) {
      setState(() {
        loading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final displayHospitals = filteredHospitals;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.dark_blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: loading
          ? Center(child: SpinKitFadingCircle(color: Palette.blue))
          : Column(
              children: [
                SizedBox(height: 12),
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
                        controller: _searchController,
                        textAlign: TextAlign.left,
                        textCapitalization: TextCapitalization.words,
                        textAlignVertical: TextAlignVertical.center,
                        onChanged: (value) {
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: "Search hospitals",
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
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userAddress == null || userAddress == "N_A" || userAddress!.isEmpty ? "Current location" : userAddress!,
                        style: TextStyle(fontSize: 12, color: Palette.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.black.withOpacity(0.08),
                              blurRadius: 6,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildFilterPill(
                              label: "All",
                              selected: !nearMeOnly,
                              icon: Icons.public,
                              onTap: () {
                                setState(() {
                                  nearMeOnly = false;
                                });
                                _applyFilters();
                              },
                            ),
                            SizedBox(width: 6),
                            _buildFilterPill(
                              label: "Near Me",
                              selected: nearMeOnly,
                              icon: Icons.near_me,
                              onTap: () {
                                setState(() {
                                  nearMeOnly = true;
                                });
                                _applyFilters();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: displayHospitals.isEmpty
                      ? Center(
                          child: Text(
                            'No Data Found',
                            style: TextStyle(fontSize: width * 0.04, color: Palette.grey),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: displayHospitals.length,
                          itemBuilder: (context, index) {
                            final hospital = displayHospitals[index];
                            final address = (hospital.address ?? "").trim();
                            final facility = (hospital.facility ?? "").trim();
                            final imageUrl = hospital.hospitalGallery != null && hospital.hospitalGallery!.isNotEmpty
                                ? hospital.hospitalGallery!.first.fullImage ?? ""
                                : "";
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HospitalDetailScreen(hospital: hospital),
                                  ),
                                );
                              },
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
                                        imageUrl: imageUrl,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                        errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hospital.name ?? "",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Palette.dark_blue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (address.isNotEmpty) ...[
                                            SizedBox(height: 4),
                                            Text(
                                              address,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Palette.grey,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          SizedBox(height: 4),
                                          Text(
                                            facility.isNotEmpty ? facility : "No facilities listed",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Palette.grey,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class HospitalDetailScreen extends StatefulWidget {
  final HospitalData hospital;

  HospitalDetailScreen({required this.hospital});

  @override
  _HospitalDetailScreenState createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  bool detailLoading = false;
  HospitalData? hospitalDetail;
  final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    callApiHospitalDetail();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<BaseModel<HospitalDetailModel>> callApiHospitalDetail() async {
    HospitalDetailModel response;
    setState(() {
      detailLoading = true;
    });
    try {
      response = await RestClient(RetroApi2().dioData2()).hospitalDetailRequest(widget.hospital.id);
      if (response.success == true) {
        setState(() {
          hospitalDetail = response.data;
          detailLoading = false;
        });
      } else {
        setState(() {
          detailLoading = false;
        });
      }
    } catch (error, stacktrace) {
      setState(() {
        detailLoading = false;
      });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  double? _parseCoordinate(String? value) {
    if (value == null || value.isEmpty || value == "N_A") {
      return null;
    }
    return double.tryParse(value);
  }

  List<String> _facilityItems(String? facility) {
    if (facility == null || facility.trim().isEmpty) {
      return [];
    }
    return facility.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Palette.blue),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: Palette.grey),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Palette.black.withOpacity(0.08),
            blurRadius: 8,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Palette.dark_blue),
          ),
          SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = hospitalDetail ?? widget.hospital;
    final gallery = data.hospitalGallery ?? [];
    final lat = _parseCoordinate(data.lat);
    final lng = _parseCoordinate(data.lng);
    final facilities = _facilityItems(data.facility);
    return Scaffold(
      backgroundColor: Palette.dark_white,
      appBar: AppBar(
        backgroundColor: Palette.dark_blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          data.name ?? "Hospital",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: detailLoading && hospitalDetail == null
          ? Center(child: SpinKitFadingCircle(color: Palette.blue))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(16, 16, 16, 6),
                    decoration: BoxDecoration(
                      color: Palette.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        height: 220,
                        child: Stack(
                          children: [
                            if (gallery.isNotEmpty)
                              PageView.builder(
                                controller: _galleryController,
                                itemCount: gallery.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _galleryIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final imageUrl = gallery[index].fullImage ?? "";
                                  return CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                                    errorWidget: (context, url, error) => Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover),
                                  );
                                },
                              )
                            else
                              Image.asset("assets/images/no_image.jpg", fit: BoxFit.cover, width: double.infinity),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Palette.black.withOpacity(0.65),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.name ?? "Hospital",
                                    style: TextStyle(
                                      color: Palette.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if ((data.address ?? "").isNotEmpty) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      data.address ?? "",
                                      style: TextStyle(color: Palette.white.withOpacity(0.9), fontSize: 12),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (gallery.length > 1)
                              Positioned(
                                bottom: 10,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(gallery.length, (index) {
                                    final isActive = index == _galleryIndex;
                                    return AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      margin: EdgeInsets.symmetric(horizontal: 4),
                                      height: 6,
                                      width: isActive ? 18 : 6,
                                      decoration: BoxDecoration(
                                        color: isActive ? Palette.blue : Palette.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _sectionCard(
                    title: "Contact",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((data.address ?? "").isNotEmpty) _infoRow(icon: Icons.location_on_outlined, text: data.address ?? ""),
                        if ((data.phone ?? "").isNotEmpty) ...[
                          SizedBox(height: 10),
                          _infoRow(icon: Icons.call_outlined, text: data.phone ?? ""),
                        ],
                        if ((data.address ?? "").isEmpty && (data.phone ?? "").isEmpty)
                          Text(
                            "Contact information not available",
                            style: TextStyle(fontSize: 13, color: Palette.grey),
                          ),
                      ],
                    ),
                  ),
                  _sectionCard(
                    title: "Facilities",
                    child: facilities.isEmpty
                        ? Text(
                            "No facilities listed",
                            style: TextStyle(fontSize: 13, color: Palette.grey),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: facilities
                                .map(
                                  (item) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Palette.dark_white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Palette.blue.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      item,
                                      style: TextStyle(fontSize: 12, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  _sectionCard(
                    title: "Location",
                    child: SizedBox(
                      height: 220,
                      child: lat == null || lng == null
                          ? Center(
                              child: Text(
                                "Location not available",
                                style: TextStyle(color: Palette.grey),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(lat, lng),
                                  zoom: 13,
                                ),
                                markers: {
                                  Marker(
                                    markerId: MarkerId("hospital_${data.id ?? 0}"),
                                    position: LatLng(lat, lng),
                                  )
                                },
                                myLocationEnabled: false,
                                zoomControlsEnabled: false,
                                mapToolbarEnabled: false,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
