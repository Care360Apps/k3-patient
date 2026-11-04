class Providers {
  bool? success;
  List<ProviderModel>? data;
  String? msg;

  Providers({this.success, this.data, this.msg});

  Providers.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = <ProviderModel>[];
      json['data'].forEach((v) {
        data!.add(ProviderModel.fromJson(v));
      });
    }
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['msg'] = msg;
    return data;
  }
}

class ProviderModel {
  int? id;
  String? name;
  String? image;
  String? fullImage;
  String? address;
  double? lat;
  double? lng;
  int? providerTypeId;
  String? appointmentFees;
  num? hourlyRate;
  late bool offersVideoCall;
  late bool offersHomeVisit;
  bool? isFavorite;
  ProviderTypeLite? providerType;
  String? distanceKm;
  /// Average rating value for the provider (from backend).
  dynamic rate;
  /// Total number of reviews for the provider.
  int? review;

  ProviderModel({
    this.id,
    this.name,
    this.image,
    this.fullImage,
    this.address,
    this.lat,
    this.lng,
    this.providerTypeId,
    this.appointmentFees,
    this.hourlyRate,
    this.offersVideoCall = false,
    this.offersHomeVisit = false,
    this.isFavorite,
    this.providerType,
    this.distanceKm,
    this.rate,
    this.review,
  });

  ProviderModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    image = json['image'];
    fullImage = json['fullImage'];
    address = json['address'];
    lat = json['lat'] != null ? double.tryParse(json['lat'].toString()) : null;
    lng = json['lng'] != null ? double.tryParse(json['lng'].toString()) : null;
    providerTypeId = json['provider_type_id'] != null ? int.tryParse(json['provider_type_id'].toString()) : null;
    appointmentFees = json['appointment_fees']?.toString();
    hourlyRate = json['hourly_rate'] != null ? num.tryParse(json['hourly_rate'].toString()) : null;
    offersVideoCall = json['offers_video_call'] == true || json['offers_video_call']?.toString() == '1';
    offersHomeVisit = json['offers_home_visit'] == true || json['offers_home_visit']?.toString() == '1';
    isFavorite = json['is_faviroute'];
    distanceKm = json['distance_km']?.toString();
    providerType = json['provider_type'] != null ? ProviderTypeLite.fromJson(json['provider_type']) : null;
    rate = json['rate'];
    review = json['review'] != null ? int.tryParse(json['review'].toString()) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['image'] = image;
    data['fullImage'] = fullImage;
    data['address'] = address;
    data['lat'] = lat;
    data['lng'] = lng;
    data['provider_type_id'] = providerTypeId;
    data['appointment_fees'] = appointmentFees;
    data['hourly_rate'] = hourlyRate;
    data['offers_video_call'] = offersVideoCall ? 1 : 0;
    data['offers_home_visit'] = offersHomeVisit ? 1 : 0;
    data['is_faviroute'] = isFavorite;
    data['distance_km'] = distanceKm;
    data['rate'] = rate;
    data['review'] = review;
    if (providerType != null) {
      data['provider_type'] = providerType!.toJson();
    }
    return data;
  }
}

class ProviderTypeLite {
  int? id;
  String? name;
  String? icon;
  String? fullImage;

  ProviderTypeLite({this.id, this.name, this.icon, this.fullImage});

  ProviderTypeLite.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    icon = json['icon'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['icon'] = icon;
    data['fullImage'] = fullImage;
    return data;
  }
}

