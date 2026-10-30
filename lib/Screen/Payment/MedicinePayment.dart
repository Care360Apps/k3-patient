import 'dart:convert';
import 'dart:io';
import 'package:doctro_patient/const/preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:geolocator/geolocator.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../model/common_response.dart';
import '../MedicineAndPharmacy/AllPharamacy.dart';
import '../AppointmentRelatedScreen/Bookappointment.dart';
import '../Location/Showlocation.dart';
import 'PaypalPaymentScreen.dart';
import '../../api/retrofit_Api.dart';
import '../../api/network_api.dart';
import 'package:dio/dio.dart';
import '../../const/prefConstatnt.dart';
import '../../database/db_service.dart';
import '../../models/data_model.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';
import '../../model/detail_setting_model.dart';
import '../../model/pharmacys_details_model.dart';
import '../../model/apply_offer_model.dart';
import 'medicines_stripe_services.dart';

enum SingingCharacter { Pharmacy, Home }

enum SingingCharacterPayment { Paypal, Razorpay, Stripe, FlutterWave, PayStack, COD }

class MedicinePayment extends StatefulWidget {
  @override
  _MedicinePaymentState createState() => _MedicinePaymentState();
}

class _MedicinePaymentState extends State<MedicinePayment> {
  TextEditingController _offerController = TextEditingController();

  final GlobalKey<FormState> _offerFormKey = GlobalKey<FormState>();

  bool isPaymentClicked = false;

  SingingCharacter? _character = SingingCharacter.Pharmacy;
  SingingCharacterPayment? _payment;

  late var str;
  var parts;
  String? deliveryType = "Pharmacy";
  var startPart;

  var strPayment;
  var partsPayment;
  String? paymentType = 'COD';
  var startPartPayment;

  //Discount //
  String discountType = "";
  int? isFlat = 0;
  int? flatDiscount = 0;
  int? discount = 0;
  int? minDiscount = 0;
  DateTime? todayDate;

  late int deliveryDistance;

  ProductModel? model;
  late DBService dbService;

  String? address = "";
  int addressId = 0;

  String? businessName = "";
  String? logo = "";
  String? razorpayKey = "";
  int? cod = 0;
  int? stripe = 0;
  int? paypal = 0;
  int? razor = 0;
  int? flutterWave = 0;
  int? payStack = 0;

  bool loading = false;

  String isWhere = "";
  String? userLat = "";
  String? userLang = "";

  int? userCharges;
  int? isShipping;
  String? pharmacyLat;
  String? pharmacyLong;

  // Razorpay //
  late Razorpay _razorpay;

  // FlutterWave //
  final String txRef = "";
  final String amount = "";

  String? _paymentToken = "";

  String? userPhoneNo = "";
  String? userEmail = "";

  List<String?> minValue = [];
  List<String?> maxValue = [];
  List<String?> charges = [];

  int payAmount = 0;
  int grandTotal = 0;
  dynamic discountGrandTotal = 0;
  dynamic newGrandTotal = 0;
  int pharmacyId = 0;
  String? prescriptionFilePath = "";
  List<Map<String, dynamic>> medicine = [];

  double prAmount = 0;

  List<DeliveryChargesModel> listDeliveryCharge = [];
  String? strFinalDeliveryCharge = '';

  int? charge;
  List<Map> listData = [];

  @override
  void initState() {
    super.initState();
    dbService = new DBService();
    model = new ProductModel();
    getBookedData();
    initFun();
    _getAddress();
    _detailSetting();

    todayDate = DateTime.now();

    // RazorPay //
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    Stripe.publishableKey = SharedPreferenceHelper.getString(Preferences.stripe_public_key)!;
  }

  // RazorPay Clear //
  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
  }

  Future initFun() async {
    await callApiPharamacyDetail();
  }

  getBookedData() async {
    grandTotal = SharedPreferenceHelper.getInt('grandTotal');
    pharmacyId = SharedPreferenceHelper.getInt('pharmacyIdCart');
    prescriptionFilePath = SharedPreferenceHelper.getString('prescriptionFilePath');
    _character = isShipping == 1 ? SingingCharacter.Home : SingingCharacter.Pharmacy;
    deliveryType = isShipping == 1 ? "Home" : "Pharmacy";
    getSavedInfo();
  }

  getSavedInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    var myFavList = json.decode(pref.getString('myFavList')!);
    for (int i = 0; i < myFavList.length; i++) {
      listData.add({
        "id": myFavList[i]["id"],
        "price": myFavList[i]["price"],
        "qty": myFavList[i]["qty"],
      });
    }
  }

  _getAddress() async {
    setState(
      () {
        address = (SharedPreferenceHelper.getString('Address'));
        addressId = (SharedPreferenceHelper.getInt('addressId'));
        userLat = SharedPreferenceHelper.getString('lat');
        userLang = SharedPreferenceHelper.getString('lang');
        //user data
        userPhoneNo = SharedPreferenceHelper.getString('phone_no');
        userEmail = SharedPreferenceHelper.getString('email');
      },
    );
  }

  getDistance() async {
    double distanceInMeters = Geolocator.distanceBetween(double.parse(pharmacyLat!), double.parse(pharmacyLong!), double.parse(userLat!), double.parse(userLang!));
    double deliveryKM = distanceInMeters / 1000;
    str = "$deliveryKM";
    parts = str.split(".");
    deliveryDistance = int.parse(parts[0].trim());

    if (isShipping == 1) {
      String? strFinalDeliveryCharge1 = '';
      for (int i = 0; i < listDeliveryCharge.length; i++) {
        if (deliveryDistance >= double.parse(listDeliveryCharge[i].minValue!) && deliveryDistance <= double.parse(listDeliveryCharge[i].maxValue!)) {
          strFinalDeliveryCharge1 = listDeliveryCharge[i].charges;
        }
      }
      if (deliveryDistance < 1) {
        strFinalDeliveryCharge = '0';
      } else {
        if (strFinalDeliveryCharge1 == '') {
          var max = listDeliveryCharge.reduce((current, next) => int.parse(current.charges!) > int.parse(next.charges!) ? current : next);
          strFinalDeliveryCharge = max.charges;
        } else {
          strFinalDeliveryCharge = strFinalDeliveryCharge1;
        }
      }
    }

    SharedPreferenceHelper.setString('strFinalDeliveryCharge', strFinalDeliveryCharge!);

    if (deliveryType == "Home" && isShipping == 1) {
      payAmount = grandTotal + int.parse(strFinalDeliveryCharge!);
    } else {
      payAmount = grandTotal;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    width = MediaQuery.of(context).size.width;
    height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Palette.dark_white,
      appBar: PreferredSize(
        preferredSize: Size(width * 0.3, 50),
        child: SafeArea(
          top: true,
          child: Container(
            alignment: Alignment.centerLeft,
            margin: EdgeInsets.only(left: 5, right: 5),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                size: 25,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.5,
        progressIndicator: SpinKitFadingCircle(
          color: Palette.blue,
          size: 50.0,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              children: [
                // Delivery type card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.blue.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslated(context, AppString.medicinePayment_youOrdered).toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Palette.dark_blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          getTranslated(context, AppString.medicinePayment_pharmacy).toString(),
                          style: const TextStyle(
                            color: Palette.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: SingingCharacter.Pharmacy,
                        groupValue: _character,
                        onChanged: (SingingCharacter? value) {
                          setState(() {
                            payAmount = grandTotal;
                            _character = value;
                            str = "$_character";
                            parts = str.split(".");
                            startPart = parts[0].trim();
                            deliveryType = parts.sublist(1).join('.').trim();
                          });
                        },
                      ),
                      if (isShipping == 1)
                        RadioListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            getTranslated(context, AppString.medicinePayment_home).toString(),
                            style: const TextStyle(
                              color: Palette.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: SingingCharacter.Home,
                          groupValue: _character,
                          onChanged: (SingingCharacter? value) {
                            setState(
                              () {
                                _character = value;
                                str = "$_character";
                                parts = str.split(".");
                                startPart = parts[0].trim();
                                deliveryType = parts.sublist(1).join('.').trim();
                                getDistance();
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
                deliveryType == 'Home' && isShipping == 1
                    ? Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Palette.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Palette.blue.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslated(context, AppString.medicinePayment_address).toString(),
                              style: const TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                SharedPreferenceHelper.setString('isWhere', "MedicinePayment");
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShowLocation(),
                                  ),
                                );
                              },
                              child: Text(
                                address != null && address != "N_A"
                                    ? '$address'
                                    : getTranslated(context, AppString.addLocation_address_validator).toString(),
                                style: const TextStyle(fontSize: 14, color: Palette.blue),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(),
                const SizedBox(height: 16),
                // Offer code card
                Form(
                  key: _offerFormKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Palette.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Palette.blue.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _offerController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'))],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: getTranslated(context, AppString.medicinePayment_offerCode_hint).toString(),
                              hintStyle: TextStyle(
                                fontSize: width * 0.04,
                                color: Palette.dark_grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            validator: (String? value) {
                              if (value!.isEmpty) {
                                return getTranslated(context, AppString.medicinePayment_offerCode_validator).toString();
                              }
                              return null;
                            },
                            onSaved: (String? name) {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_offerFormKey.currentState!.validate()) {
                                callApiApplyOffer();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              getTranslated(context, AppString.medicinePayment_apply_button).toString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                // Total amount card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.blue.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslated(context, AppString.medicinePayment_totalAmount).toString(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Palette.dark_blue),
                      ),
                      const SizedBox(height: 8),
                      deliveryType == "Home" && isShipping == 1
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.medicinePayment_amount).toString(),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          ('$discountGrandTotal' == "0.0" || '$discountGrandTotal' == "0"
                                                  ? SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + grandTotal.toString()
                                                  : SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + discountGrandTotal.toString()),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.blue),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          getTranslated(context, AppString.medicinePayment_deliveryCharges).toString(),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$strFinalDeliveryCharge',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.blue),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  ('$newGrandTotal' == "0.0" || '$newGrandTotal' == "0"
                                          ? SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$payAmount'
                                          : SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$newGrandTotal'),
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Palette.blue,
                                  ),
                                ),
                              ],
                            )
                          : Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                ('$newGrandTotal' == "0.0" || '$newGrandTotal' == '0'
                                        ? SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$payAmount'
                                        : SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$newGrandTotal'),
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Palette.blue,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Palette.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.blue.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslated(context, AppString.medicinePayment_paymentType).toString(),
                        style: const TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      // Paypal
                      if (paypal == 1 && Platform.isAndroid)
                        _buildPaymentOption(
                          value: SingingCharacterPayment.Paypal,
                          title: Row(
                            children: [
                              Image.network(
                                "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/PayPal_Logo_Icon_2014.svg/1200px-PayPal_Logo_Icon_2014.svg.png",
                                height: 26,
                                width: 44,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslated(context, AppString.payPal).toString(),
                                style: const TextStyle(fontSize: 15, color: Palette.black),
                              ),
                            ],
                          ),
                        ),
                      // Razorpay
                      if (razor == 1)
                        _buildPaymentOption(
                          value: SingingCharacterPayment.Razorpay,
                          title: Row(
                            children: [
                              Image.network(
                                "https://avatars.githubusercontent.com/u/7713209?s=280&v=4",
                                height: 26,
                                width: 44,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslated(context, AppString.razorPay).toString(),
                                style: const TextStyle(fontSize: 15, color: Palette.black),
                              ),
                            ],
                          ),
                        ),
                      // Stripe
                      if (stripe == 1)
                        _buildPaymentOption(
                          value: SingingCharacterPayment.Stripe,
                          title: Row(
                            children: [
                              Image.network(
                                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT3PGzfbaZZzR0j8rOWBjWJPGWnkPzkm12f5A&usqp=CAU",
                                height: 26,
                                width: 44,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslated(context, AppString.stripe_label).toString(),
                                style: const TextStyle(fontSize: 15, color: Palette.black),
                              ),
                            ],
                          ),
                        ),
                      // FlutterWave
                      if (flutterWave == 1)
                        _buildPaymentOption(
                          value: SingingCharacterPayment.FlutterWave,
                          title: Row(
                            children: [
                              Image.network(
                                "https://cdn.filestackcontent.com/OITnhSPCSzOuiVvwnH7r",
                                height: 26,
                                width: 44,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  getTranslated(context, AppString.flutterWave_label).toString(),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontSize: 15, color: Palette.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Paystack
                      if (payStack == 1)
                        _buildPaymentOption(
                          value: SingingCharacterPayment.PayStack,
                          title: Row(
                            children: [
                              Image.network(
                                "https://website-v3-assets.s3.amazonaws.com/assets/img/hero/Paystack-mark-white-twitter.png",
                                height: 26,
                                width: 44,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                getTranslated(context, AppString.payStackLabel).toString(),
                                style: const TextStyle(fontSize: 15, color: Palette.black),
                              ),
                            ],
                          ),
                        ),
                      // COD
                      if (cod == 1)
                        _buildPaymentOption(
                          value: SingingCharacterPayment.COD,
                          title: Text(
                            getTranslated(context, AppString.codLabel).toString(),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(fontSize: 15, color: Palette.black),
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
      bottomNavigationBar: Container(
        height: 50,
        child: ElevatedButton(
          child: Text(
            getTranslated(context, AppString.bookAppointment_pay_button).toString(),
            // 'Pay'
          ),
          onPressed: () async {
            if (deliveryType == 'Home') {
              if (address != null && address != "N_A") {
                if (_payment!.index == 0) {
                  print('Paypal');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) => PaypalPayment(
                        total: grandTotal.toString(),
                        onFinish: (number) async {
                          print('order id: ' + number);
                          if (number != null && number.toString() != '') {
                            setState(() {
                              _paymentToken = number;
                              callApiBookMedicine();
                            });
                            print("success paypal payment ${number.toString()}");
                          }
                        },
                      ),
                    ),
                  );
                }
                if (_payment!.index == 1) {
                  openCheckoutRazorPay();
                  print('Razorpay');
                }
                if (_payment!.index == 2) {
                  print('Stripe');
                  Provider.of<MedicinesStripePayment>(context, listen: false)
                      .makePayment(context: context, pharamacyId: pharmacyId, amount: grandTotal.toString(), deliveryType: deliveryType, prescriptionFilePath: prescriptionFilePath, strFinalDeliveryCharge: strFinalDeliveryCharge, listData: listData);
                }
                if (_payment!.index == 3) {
                  flutterWavePayment(context, payAmount);
                }
                if (_payment!.index == 4) {
                  Fluttertoast.showToast(msg: getTranslated(context, AppString.payStackLabel).toString() + " is not available");
                }
                if (_payment!.index == 5) {
                  print('cod');
                  callApiBookMedicine();
                }
              } else {
                Fluttertoast.showToast(msg: "Please Select Address");
              }
            } else {
              if (_payment!.index == 0) {
                print('Paypal');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) => PaypalPayment(
                      total: grandTotal.toString(),
                      onFinish: (number) async {
                        print('order id: ' + number);
                        if (number != null && number.toString() != '') {
                          setState(() {
                            _paymentToken = number;
                            callApiBookMedicine();
                          });
                          print("success paypal payment ${number.toString()}");
                        }
                      },
                    ),
                  ),
                );
              }
              if (_payment!.index == 1) {
                openCheckoutRazorPay();
                print('Razorpay');
              }
              if (_payment!.index == 2) {
                print('Stripe');
                Provider.of<MedicinesStripePayment>(context, listen: false)
                    .makePayment(context: context, pharamacyId: pharmacyId, amount: grandTotal.toString(), deliveryType: deliveryType, prescriptionFilePath: prescriptionFilePath, strFinalDeliveryCharge: strFinalDeliveryCharge, listData: listData);
              }
              if (_payment!.index == 3) {
                flutterWavePayment(context, payAmount);
              }
              if (_payment!.index == 4) {
                Fluttertoast.showToast(msg: getTranslated(context, AppString.payStackLabel).toString() + " is not available");
              }
              if (_payment!.index == 5) {
                print('cod');
                callApiBookMedicine();
              }
            }
            str = "$_payment";
            parts = str.split(".");
            startPartPayment = parts[0].trim();
            paymentType = parts.sublist(1).join('.').trim();
          },
        ),
      ),
    );
  }

  Future<BaseModel<DetailSetting>> _detailSetting() async {
    DetailSetting response;

    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).settingRequest();
      setState(() {
        loading = false;
        if (response.success == true) {
          razorpayKey = response.data!.razorKey;
          businessName = response.data!.businessName;
          logo = response.data!.logo;
          cod = response.data!.cod;
          stripe = response.data!.stripe;
          paypal = response.data!.paypal;
          flutterWave = response.data!.flutterwave;
          razor = response.data!.razor;
          payStack = response.data!.payStack;
          setState(() {});
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

  Widget _buildPaymentOption({
    required SingingCharacterPayment value,
    required Widget title,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Palette.dark_white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RadioListTile<SingingCharacterPayment>(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: Palette.blue,
        title: title,
        value: value,
        groupValue: _payment,
        onChanged: (SingingCharacterPayment? newValue) {
          setState(() {
            _payment = newValue;
            isPaymentClicked = true;
          });
        },
      ),
    );
  }

  // RazorPay Code //
  void openCheckoutRazorPay() async {
    var options = {
      'key': SharedPreferenceHelper.getString(Preferences.razor_key),
      'amount': '$newGrandTotal' == "0.0" || '$newGrandTotal' == '0' ? num.parse('$payAmount') * 100 : num.parse('$newGrandTotal') * 100,
      'name': '$businessName',
      'image': '$logo',
      'currency': SharedPreferenceHelper.getString(Preferences.currency_code),
      'description': '',
      'send_sms_hash': 'true',
      'prefill': {'contact': '$userPhoneNo', 'email': '$userEmail'},
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  // RazorPay Success Method //
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentToken = response.paymentId;
    _paymentToken != "" && _paymentToken!.isNotEmpty ? callApiBookMedicine() : Fluttertoast.showToast(msg: getTranslated(context, AppString.medicinePayment_paymentNotComplete).toString(), toastLength: Toast.LENGTH_SHORT);
  }

  // RazorPay Error Method //
  void _handlePaymentError(PaymentFailureResponse response) {}

  // RazorPay Wallet Method //
  void _handleExternalWallet(ExternalWalletResponse response) {}

  String _getReference() {
    String platform;
    if (Platform.isIOS) {
      platform = 'iOS';
    } else {
      platform = 'Android';
    }
    return 'ChargedFrom${platform}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<BaseModel<CommonResponse>> callApiBookMedicine() async {
    String fileName = prescriptionFilePath!.split('/').last;
    CommonResponse response;
    Map<String, dynamic> body = {};
    body['pharmacy_id'] = pharmacyId;
    body["medicines"] = JsonEncoder().convert(listData);
    body["amount"] = grandTotal;
    body["payment_type"] = paymentType;
    body["payment_status"] = _payment!.index == 5 ? 0 : 1;
    body["payment_token"] = _payment!.index == 5 ? "" : _paymentToken;
    body["shipping_at"] = deliveryType;
    body["address_id"] = deliveryType == 'Pharmacy' ? "" : addressId;
    body["delivery_charge"] = deliveryType == 'Pharmacy' ? 0 : strFinalDeliveryCharge;
    if (prescriptionFilePath != "") {
      body["pdf"] = MultipartFile.fromFileSync(prescriptionFilePath!, filename: fileName);
    }
    try {
      print(body);
      setState(() {
        Preferences.onLoading(context);
      });
      response = await RestClient(RetroApi().dioData()).bookMedicineRequest(body);
      if (response.success == true) {
        setState(() {
          Preferences.hideDialog(context);
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        Preferences.hideDialog(context);
        prefs.remove('grandTotal');
        prefs.remove('strFinalDeliveryCharge');
        prefs.remove('pharmacyId');
        prefs.remove('prescriptionFilePath');
        late List<ProductModel> products;
        await dbService.getProducts().then((value) {
          products = value;
        });
        dbService.deleteTable(products[0]).then((value) {
          setState(() {});
        });
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AllPharamacy()),
          ModalRoute.withName('/'),
        );
      } else {
        setState(() {
          Preferences.hideDialog(context);
        });
      }
    } catch (error) {
      setState(() {
        Preferences.hideDialog(context);
      });
      return BaseModel()..setException(ServerError.withError(error: error));
    }
    return BaseModel()..data = response;
  }

  ///flutter wave
  final String currencyFlutterWave = "RWF";

  flutterWavePayment(context, payAmount) async {
    final flutterwave = Flutterwave(
      publicKey: SharedPreferenceHelper.getString(Preferences.flutterWave_key)!,
      currency: currencyFlutterWave,
      txRef: Uuid().v1(),
      amount: payAmount.toString(),
      customer: customer,
      paymentOptions: "card",
      customization: Customization(title: "Doctro Patient"),
      redirectUrl: "https://www.google.com",
      isTestMode: true,
    );
    final ChargeResponse response = await flutterwave.charge(context);
    if (response.transactionId!.isNotEmpty) {
      setState(() {
        _paymentToken = response.transactionId;
        callApiBookMedicine();
        ;
      });
    }
  }

  final Customer customer = Customer(name: SharedPreferenceHelper.getString(Preferences.name)!, phoneNumber: SharedPreferenceHelper.getString(Preferences.phone)!, email: SharedPreferenceHelper.getString(FirestoreConstants.email)!);

  Future<BaseModel<ApplyOffer>> callApiApplyOffer() async {
    ApplyOffer response;
    var offerDateToday = "$todayDate";
    String offerDate = DateUtilForPass().formattedDate(DateTime.parse(offerDateToday));
    Map<String, dynamic> body = {
      "offer_code": _offerController.text,
      "date": offerDate,
      "from": "medicine",
    };
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).applyOfferRequest(body);
      setState(() {
        if (response.success == true) {
          setState(() {
            loading = false;
            discountType = response.data!.discountType!.toUpperCase();
            flatDiscount = response.data!.flatDiscount;
            isFlat = response.data!.isFlat;
            minDiscount = response.data!.minDiscount;
            discount = response.data!.discount;

            if (discountType == "AMOUNT" && isFlat == 1) {
              if (grandTotal > flatDiscount!) {
                if (flatDiscount! < minDiscount!) {
                  newGrandTotal = int.parse('$payAmount') - int.parse('$flatDiscount');
                  discountGrandTotal = double.parse('$grandTotal') - double.parse('$flatDiscount');
                } else {
                  newGrandTotal = int.parse('$payAmount') - int.parse('$minDiscount');
                  discountGrandTotal = double.parse('$grandTotal') - double.parse('$minDiscount');
                }
                Fluttertoast.showToast(
                  msg: getTranslated(context, AppString.medicinePayment_successFullOfferApply_toast).toString(),
                  // 'Successfully Offer Apply',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                );
              } else {
                Fluttertoast.showToast(
                  msg: getTranslated(context, AppString.medicinePayment_worthMoreThan_toast).toString() + SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$flatDiscount.',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                );
              }
            } else if (discountType == "AMOUNT" && isFlat == 0) {
              if (grandTotal > discount!) {
                if (discount! < minDiscount!) {
                  newGrandTotal = int.parse('$payAmount') - int.parse('$discount');
                  discountGrandTotal = double.parse('$grandTotal') - double.parse('$discount');
                } else {
                  newGrandTotal = int.parse('$payAmount') - int.parse('$minDiscount');
                  discountGrandTotal = double.parse('$grandTotal') - double.parse('$minDiscount');
                }
                Fluttertoast.showToast(
                  msg: getTranslated(context, AppString.medicinePayment_successFullOfferApply_toast).toString(),
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                );
              } else {
                Fluttertoast.showToast(
                  msg: getTranslated(context, AppString.medicinePayment_worthMoreThan_toast).toString() + SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$discount.',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                );
              }
            } else if (discountType == "PERCENTAGE") {
              prAmount = (int.parse('$grandTotal') * int.parse('$discount')) / 100;
              if (prAmount <= minDiscount!) {
                newGrandTotal = double.parse('$payAmount') - double.parse('$prAmount');
                discountGrandTotal = double.parse('$grandTotal') - double.parse('$prAmount');
              } else {
                newGrandTotal = double.parse('$payAmount') - double.parse('$minDiscount');
                discountGrandTotal = double.parse('$grandTotal') - double.parse('$minDiscount');
              }
              Fluttertoast.showToast(
                msg: payAmount >= prAmount || payAmount >= minDiscount!
                    ? getTranslated(context, AppString.medicinePayment_successFullOfferApply_toast).toString()
                    : getTranslated(context, AppString.medicinePayment_worthMoreThan_toast).toString() + SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$prAmount.',
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
              );
              newGrandTotal = payAmount >= prAmount || payAmount >= minDiscount! ? newGrandTotal : payAmount;
            }
          });
        } else {
          setState(() {
            loading = false;
            Fluttertoast.showToast(
              msg: '${response.msg}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
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

  Future<BaseModel<PharmacyDetailsModel>> callApiPharamacyDetail() async {
    PharmacyDetailsModel response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).pharmacyDetailRequest(pharmacyId);
      setState(() {
        loading = false;

        if (response.success == true) {
          if (mounted) {
            setState(() {
              isShipping = response.data!.isShipping;
              pharmacyLat = response.data!.lat;
              pharmacyLong = response.data!.lang;
              if (isShipping == 1) {
                var convertCharges = json.decode(response.data!.deliveryCharges!);
                minValue.clear();
                maxValue.clear();
                charges.clear();
                for (int i = 0; i < convertCharges.length; i++) {
                  minValue.add(convertCharges[i]['min_value']);
                  maxValue.add(convertCharges[i]['max_value']);
                  charges.add(convertCharges[i]['charges']);
                }

                String strDeliveryCharges = response.data!.deliveryCharges!;
                var deliveryCharge = jsonDecode(strDeliveryCharges);
                listDeliveryCharge = (deliveryCharge as List).map((i) => DeliveryChargesModel.fromJson(i)).toList();
              }
              getDistance();
            });
          } else {
            isShipping = response.data!.isShipping;
            pharmacyLat = response.data!.lat;
            pharmacyLong = response.data!.lang;
            if (isShipping == 1) {
              var convertCharges = json.decode(response.data!.deliveryCharges!);
              minValue.clear();
              maxValue.clear();
              charges.clear();
              for (int i = 0; i < convertCharges.length; i++) {
                minValue.add(convertCharges[i]['min_value']);
                maxValue.add(convertCharges[i]['max_value']);
                charges.add(convertCharges[i]['charges']);
              }

              String strDeliveryCharges = response.data!.deliveryCharges!;
              var deliveryCharge = jsonDecode(strDeliveryCharges);
              listDeliveryCharge = (deliveryCharge as List).map((i) => DeliveryChargesModel.fromJson(i)).toList();
            }

            getDistance();
          }
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

class DeliveryChargesModel {
  String? minValue;
  String? maxValue;
  String? charges;

  DeliveryChargesModel({this.minValue, this.maxValue, this.charges});

  factory DeliveryChargesModel.fromJson(Map<String, dynamic> parsedJson) {
    return DeliveryChargesModel(minValue: parsedJson['min_value'], maxValue: parsedJson['max_value'], charges: parsedJson['charges']);
  }
}
