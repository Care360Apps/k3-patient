class MedicineOrderDetails {
  bool? success;
  Data? data;

  MedicineOrderDetails({this.success, this.data});

  MedicineOrderDetails.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  int? id;
  String? medicineId;
  int? userId;
  String? pdf;
  String? amount;
  String? paymentType;
  String? paymentToken;
  int? paymentStatus;
  int? adminCommission;
  int? pharamacyCommission;
  int? pharamacyId;
  String? shippingAt;
  int? addressId;
  int? deliveryCharge;
  String? createdAt;
  String? updatedAt;
  List<MedicineName>? medicineName;

  Data(
      {this.id,
      this.medicineId,
      this.userId,
      this.pdf,
      this.amount,
      this.paymentType,
      this.paymentToken,
      this.paymentStatus,
      this.adminCommission,
      this.pharamacyCommission,
      this.pharamacyId,
      this.shippingAt,
      this.addressId,
      this.deliveryCharge,
      this.createdAt,
      this.updatedAt,
      this.medicineName});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    medicineId = json['medicine_id']?.toString();
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    pdf = json['pdf'];
    amount = json['amount']?.toString();
    paymentType = json['payment_type'];
    paymentToken = json['payment_token'];
    paymentStatus = json['payment_status'] != null ? int.tryParse(json['payment_status'].toString()) : null;
    adminCommission = json['admin_commission'] != null ? int.tryParse(json['admin_commission'].toString()) : null;
    pharamacyCommission = json['pharamacy_commission'] != null ? int.tryParse(json['pharamacy_commission'].toString()) : null;
    pharamacyId = json['pharamacy_id'] != null ? int.tryParse(json['pharamacy_id'].toString()) : null;
    shippingAt = json['shipping_at'];
    addressId = json['address_id'] != null ? int.tryParse(json['address_id'].toString()) : null;
    deliveryCharge = json['delivery_charge'] != null ? int.tryParse(json['delivery_charge'].toString()) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['medicine_name'] != null) {
      medicineName = [];
      json['medicine_name'].forEach((v) {
        medicineName!.add(new MedicineName.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['medicine_id'] = this.medicineId;
    data['user_id'] = this.userId;
    data['pdf'] = this.pdf;
    data['amount'] = this.amount;
    data['payment_type'] = this.paymentType;
    data['payment_token'] = this.paymentToken;
    data['payment_status'] = this.paymentStatus;
    data['admin_commission'] = this.adminCommission;
    data['pharamacy_commission'] = this.pharamacyCommission;
    data['pharamacy_id'] = this.pharamacyId;
    data['shipping_at'] = this.shippingAt;
    data['address_id'] = this.addressId;
    data['delivery_charge'] = this.deliveryCharge;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.medicineName != null) {
      data['medicine_name'] = this.medicineName!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MedicineName {
  int? id;
  int? purchaseMedicineId;
  int? medicineId;
  int? price;
  int? qty;
  String? createdAt;
  String? updatedAt;
  String? name;

  MedicineName({this.id, this.purchaseMedicineId, this.medicineId, this.price, this.qty, this.createdAt, this.updatedAt, this.name});

  MedicineName.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    purchaseMedicineId = json['purchase_medicine_id'] != null ? int.tryParse(json['purchase_medicine_id'].toString()) : null;
    medicineId = json['medicine_id'] != null ? int.tryParse(json['medicine_id'].toString()) : null;
    price = json['price'] != null ? int.tryParse(json['price'].toString()) : null;
    qty = json['qty'] != null ? int.tryParse(json['qty'].toString()) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['purchase_medicine_id'] = this.purchaseMedicineId;
    data['medicine_id'] = this.medicineId;
    data['price'] = this.price;
    data['qty'] = this.qty;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['name'] = this.name;
    return data;
  }
}
