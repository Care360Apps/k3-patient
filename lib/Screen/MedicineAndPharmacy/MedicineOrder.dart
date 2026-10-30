import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/AppointmentRelatedScreen/Bookappointment.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/model/medicine_order_model_model.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'MedicineOrderDetail.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../localization/localization_constant.dart';

class MedicineOrder extends StatefulWidget {
  @override
  _MedicineOrderState createState() => _MedicineOrderState();
}

class _MedicineOrderState extends State<MedicineOrder> {
  bool loading = false;
  List<Data> medicineList = [];
  dynamic grandTotal = 0;
  String? date;

  @override
  void initState() {
    super.initState();
    callApiMedicineOrder();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
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
          getTranslated(context, AppString.medicineOrder_title).toString(),
          style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading,
        opacity: 0.5,
        progressIndicator: SpinKitFadingCircle(color: Palette.blue, size: 50.0),
        child: _buildBody(context, width),
      ),
    );
  }

  Widget _buildBody(BuildContext context, double width) {
    if (medicineList.isEmpty) {
      return Center(
        child: Text(
          getTranslated(context, AppString.medicineOrder_orderNotFound).toString(),
          style: TextStyle(fontSize: width * 0.04, color: Palette.grey, fontWeight: FontWeight.bold),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: callApiMedicineOrder,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: medicineList.length,
        itemBuilder: (context, index) => _buildOrderCard(context, index, width),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, int index, double width) {
    date = DateUtil().formattedDate(DateTime.parse(medicineList[index].createdAt!));
    if (medicineList[index].deliveryCharge != null) {
      grandTotal = double.parse(medicineList[index].amount!) + medicineList[index].deliveryCharge!;
    } else {
      grandTotal = medicineList[index].amount;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking ID + Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, AppString.medicineOrder_bookingId).toString() +
                          ' : #${medicineList[index].medicineId}',
                      style: TextStyle(
                        fontSize: width * 0.035,
                        color: Palette.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date',
                      style: TextStyle(fontSize: width * 0.032, color: Palette.grey),
                    ),
                  ],
                ),
                Text(
                  SharedPreferenceHelper.getString(Preferences.currency_symbol).toString() + '$grandTotal',
                  style: TextStyle(
                    fontSize: width * 0.05,
                    color: Palette.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pharmacy image + name + address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: CachedNetworkImage(
                    imageUrl: medicineList[index].pharmacyDetails!.fullImage!,
                    height: 44,
                    width: 44,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => SpinKitFadingCircle(color: Palette.blue),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/no_image.jpg',
                      height: 44,
                      width: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineList[index].pharmacyDetails!.name!,
                        style: TextStyle(
                          fontSize: width * 0.04,
                          color: Palette.dark_blue,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        medicineList[index].pharmacyDetails!.address!,
                        style: TextStyle(fontSize: width * 0.032, color: Palette.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(color: Palette.dark_white, thickness: 1),
            const SizedBox(height: 6),
            // Items label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                getTranslated(context, AppString.medicineOrder_items).toString(),
                style: TextStyle(
                  fontSize: width * 0.035,
                  color: Palette.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: medicineList[index].medicineName!.length,
              itemBuilder: (context, i) {
                final item = medicineList[index].medicineName![i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${item.qty} × ${item.name}',
                    style: TextStyle(fontSize: width * 0.032, color: Palette.dark_blue),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            // Date + View More
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, AppString.medicineOrder_orderedOn).toString(),
                      style: TextStyle(
                        fontSize: width * 0.034,
                        color: Palette.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medicineList[index].shippingAt!,
                      style: TextStyle(fontSize: width * 0.032, color: Palette.dark_blue),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedicineOrderDetail(
                          pharmacyName: medicineList[index].pharmacyDetails!.name,
                          pharmacyAddress: medicineList[index].pharmacyDetails!.address,
                          orderId: medicineList[index].id,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    getTranslated(context, AppString.medicineOrder_viewMore).toString(),
                    style: TextStyle(fontSize: 14, color: Palette.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<BaseModel<MedicineOrderModel>> callApiMedicineOrder() async {
    MedicineOrderModel response;
    setState(() {
      loading = true;
    });
    try {
      response = await RestClient(RetroApi().dioData()).medicineOrderRequest();
      setState(() {
        loading = false;
        if (response.success == true) {
          setState(() {
            loading = false;
            medicineList.clear();
            medicineList.addAll(response.data!.reversed);
          });
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
}
