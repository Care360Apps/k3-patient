import 'package:doctro_patient/model/providers_model.dart';

class ProviderDetailResponse {
  bool? success;
  ProviderDetailData? data;
  String? msg;

  ProviderDetailResponse({this.success, this.data, this.msg});

  ProviderDetailResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? ProviderDetailData.fromJson(json['data']) : null;
    msg = json['msg'];
  }
}

class ProviderDetailData {
  int? id;
  String? name;
  String? image;
  String? fullImage;
  String? desc;
  String? appointmentFees;
  num? hourlyRate;
  String? address;
  String? experience;
  dynamic rate;
  int? review;
  String? education;
  String? certificate;
  ProviderTypeLite? providerType;
  List<ProviderReviewItem>? reviews;
  String? distanceKm;

  ProviderDetailData({
    this.id,
    this.name,
    this.image,
    this.fullImage,
    this.desc,
    this.appointmentFees,
    this.hourlyRate,
    this.address,
    this.experience,
    this.rate,
    this.review,
    this.education,
    this.certificate,
    this.providerType,
    this.reviews,
    this.distanceKm,
  });

  ProviderDetailData.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    image = json['image'];
    fullImage = json['fullImage'];
    desc = json['desc'];
    appointmentFees = json['appointment_fees']?.toString();
    hourlyRate = json['hourly_rate'] != null ? num.tryParse(json['hourly_rate'].toString()) : null;
    address = json['address'];
    experience = json['experience']?.toString();
    rate = json['rate'] != null ? int.tryParse(json['rate'].toString()) : null;
    review = json['review'] != null ? int.tryParse(json['review'].toString()) : null;
    education = json['education'];
    certificate = json['certificate'];
    providerType = json['provider_type'] != null ? ProviderTypeLite.fromJson(json['provider_type']) : null;
    if (json['reviews'] != null) {
      reviews = <ProviderReviewItem>[];
      json['reviews'].forEach((v) {
        reviews!.add(ProviderReviewItem.fromJson(v));
      });
    }
    distanceKm = json['distance_km']?.toString();
  }
}

class ProviderReviewItem {
  int? id;
  String? review;
  int? rate;
  ProviderReviewUser? user;

  ProviderReviewItem({this.id, this.review, this.rate, this.user});

  ProviderReviewItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    review = json['review']?.toString();
    rate = json['rate'] != null ? int.tryParse(json['rate'].toString()) : null;
    user = json['user'] != null ? ProviderReviewUser.fromJson(json['user']) : null;
  }
}

class ProviderReviewUser {
  int? id;
  String? name;
  String? image;

  ProviderReviewUser({this.id, this.name, this.image});

  ProviderReviewUser.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    image = json['image'];
  }
}
