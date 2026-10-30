import 'dart:convert';
import 'package:doctro_patient/const/app_string.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Payment/MedicinePayment.dart';
import '../../const/Palette.dart';
import '../../const/preference.dart';
import '../../const/prefConstatnt.dart';
import '../../database/db_service.dart';
import '../../database/form_helper.dart';
import '../../localization/localization_constant.dart';
import '../../models/data_model.dart';

class AddToCart extends StatefulWidget {
  final bool isEditMode = true;

  @override
  _AddToCartState createState() => _AddToCartState();
}

class _AddToCartState extends State<AddToCart> {
  String? address = "";

  ProductModel? model;
  late DBService dbService;

  bool isSelected = false;

  int grandTotal = 0;
  int passGrandTotal = 0;

  int pharmacyId = 0;
  int? pharmacyIdCart = 0;
  String? prescriptionFilePath = "";

  List<ProductModel> products = [];
  List<Map<String, dynamic>> medicineBooked = [];

  int? shippingStatus;
  String? pharmacyLat = "";
  String? pharmacyLang = "";

  String? listOfMedicine;

  String? userLat = "";
  String? userLang = "";

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _getAddress();
    dbService = new DBService();
    model = new ProductModel();

    getGrandTotal();
  }

  var loggerNoStack = Logger(
    printer: PrettyPrinter(methodCount: 0),
  );

  getGrandTotal() async {
    Future<List<ProductModel>> _futureOfList = dbService.getProducts();
    products.clear();
    products = await _futureOfList;
    if (products.length != 0) {
      if (products.length != 0) {
        medicineBooked.clear();

        shippingStatus = products[0].shippingStatus;
        pharmacyLat = products[0].pLat;
        pharmacyLang = products[0].pLang;
        grandTotal = 0;
        for (var data in products) {
          grandTotal = grandTotal + (data.quantity! * data.price!);
          Map<String, dynamic> medicineBookedDetail = {
            "id": data.medicineId.toString(),
            "price": data.price.toString(),
            "qty": data.quantity.toString(),
          };
          medicineBooked.add(medicineBookedDetail);
          pharmacyIdCart = products[0].pharmacyId;
          prescriptionFilePath = products[0].prescriptionFilePath;
          Logger().d(medicineBooked);
        }
        setState(() {});
      }
    }
  }

  _getAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(
      () {
        address = (prefs.getString('Address'));
        userLat = (prefs.getString('lat'));
        userLang = (prefs.getString('lang'));
      },
    );
  }

  setBookedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (grandTotal != grandTotal) {
      prefs.remove('grandTotal');
      prefs.remove('pharmacyIdCart');
      prefs.remove('pharmacyLat');
      prefs.remove('pharmacyLang');
      prefs.setInt('grandTotal', grandTotal);
      prefs.setInt('pharmacyIdCart', pharmacyIdCart!);
      prefs.setString('prescriptionFilePath', prescriptionFilePath!);
      prefs.setString('pharmacyLat', pharmacyLat!);
      prefs.setString('pharmacyLang', pharmacyLang!);
      _saveToList(medicineBooked);
    } else {
      prefs.setInt('grandTotal', grandTotal);
      prefs.setInt('pharmacyIdCart', pharmacyIdCart!);
      prefs.setString('prescriptionFilePath', prescriptionFilePath!);
      prefs.setString('pharmacyLat', pharmacyLat!);
      prefs.setString('pharmacyLang', pharmacyLang!);
      _saveToList(medicineBooked);
    }
  }

  _saveToList(List<Map<String, dynamic>> _favList) async {
    var s = json.encode(medicineBooked);
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString('myFavList', s);
    Logger().d(SharedPreferenceHelper.getString('myFavList'));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (products.length != 0) {
      return Scaffold(
        backgroundColor: Palette.dark_white,
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Palette.white,
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
              getTranslated(context, AppString.cart_title).toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Palette.dark_blue,
              ),
            ),
            centerTitle: true),
        body: Container(
          color: Palette.dark_white,
          child: SingleChildScrollView(child: _fetchData()),
        ),
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Palette.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Palette.blue.withOpacity(0.08),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      getTranslated(context, AppString.AddToCart_total).toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Palette.grey,
                      ),
                    ),
                    Text(
                      '${SharedPreferenceHelper.getString(Preferences.currency_symbol)}$grandTotal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Palette.dark_blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      getTranslated(context, AppString.AddToCart_placeOrder).toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Palette.white,
                      ),
                    ),
                    onPressed: () {
                      loggerNoStack.t(medicineBooked);
                      if (products.length != 0) {
                        setBookedData();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MedicinePayment(),
                          ),
                        );
                      } else {
                        Fluttertoast.showToast(
                          msg: getTranslated(context, AppString.AddToCart_cartInNoData).toString(),
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
            elevation: 0,
            backgroundColor: Palette.white,
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
              getTranslated(context, AppString.cart_title).toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Palette.dark_blue,
              ),
            ),
            centerTitle: true),
        body: Center(
          child: Text(
            getTranslated(context, AppString.AddToCart_NoData).toString(),
            style: TextStyle(fontSize: width * 0.045, color: Palette.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  Widget _fetchData() {
    return FutureBuilder<List<ProductModel>>(
      future: dbService.getProducts(),
      builder: (BuildContext context, AsyncSnapshot<List<ProductModel>> products) {
        if (products.hasData) {
          return _buildUI(products.data!);
        }

        return SpinKitFadingCircle(
          color: Palette.blue,
          size: 50.0,
        );
      },
    );
  }

  Widget _buildUI(List<ProductModel> products) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: _buildDataTable(products),
    );
  }

  Widget _buildDataTable(List<ProductModel> model) {
    final currencySymbol = SharedPreferenceHelper.getString(Preferences.currency_symbol).toString();

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: model.length,
      separatorBuilder: (_, __) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = model[index];
        final int price = data.price ?? 0;
        final int quantity = data.quantity ?? 0;
        final int itemTotal = price * quantity;

        return Container(
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Palette.blue.withOpacity(0.06),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            data.productName ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Palette.dark_blue,
                            ),
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          icon: Icon(
                            Icons.clear,
                            color: Palette.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            FormHelper.showMessage(
                              context,
                              getTranslated(context, AppString.AddToCart_removeMedicine_alert_title).toString(),
                              getTranslated(context, AppString.AddToCart_removeMedicine_alert_text).toString(),
                              getTranslated(context, AppString.No).toString(),
                              () {
                                Navigator.of(context).pop();
                              },
                              buttonText2: getTranslated(context, AppString.Yes).toString(),
                              isConfirmationDialog: true,
                              onPressed2: () {
                                loading = true;
                                dbService.deleteProduct(data).then((value) {
                                  setState(() {
                                    loading = false;
                                    getGrandTotal();
                                    Navigator.of(context).pop();
                                  });
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$currencySymbol$price × $quantity',
                      style: TextStyle(
                        fontSize: 13,
                        color: Palette.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${getTranslated(context, AppString.AddToCart_total)}: $currencySymbol$itemTotal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Palette.dark_blue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Palette.blue),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      constraints: BoxConstraints(),
                      onPressed: () {
                        decrease(data);
                      },
                      icon: Icon(Icons.remove, color: Palette.dark_blue),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        quantity.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Palette.dark_blue,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 18,
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      constraints: BoxConstraints(),
                      onPressed: () {
                        increase(data);
                      },
                      icon: Icon(Icons.add, color: Palette.dark_blue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void increase(ProductModel data) {
    setState(
      () {
        if (data.quantity == data.medicineStock) {
          Fluttertoast.showToast(
            msg: getTranslated(context, AppString.AddToCart_outOfStock_toast).toString(),
          );
        } else {
          data.quantity = data.quantity! + 1;
          update(data);
        }
      },
    );
  }

  void decrease(ProductModel data) {
    setState(
      () {
        1 < data.quantity! ? data.quantity = data.quantity! - 1 : data.quantity = 1;
        update(data);
      },
    );
  }

  void update(ProductModel data) {
    if (widget.isEditMode) {
      dbService.updateProduct(data).then(
        (value) {
          setState(
            () {
              getGrandTotal();
            },
          );
        },
      );
    }
  }
}
