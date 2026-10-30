class Doctors {
  bool? success;
  List<DoctorModel>? data;
  String? msg;

  Doctors({this.success, this.data, this.msg});

  Doctors.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new DoctorModel.fromJson(v));
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

class DoctorModel {
  int? id;
  int? status;
  String? image;
  String? name;
  int? treatmentId;
  bool? isFavorite;
  String? fullImage;
  Treatment? treatment;
  /// Doctor's address (optional). Set when doctor has own location.
  String? address;
  /// Latitude (doctor's own or nearest hospital). Used for map view.
  double? lat;
  /// Longitude (doctor's own or nearest hospital). Used for map view.
  double? lng;
  /// Average rating value (from backend).
  dynamic rate;
  /// Number of reviews for this doctor.
  int? review;
  /// Precomputed distance in kilometers from user (if provided by API).
  String? distanceKm;

  DoctorModel({
    this.id,
    this.status,
    this.image,
    this.name,
    this.treatmentId,
    this.isFavorite,
    this.fullImage,
    this.treatment,
    this.address,
    this.lat,
    this.lng,
    this.rate,
    this.review,
    this.distanceKm,
  });

  DoctorModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    status = json['status'] != null ? int.tryParse(json['status'].toString()) : null;
    image = json['image'];
    name = json['name'];
    treatmentId = json['treatment_id'] != null ? int.tryParse(json['treatment_id'].toString()) : null;
    isFavorite = json['is_faviroute'];
    fullImage = json['fullImage'];
    treatment = json['treatment'] != null ? new Treatment.fromJson(json['treatment']) : null;
    address = json['address']?.toString();
    lat = json['lat'] != null ? double.tryParse(json['lat'].toString()) : null;
    lng = json['lng'] != null ? double.tryParse(json['lng'].toString()) : null;
    rate = json['rate'];
    review = json['review'] != null ? int.tryParse(json['review'].toString()) : null;
    distanceKm = json['distance_km']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['status'] = this.status;
    data['image'] = this.image;
    data['name'] = this.name;
    data['treatment_id'] = this.treatmentId;
    data['is_faviroute'] = this.isFavorite;
    data['fullImage'] = this.fullImage;
    if (this.treatment != null) {
      data['treatment'] = this.treatment!.toJson();
    }
    data['address'] = this.address;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['rate'] = this.rate;
    data['review'] = this.review;
    data['distance_km'] = this.distanceKm;
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
