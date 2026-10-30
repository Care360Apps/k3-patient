import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/model/medicine_order_detail_model.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../AppointmentRelatedScreen/Bookappointment.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../localization/localization_constant.dart';

class MedicineOrderDetail extends StatefulWidget {
  final int? orderId;
  final String? pharmacyName;
  final String? pharmacyAddress;

  MedicineOrderDetail({
    this.orderId,
    this.pharmacyName,
    this.pharmacyAddress,
  });

  @override
  _MedicineOrderDetailState createState() => _MedicineOrderDetailState();
}

class _MedicineOrderDetailState extends State<MedicineOrderDetail> {
  bool loading = false;

  String? paymentType = "";
  String? date = "";
  String? deliverTo = "";
  num? totalAmount = 0;
  int? deliveryCharge = 0;
  String? bookOrderId = "";

  num? grandTotal = 0;
  String newDate = "";
  int medicineAmountTotal = 0;

  List<MedicineName>? bookMedicineList = [];

  @override
  void initState() {
    super.initState();
    callApiMedicineOrderDetail();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
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
          getTranslated(context, AppString.medicineOrderDetail_orderSummary).toString(),
          style: TextStyle(fontSize: 20, color: Palette.dark_blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.5,
        progressIndicator: SpinKitFadingCircle(
          color: Palette.blue,
          size: 50.0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pharmacy card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        widget.pharmacyName ?? '',
                        style: const TextStyle(fontSize: 18, color: Palette.blue, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.pharmacyAddress ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Palette.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Order items card
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
                        getTranslated(context, AppString.medicineOrderDetail_yourOrder).toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Palette.dark_blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        itemCount: bookMedicineList!.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          medicineAmountTotal = bookMedicineList![index].qty! * bookMedicineList![index].price!;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bookMedicineList![index].name ?? '',
                                      style: const TextStyle(fontSize: 15, color: Palette.blue, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${bookMedicineList![index].qty} × ${SharedPreferenceHelper.getString(Preferences.currency_symbol)}${bookMedicineList![index].price}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Palette.dark_blue,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${SharedPreferenceHelper.getString(Preferences.currency_symbol)}$medicineAmountTotal',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Palette.dark_blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Divider(color: Palette.dark_white, thickness: 1),
                      const SizedBox(height: 6),
                      _buildAmountRow(
                        label: getTranslated(context, AppString.medicineOrderDetail_totalAmount).toString(),
                        value: '${SharedPreferenceHelper.getString(Preferences.currency_symbol)}$totalAmount',
                        width: width,
                      ),
                      const SizedBox(height: 4),
                      _buildAmountRow(
                        label: getTranslated(context, AppString.medicineOrderDetail_deliveryCharge).toString(),
                        value: deliveryCharge != null
                            ? '${SharedPreferenceHelper.getString(Preferences.currency_symbol)}$deliveryCharge'
                            : '${SharedPreferenceHelper.getString(Preferences.currency_symbol)}0',
                        width: width,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Palette.dark_white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildAmountRow(
                          label: getTranslated(context, AppString.medicineOrderDetail_grandTotal).toString(),
                          value: '${SharedPreferenceHelper.getString(Preferences.currency_symbol)}$grandTotal',
                          width: width,
                          isEmphasized: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Order detail card
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
                        getTranslated(context, AppString.medicineOrderDetail_orderDetail).toString(),
                        style: const TextStyle(fontSize: 16, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        title: getTranslated(context, AppString.medicineOrderDetail_orderNumber).toString(),
                        value: '$bookOrderId',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        title: getTranslated(context, AppString.medicineOrderDetail_payment).toString(),
                        value: '$paymentType',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        title: getTranslated(context, AppString.medicineOrderDetail_date).toString(),
                        value: '$newDate',
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        title: getTranslated(context, AppString.medicineOrderDetail_deliverTo).toString(),
                        value: '$deliverTo',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<MedicineOrderDetails>> callApiMedicineOrderDetail() async {
    MedicineOrderDetails response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).medicineOrderDetailRequest(widget.orderId);
      setState(() {
        loading = false;
        if (response.success == true) {
          setState(
            () {
              loading = false;
              paymentType = response.data!.paymentType;
              date = response.data!.createdAt;
              deliverTo = response.data!.shippingAt;
              totalAmount = num.parse(response.data!.amount.toString());
              deliveryCharge = response.data!.deliveryCharge;
              bookOrderId = response.data!.medicineId;
              bookMedicineList = response.data!.medicineName;

              if (deliveryCharge != null) {
                grandTotal = totalAmount! + deliveryCharge!;
              } else {
                grandTotal = totalAmount;
              }
              newDate = DateUtil().formattedDate(DateTime.parse(date!));
            },
          );
        } else {
          setState(() {
            loading = false;
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

  Widget _buildAmountRow({required String label, required String value, required double width, bool isEmphasized = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w600,
            color: Palette.dark_blue,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isEmphasized ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isEmphasized ? Palette.blue : Palette.dark_blue,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Palette.blue, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Palette.grey,
          ),
        ),
      ],
    );
  }
}
