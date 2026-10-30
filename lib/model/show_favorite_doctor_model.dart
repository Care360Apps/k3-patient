class ShowFavoriteDoctor {
  bool? success;
  List<Data>? data;
  String? msg;

  ShowFavoriteDoctor({this.success, this.data, this.msg});

  ShowFavoriteDoctor.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['msg'] = this.msg;
    return data;
  }
}

class Data {
  int? id;
  int? status;
  String? image;
  String? name;
  int? treatmentId;
  bool? isFaviroute;
  String? fullImage;
  Treatment? treatment;
  String? address;
  double? lat;
  double? lng;
  dynamic rate;
  int? review;

  Data({
    this.id,
    this.status,
    this.image,
    this.name,
    this.treatmentId,
    this.isFaviroute,
    this.fullImage,
    this.treatment,
    this.address,
    this.lat,
    this.lng,
    this.rate,
    this.review,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    status = json['status'] != null ? int.tryParse(json['status'].toString()) : null;
    image = json['image'];
    name = json['name'];
    treatmentId = json['treatment_id'] != null ? int.tryParse(json['treatment_id'].toString()) : null;
    isFaviroute = json['is_faviroute'];
    fullImage = json['fullImage'];
    treatment = json['treatment'] != null ? new Treatment.fromJson(json['treatment']) : null;
    address = json['address']?.toString();
    lat = json['lat'] != null ? double.tryParse(json['lat'].toString()) : null;
    lng = json['lng'] != null ? double.tryParse(json['lng'].toString()) : null;
    rate = json['rate'];
    review = json['review'] != null ? int.tryParse(json['review'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['status'] = this.status;
    data['image'] = this.image;
    data['name'] = this.name;
    data['treatment_id'] = this.treatmentId;
    data['is_faviroute'] = this.isFaviroute;
    data['fullImage'] = this.fullImage;
    if (this.treatment != null) {
      data['treatment'] = this.treatment!.toJson();
    }
    data['address'] = this.address;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['rate'] = this.rate;
    data['review'] = this.review;
    return data;
  }
}

class Treatment {
  int? id;
  String? name;
  String? fullImage;

  Treatment({this.id, this.name, this.fullImage});

  Treatment.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['fullImage'] = this.fullImage;
    return data;
  }
}
