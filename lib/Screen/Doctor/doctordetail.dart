import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Bookappointment.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../Chat/loading_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Chat/chat.dart';
import '../../model/doctor_detail_model.dart';
import '../../VideoCall/videocall.dart';
import '../../VideoCall/overlay_handler.dart';
import '../../VideoCall/overlay_service.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../database/form_helper.dart';
import '../../localization/localization_constant.dart';

class DoctorDetail extends StatefulWidget {
  final int? id;

  DoctorDetail({this.id});

  @override
  _DoctorDetailState createState() => _DoctorDetailState();
}

class _DoctorDetailState extends State<DoctorDetail> with TickerProviderStateMixin {
  bool loading = false;
  TabController? _tabController;
  int? id = 0;
  int? doctorId = 0;
  String? name = "";
  String? expertise = "";
  String? appointmentFees = "";
  String? experience = "";
  dynamic rate = 0.0;
  String? desc = "";
  String education = "";
  String certificate = "";
  String? fullImage = "";
  String? treatmentName = "";
  bool videoCall = false;

  String? mobileNo = "";

  List<String?> degree = [];
  List<String?> collage = [];
  List<String?> degreeYear = [];
  List<String?> award = [];
  List<String?> awardYear = [];
  List<HospitalId> hospitalDetail = [];
  HospitalId? hospitalDetailData;
  int hospitalIndex = 0;
  List<Reviews> reviews = [];
  List<HospitalGallery> hospitalGallery = [];
  String? token = "";
  String? channelName = "";
  String? _lat = "";
  String? _lang = "";

  void initState() {
    print("InitState");
    id = widget.id;
    hospitalIndex = 0;
    _getAddress();
    _tabController = TabController(vsync: this, length: 3, initialIndex: 0);

    super.initState();
  }

  @override
  void dispose() {
    _tabController!.dispose();
    super.dispose();
  }

  _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lat = prefs.getString('lat');
      _lang = prefs.getString('lang');
    });
    callApiDoctorDetail();
  }

  _addVideoOverlay(BuildContext context) {
    OverlayService().addVideosOverlay(
      context,
      VideoCall(
        doctorId: widget.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return WillPopScope(
      onWillPop: () async {
        if (Provider.of<OverlayHandlerProvider>(context, listen: false).overlayActive) {
          Provider.of<OverlayHandlerProvider>(context, listen: false).enablePip(1.8);
          return false;
        }
        return true;
      },
      child: DefaultTabController(
        // Added
        length: 3, // Added
        initialIndex: 0,
        child: Scaffold(
          backgroundColor: Palette.dark_white,
          appBar: AppBar(
            elevation: 0,
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActionButton(
                              child: SvgPicture.asset(
                                'assets/icons/call.svg',
                                width: 20,
                                height: 20,
                              ),
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext bc) {
                                    return SafeArea(
                                      child: Container(
                                        child: new Wrap(
                                          children: <Widget>[
                                            new ListTile(
                                              leading: new Icon(Icons.phone_in_talk),
                                              title: new Text(
                                                getTranslated(context, "call").toString(),
                                              ),
                                              onTap: () {
                                                if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
                                                  Navigator.of(context).pop();
                                                  launchUrl(Uri.parse("tel:$mobileNo"));
                                                } else {
                                                  Navigator.of(context).pop();
                                                  FormHelper.showMessage(
                                                    context,
                                                    getTranslated(context, "call").toString(),
                                                    getTranslated(context, "call_alert").toString(),
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
                                            ),
                                            if (videoCall)
                                            new ListTile(
                                              leading: new Icon(Icons.videocam),
                                              title: new Text(
                                                getTranslated(context, "videoCall").toString(),
                                              ),
                                              onTap: () {
                                                setState(
                                                  () {
                                                    if (SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true) {
                                                      Navigator.of(context).pop();
                                                      _addVideoOverlay(context);
                                                    } else {
                                                      Navigator.of(context).pop();
                                                      FormHelper.showMessage(
                                                        context,
                                                        getTranslated(context, "videoCall").toString(),
                                                        getTranslated(context, "videoCall_alert").toString(),
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
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
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
                                imageUrl: '$fullImage',
                                imageBuilder: (context, imageProvider) => ClipOval(
                                  child: Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                placeholder: (context, url) => ShimmerIndicator(size: 32),
                                errorWidget: (context, url, error) => ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.asset(
                                    "assets/images/no_image.jpg",
                                    width: width * 0.28,
                                    height: width * 0.28,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            _buildActionButton(
                              child: SvgPicture.asset(
                                'assets/icons/msg.svg',
                                width: 20,
                                height: 20,
                              ),
                              onTap: () {
                                SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                                    ? Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Chat(
                                            doctorId: doctorId!,
                                            where: 'DoctorDetail',
                                          ),
                                        ),
                                      )
                                    : FormHelper.showMessage(
                                        context,
                                        getTranslated(context, "doctorDetail_chat_alert_title").toString(),
                                        getTranslated(context, "doctorDetail_chat_alert_text").toString(),
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
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '$name',
                          style: TextStyle(
                            fontSize: 22,
                            color: Palette.dark_blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$treatmentName',
                          style: TextStyle(
                            fontSize: 14,
                            color: Palette.grey,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Palette.tabBar,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$expertise',
                            style: TextStyle(
                              fontSize: 12,
                              color: Palette.dark_blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.monetization_on_outlined,
                                label: getTranslated(context, AppString.doctorDetail_appointmentFees).toString(),
                                value: SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$appointmentFees',
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.work_outline,
                                label: getTranslated(context, AppString.doctorDetail_doctorExperience).toString(),
                                value: '$experience  ' + getTranslated(context, AppString.doctorDetail_year).toString(),
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.star_rate_rounded,
                                label: getTranslated(context, AppString.doctorDetail_doctorRates).toString(),
                                value: '$rate',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Palette.tabBar,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      labelColor: Palette.white,
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Palette.blue,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      tabs: [
                        Tab(
                          child: Text(
                            getTranslated(context, AppString.doctorDetail_tab1_title).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Tab(
                          child: Text(
                            getTranslated(context, AppString.doctorDetail_tab2_title).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Tab(
                          child: Text(
                            getTranslated(context, AppString.doctorDetail_tab3_title).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      unselectedLabelColor: Palette.dark_blue,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ///tab 1
                        SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              children: [
                                _buildSectionCard(
                                  title: getTranslated(context, AppString.doctorDetail_personalBio).toString(),
                                  child: Text(
                                    '$desc',
                                    style: TextStyle(fontSize: 13, color: Palette.grey, height: 1.4),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                                _buildSectionCard(
                                  title: getTranslated(context, AppString.doctorDetail_education).toString(),
                                  child: ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: degree.length,
                                    scrollDirection: Axis.vertical,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              degree[index]!.toUpperCase(),
                                              style: TextStyle(fontSize: 13, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              collage[index]! + '.',
                                              style: TextStyle(fontSize: 12, color: Palette.grey),
                                            ),
                                            Text(
                                              degreeYear[index]!,
                                              style: TextStyle(fontSize: 12, color: Palette.grey),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                _buildSectionCard(
                                  title: getTranslated(context, AppString.doctorDetail_certificate).toString(),
                                  child: ListView.builder(
                                    physics: NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: award.length,
                                    scrollDirection: Axis.vertical,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                award[index]!,
                                                style: TextStyle(fontSize: 13, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                            Text(
                                              awardYear[index]!,
                                              style: TextStyle(fontSize: 12, color: Palette.grey),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                _buildSectionCard(
                                  title: getTranslated(context, AppString.doctorDetail_specialization).toString(),
                                  child: Text(
                                    '$expertise',
                                    style: TextStyle(fontSize: 13, color: Palette.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        ///tab 2
                        hospitalDetail.isEmpty
                            ? Center(
                                child: Text(
                                  getTranslated(context, AppString.doctorDetail_hospitalName).toString(),
                                  style: TextStyle(fontSize: width * 0.04, color: Palette.dark_blue),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                physics: BouncingScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Column(
                                    children: [
                                      _buildSectionCard(
                                        title: getTranslated(context, AppString.doctorDetail_hospitalName).toString(),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Palette.dark_white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: DropdownButtonFormField(
                                            hint: Text(
                                              hospitalDetail[hospitalIndex].hospitalDetails!.name!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Palette.dark_blue,
                                              ),
                                            ),
                                            value: hospitalDetailData,
                                            isExpanded: true,
                                            iconSize: 25,
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            ),
                                            onSaved: (dynamic value) {
                                              setState(() {
                                                hospitalDetailData = value;
                                                print("$hospitalDetailData");
                                              });
                                            },
                                            onChanged: (HospitalId? newValue) {
                                              setState(
                                                () {
                                                  print("${hospitalDetail.indexOf(newValue!)}");
                                                  hospitalIndex = hospitalDetail.indexOf(newValue);
                                                  setState(() {});
                                                },
                                              );
                                            },
                                            validator: (dynamic value) => value == null ? getTranslated(context, AppString.bookAppointment_patientAddress_validator1).toString() : null,
                                            items: hospitalDetail.map((location) {
                                              return DropdownMenuItem<HospitalId>(
                                                child: new Text(
                                                  location.hospitalDetails!.name!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Palette.dark_blue,
                                                  ),
                                                ),
                                                value: location,
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      _buildSectionCard(
                                        title: getTranslated(context, AppString.doctorDetail_phoneNumber).toString(),
                                        child: _buildInfoTile(
                                          value: Text(
                                            SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true ? hospitalDetail[hospitalIndex].hospitalDetails!.phone! : "Login to see",
                                            style: TextStyle(fontSize: 13, color: Palette.dark_blue),
                                          ),
                                        ),
                                      ),
                                      _buildSectionCard(
                                        title: getTranslated(context, AppString.doctorDetail_address).toString(),
                                        child: _buildInfoTile(
                                          value: Text(
                                            hospitalDetail[hospitalIndex].hospitalDetails!.address!,
                                            style: TextStyle(fontSize: 13, color: Palette.grey),
                                          ),
                                        ),
                                      ),
                                      _buildSectionCard(
                                        title: getTranslated(context, AppString.doctorDetail_facility).toString(),
                                        child: _buildInfoTile(
                                          value: Text(
                                            hospitalDetail[hospitalIndex].hospitalDetails!.facility!,
                                            style: TextStyle(fontSize: 13, color: Palette.grey),
                                          ),
                                        ),
                                      ),
                                      hospitalDetail[hospitalIndex].hospitalGallery!.length != 0
                                          ? _buildSectionCard(
                                              title: getTranslated(context, AppString.doctorDetail_image).toString(),
                                              child: GridView.builder(
                                                physics: NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                scrollDirection: Axis.vertical,
                                                itemCount: hospitalDetail[hospitalIndex].hospitalGallery!.length,
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 3,
                                                  mainAxisSpacing: 8,
                                                  crossAxisSpacing: 8,
                                                ),
                                                itemBuilder: (context, imageIndex) {
                                                  return ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: CachedNetworkImage(
                                                      alignment: Alignment.center,
                                                      imageUrl: hospitalDetail[hospitalIndex].hospitalGallery![imageIndex].fullImage!,
                                                placeholder: (context, url) => ShimmerIndicator(size: 28),
                                                      errorWidget: (context, url, error) => Image.asset("assets/images/NoImage.png"),
                                                      height: height * 0.2,
                                                      width: width * 0.3,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : SizedBox(),
                                    ],
                                  ),
                                ),
                              ),

                        ///tab 3
                        reviews.length != 0
                            ? SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                physics: AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Text(
                                          getTranslated(context, AppString.doctorDetail_review).toString(),
                                          style: TextStyle(
                                            fontSize: width * 0.04,
                                            color: Palette.dark_blue,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      ListView.builder(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemCount: reviews.length,
                                        itemBuilder: (context, index) {
                                          String date = DateUtil().formattedDate(DateTime.parse(reviews[index].createdAt!));
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Palette.white,
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Palette.blue.withOpacity(0.08),
                                                  blurRadius: 12,
                                                  offset: Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: height * 0.062,
                                                  width: width * 0.125,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Palette.blue.withOpacity(0.15),
                                                        blurRadius: 4,
                                                      ),
                                                    ],
                                                  ),
                                                  child: CachedNetworkImage(
                                                    alignment: Alignment.center,
                                                    imageUrl: reviews[index].user!.fullImage!,
                                                    imageBuilder: (context, imageProvider) => CircleAvatar(
                                                      radius: 50,
                                                      backgroundColor: Palette.white,
                                                      child: CircleAvatar(
                                                        radius: 20,
                                                        backgroundImage: imageProvider,
                                                      ),
                                                    ),
                                                    placeholder: (context, url) => ShimmerIndicator(size: 28),
                                                    errorWidget: (context, url, error) => ClipRRect(
                                                      borderRadius: BorderRadius.circular(50),
                                                      child: Image.asset(
                                                        "assets/images/no_image.jpg",
                                                        fit: BoxFit.fitHeight,
                                                        width: 60,
                                                        height: 60,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Row(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  reviews[index].user!.name!,
                                                                  style: TextStyle(fontSize: width * 0.035, fontWeight: FontWeight.bold, color: Palette.dark_blue),
                                                                ),
                                                                SizedBox(height: 2),
                                                                Text(
                                                                  '$date',
                                                                  style: TextStyle(fontSize: 11, color: Palette.grey),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          RatingBarIndicator(
                                                            rating: reviews[index].rate!.toDouble(),
                                                            itemBuilder: (context, index) => Icon(
                                                              Icons.star,
                                                              color: Palette.blue,
                                                            ),
                                                            itemCount: 5,
                                                            itemSize: width * 0.04,
                                                            direction: Axis.horizontal,
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        reviews[index].review!,
                                                        style: TextStyle(fontSize: 12, color: Palette.grey),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Container(
                                alignment: AlignmentDirectional.center,
                                child: Text(
                                  getTranslated(context, AppString.doctorDetail_noReview).toString(),
                                  style: TextStyle(fontSize: width * 0.04, color: Palette.dark_blue),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: width * 0.13,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Palette.blue,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  getTranslated(context, AppString.doctorDetail_bookAppointment).toString(),
                  style: TextStyle(fontSize: width * 0.04, color: Palette.white),
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookAppointment(id: id),
                          ),
                        )
                      : FormHelper.showMessage(
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
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Palette.tabBar,
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Palette.blue.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Palette.blue, size: 20),
          SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Palette.grey),
          ),
          SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Palette.dark_blue, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Palette.blue.withOpacity(0.08),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 14, color: Palette.dark_blue, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoTile({required Widget value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Palette.dark_white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: value,
    );
  }

  Future<BaseModel<DoctorDetailModel>> callApiDoctorDetail() async {
    DoctorDetailModel response;
    Map<String, dynamic> body = {
      "lat": _lat,
      "lang": _lang,
    };
    if (mounted) setState(() { loading = true; });
    print(body);
    try {
      response = await RestClient(RetroApi2().dioData2()).doctorDetailRequest(id, body);
      if (response.success == true && response.data == null) {
        throw StateError('Doctor details are unavailable');
      }
      if (response.success == true && mounted) {
        setState(() {
          loading = false;
          id = response.data!.id;
          doctorId = response.data!.userId;
          name = response.data!.name;
          rate = response.data!.rate?.toDouble() ?? 0.0;
          experience = response.data!.experience;
          appointmentFees = response.data!.appointmentFees;
          desc = response.data!.desc;
          expertise = response.data!.expertise?.name ?? '';
          fullImage = response.data!.fullImage;
          treatmentName = response.data!.treatment?.name ?? '';
          reviews.addAll(response.data!.reviews ?? []);
          videoCall = response.data!.patientVideoCall == 0 ? false : true;
          hospitalDetail.addAll(response.data!.hospitalId ?? []);
          var convertDegree = json.decode(response.data!.education ?? '[]');
          degree.clear();
          collage.clear();
          degreeYear.clear();
          for (int i = 0; i < convertDegree.length; i++) {
            degree.add(convertDegree[i]['degree']);
            collage.add(convertDegree[i]['college']);
            degreeYear.add(convertDegree[i]['year']);
          }
          var convertCertificate = json.decode(response.data!.certificate ?? '[]');
          award.clear();
          awardYear.clear();
          for (int i = 0; i < convertCertificate.length; i++) {
            award.add(convertCertificate[i]['certificate']);
            awardYear.add(convertCertificate[i]['certificate_year']);
          }
        });
      }
    } catch (error, stacktrace) {
      if (mounted) setState(() { loading = false; });
      print("Exception occur: $error stackTrace: $stacktrace");
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }
}
