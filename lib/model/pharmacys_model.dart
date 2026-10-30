class pharmacyModel {
  bool? success;
  List<Data>? data;
  String? msg;

  pharmacyModel({this.success, this.data, this.msg});

  pharmacyModel.fromJson(Map<String, dynamic> json) {
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
  String? name;
  String? image;
  String? address;
  String? description;
  String? fullImage;
  /// Latitude (for distance sort).
  double? lat;
  /// Longitude (for distance sort). API returns as "lang".
  double? lng;
  /// Distance in km from user when lat/lang passed to API.
  String? distanceKm;

  Data({
    this.id,
    this.name,
    this.image,
    this.address,
    this.description,
    this.fullImage,
    this.lat,
    this.lng,
    this.distanceKm,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    image = json['image'];
    address = json['address'];
    description = json['description'];
    fullImage = json['fullImage'];
    lat = json['lat'] != null ? double.tryParse(json['lat'].toString()) : null;
    lng = json['lang'] != null ? double.tryParse(json['lang'].toString()) : null;
    distanceKm = json['distance_km']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image'] = this.image;
    data['address'] = this.address;
    data['description'] = this.description;
    data['fullImage'] = this.fullImage;
    data['lat'] = this.lat;
    data['lang'] = this.lng;
    data['distance_km'] = this.distanceKm;
    return data;
  }
}
