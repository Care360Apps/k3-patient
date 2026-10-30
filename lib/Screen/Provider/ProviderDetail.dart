import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Bookappointment.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/const/app_string.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/model/provider_detail_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Chat/loading_view.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/prefConstatnt.dart';
import '../../database/form_helper.dart';
import '../../localization/localization_constant.dart';

class ProviderDetail extends StatefulWidget {
  final int? id;

  ProviderDetail({this.id});

  @override
  _ProviderDetailState createState() => _ProviderDetailState();
}

class _ProviderDetailState extends State<ProviderDetail> {
  bool loading = false;
  ProviderDetailData? provider;
  String? _lat = "";
  String? _lang = "";

  @override
  void initState() {
    super.initState();
    _getAddress();
  }

  _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _lat = prefs.getString('lat');
      _lang = prefs.getString('lang');
    });
    _callApiProviderDetail();
  }

  Future<BaseModel<ProviderDetailResponse>> _callApiProviderDetail() async {
    if (widget.id == null) return BaseModel();
    setState(() => loading = true);
    try {
      final body = <String, dynamic>{"lat": _lat, "lang": _lang};
      final response = await RestClient(RetroApi2().dioData2()).providerDetailRequest(widget.id, body);
      setState(() {
        loading = false;
        provider = response.data;
      });
      return BaseModel()..data = response;
    } catch (error, stacktrace) {
      setState(() => loading = false);
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Palette.dark_white,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: Palette.dark_blue),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        backgroundColor: Palette.white,
        title: Text(
          getTranslated(context, AppString.doctorDetail_title).toString(),
          style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.5,
        progressIndicator: ShimmerIndicator(size: 56),
        child: provider == null
            ? Center(
                child: loading
                    ? null
                    : Text(
                        getTranslated(context, AppString.home_notFound).toString(),
                        style: TextStyle(fontSize: width * 0.04, color: Palette.grey),
                      ),
              )
            : RefreshIndicator(
                onRefresh: _callApiProviderDetail,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(width, height),
                      _buildInfo(width),
                      if ((provider!.desc ?? "").trim().isNotEmpty) _buildAbout(width),
                      if (provider!.reviews != null && provider!.reviews!.isNotEmpty) _buildReviews(width),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
      ),
      bottomNavigationBar: provider != null ? _buildBookButton(width) : null,
    );
  }

  Widget _buildHeader(double width, double height) {
    final imageUrl = provider!.fullImage ?? provider!.image ?? "";
    final name = provider!.name ?? "";
    final typeName = provider!.providerType?.name ?? "";
    final ratingValue = (provider!.rate is num) ? (provider!.rate as num).toDouble() : 0.0;
    final hasRating = provider!.rate != null;
    final reviewCount = provider!.review ?? 0;
    final distanceText = (provider!.distanceKm != null && provider!.distanceKm!.isNotEmpty)
        ? '${provider!.distanceKm} km'
        : null;
    final reviewsLabel = getTranslated(context, AppString.doctorDetail_review) ?? 'Review';

    return Container(
      color: Palette.dark_white,
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Palette.blue.withOpacity(0.08),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: width * 0.28,
              height: width * 0.28,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Palette.blue, width: 3),
              ),
              child: CachedNetworkImage(
                alignment: Alignment.center,
                imageUrl: imageUrl,
                imageBuilder: (context, imageProvider) => ClipOval(
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                placeholder: (context, url) => ShimmerIndicator(size: 32),
                errorWidget: (context, url, error) => ClipOval(
                  child: Image.asset(
                    "assets/images/no_image.jpg",
                    width: width * 0.28,
                    height: width * 0.28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Palette.dark_blue),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            if (typeName.isNotEmpty)
              Text(
                typeName,
                style: TextStyle(fontSize: 14, color: Palette.grey),
              ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasRating)
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        RatingBarIndicator(
                          rating: ratingValue,
                          itemBuilder: (context, index) => Icon(Icons.star, color: Palette.blue),
                          itemCount: 5,
                          itemSize: 18,
                          direction: Axis.horizontal,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '$ratingValue',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                        ),
                        if (reviewCount > 0)
                          Text(
                            ' ($reviewCount $reviewsLabel)',
                            style: TextStyle(fontSize: 12, color: Palette.grey),
                          ),
                      ],
                    ),
                  ),
                if (distanceText != null)
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: Palette.grey),
                      SizedBox(width: 4),
                      Text(
                        distanceText,
                        style: TextStyle(fontSize: 12, color: Palette.grey),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(double width) {
    final currency = SharedPreferenceHelper.getString(Preferences.currency_symbol) ?? '';
    String? feeText;
    if ((provider!.hourlyRate ?? 0) > 0) {
      feeText = '$currency${provider!.hourlyRate}/hr';
    } else if ((provider!.appointmentFees ?? '').isNotEmpty) {
      feeText = '$currency${provider!.appointmentFees}';
    }

    return Container(
      margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Palette.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (feeText != null)
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 20, color: Palette.blue),
                  SizedBox(width: 8),
                  Text(
                    feeText,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                  ),
                ],
              ),
            ),
          if ((provider!.address ?? "").trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: Palette.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider!.address!,
                        style: TextStyle(fontSize: 14, color: Palette.dark_blue),
                      ),
                      SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openInMaps(provider!.address),
                        child: Text(
                          getTranslated(context, AppString.provider_open_in_maps) ?? 'Open in Maps',
                          style: TextStyle(fontSize: 13, color: Palette.blue, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (provider!.experience != null && provider!.experience!.trim().isNotEmpty) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.work_outline, size: 20, color: Palette.blue),
                SizedBox(width: 8),
                Text(
                  '${provider!.experience} ${getTranslated(context, AppString.doctorDetail_doctorExperience) ?? ''}',
                  style: TextStyle(fontSize: 14, color: Palette.dark_blue),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAbout(double width) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Palette.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, AppString.doctorDetail_personalBio) ?? 'Personal Bio',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Palette.dark_blue),
          ),
          SizedBox(height: 8),
          Text(
            provider!.desc!,
            style: TextStyle(fontSize: 14, color: Palette.dark_blue, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(double width) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Palette.black.withOpacity(0.06), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated(context, AppString.doctorDetail_review) ?? 'Review',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Palette.dark_blue),
          ),
          SizedBox(height: 12),
          ...provider!.reviews!.take(5).map((r) => Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Palette.blue.withOpacity(0.2),
                      backgroundImage: r.user?.image != null && r.user!.image!.isNotEmpty
                          ? NetworkImage(r.user!.image!)
                          : null,
                      child: r.user?.image == null || r.user!.image!.isEmpty
                          ? Text(
                              (r.user?.name ?? "?")[0].toUpperCase(),
                              style: TextStyle(color: Palette.blue, fontWeight: FontWeight.w600),
                            )
                          : null,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.user?.name ?? "",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                          ),
                          if (r.rate != null)
                            RatingBarIndicator(
                              rating: r.rate!.toDouble(),
                              itemBuilder: (context, index) => Icon(Icons.star, color: Palette.blue),
                              itemCount: 5,
                              itemSize: 14,
                              direction: Axis.horizontal,
                            ),
                          if (r.review != null && r.review!.isNotEmpty)
                            Text(
                              r.review!,
                              style: TextStyle(fontSize: 13, color: Palette.dark_blue, height: 1.3),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBookButton(double width) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: Palette.white, boxShadow: [
        BoxShadow(color: Palette.black.withOpacity(0.06), blurRadius: 8, offset: Offset(0, -2)),
      ]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointment(id: provider!.id, isProvider: true),
                  ),
                );
              } else {
                FormHelper.showMessage(
                  context,
                  getTranslated(context, AppString.home_medicineOrder_alert_title).toString(),
                  getTranslated(context, AppString.home_medicineOrder_alert_text).toString(),
                  getTranslated(context, AppString.cancel).toString(),
                  () => Navigator.of(context).pop(),
                  buttonText2: getTranslated(context, AppString.login).toString(),
                  isConfirmationDialog: true,
                  onPressed2: () => Navigator.pushNamed(context, 'SignIn'),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Palette.blue,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              getTranslated(context, AppString.provider_book_home_visit) ?? 'Book Home Visit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Palette.white),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openInMaps(String? address) async {
    if (address == null || address.isEmpty) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
