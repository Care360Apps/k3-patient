class DoctorDetailModel {
  bool? success;
  Data? data;
  String? msg;

  DoctorDetailModel({this.success, this.data, this.msg});

  DoctorDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    msg = json['msg'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['msg'] = this.msg;
    return data;
  }
}

class Data {
  int? id;
  int? treatmentId;
  int? categoryId;
  int? expertiseId;
  List<HospitalId>? hospitalId;
  int? userId;
  String? image;
  String? desc;
  String? education;
  String? certificate;
  String? appointmentFees;
  String? experience;
  String? name;
  String? startTime;
  String? endTime;
  int? subscriptionStatus;
  int? isPopular;
  String? commissionAmount;
  dynamic customTimeslot;
  int? isFilled;
  String? language;
  List<Reviews>? reviews;
  String? fullImage;
  dynamic rate;
  int? review;
  Treatment? treatment;
  Expertise? expertise;
  ProviderTypeLite? providerType;
  int? patientVideoCall;
  int? offersVideoCall;
  int? offersHomeVisit;
  num? hourlyRate;

  Data({
    this.id,
    this.treatmentId,
    this.categoryId,
    this.expertiseId,
    this.hospitalId,
    this.userId,
    this.image,
    this.desc,
    this.education,
    this.certificate,
    this.appointmentFees,
    this.experience,
    this.name,
    this.startTime,
    this.endTime,
    this.subscriptionStatus,
    this.isPopular,
    this.commissionAmount,
    this.customTimeslot,
    this.isFilled,
    this.language,
    this.reviews,
    this.fullImage,
    this.rate,
    this.review,
    this.treatment,
    this.expertise,
    this.providerType,
    this.patientVideoCall,
    this.offersVideoCall,
    this.offersHomeVisit,
    this.hourlyRate,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    treatmentId = json['treatment_id'] != null ? int.tryParse(json['treatment_id'].toString()) : null;
    categoryId = json['category_id'] != null ? int.tryParse(json['category_id'].toString()) : null;
    expertiseId = json['expertise_id'] != null ? int.tryParse(json['expertise_id'].toString()) : null;
    if (json['hospital_id'] != null) {
      hospitalId = <HospitalId>[];
      json['hospital_id'].forEach((v) {
        hospitalId!.add(new HospitalId.fromJson(v));
      });
    }
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    image = json['image'];
    desc = json['desc'];
    education = json['education'];
    certificate = json['certificate'];
    appointmentFees = json['appointment_fees'];
    experience = json['experience'];
    name = json['name'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    subscriptionStatus = json['subscription_status'] != null ? int.tryParse(json['subscription_status'].toString()) : null;
    isPopular = json['is_popular'] != null ? int.tryParse(json['is_popular'].toString()) : null;
    commissionAmount = json['commission_amount'];
    customTimeslot = json['custom_timeslot'];
    isFilled = json['is_filled'] != null ? int.tryParse(json['is_filled'].toString()) : null;
    language = json['language'];
    if (json['reviews'] != null) {
      reviews = <Reviews>[];
      json['reviews'].forEach((v) {
        reviews!.add(new Reviews.fromJson(v));
      });
    }
    patientVideoCall = json['patient_vcall'] != null ? int.tryParse(json['patient_vcall'].toString()) : null;
    offersVideoCall = json['offers_video_call'] != null ? int.tryParse(json['offers_video_call'].toString()) : null;
    offersHomeVisit = json['offers_home_visit'] != null ? int.tryParse(json['offers_home_visit'].toString()) : null;
    hourlyRate = json['hourly_rate'] != null ? num.tryParse(json['hourly_rate'].toString()) : null;
    fullImage = json['fullImage'];
    rate = json['rate'] != null ? int.tryParse(json['rate'].toString()) : null;
    review = json['review'] != null ? int.tryParse(json['review'].toString()) : null;
    treatment = json['treatment'] != null ? new Treatment.fromJson(json['treatment']) : null;
    expertise = json['expertise'] != null ? new Expertise.fromJson(json['expertise']) : null;
    providerType = json['provider_type'] != null ? new ProviderTypeLite.fromJson(json['provider_type']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['treatment_id'] = this.treatmentId;
    data['category_id'] = this.categoryId;
    data['expertise_id'] = this.expertiseId;
    if (this.hospitalId != null) {
      data['hospital_id'] = this.hospitalId!.map((v) => v.toJson()).toList();
    }
    data['user_id'] = this.userId;
    data['image'] = this.image;
    data['patient_vcall'] = this.patientVideoCall;
    data['desc'] = this.desc;
    data['education'] = this.education;
    data['certificate'] = this.certificate;
    data['appointment_fees'] = this.appointmentFees;
    data['experience'] = this.experience;
    data['name'] = this.name;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    data['subscription_status'] = this.subscriptionStatus;
    data['is_popular'] = this.isPopular;
    data['commission_amount'] = this.commissionAmount;
    data['custom_timeslot'] = this.customTimeslot;
    data['is_filled'] = this.isFilled;
    data['language'] = this.language;
    if (this.reviews != null) {
      data['reviews'] = this.reviews!.map((v) => v.toJson()).toList();
    }
    data['fullImage'] = this.fullImage;
    data['rate'] = this.rate;
    data['review'] = this.review;
    if (this.treatment != null) {
      data['treatment'] = this.treatment!.toJson();
    }
    if (this.expertise != null) {
      data['expertise'] = this.expertise!.toJson();
    }
    if (this.providerType != null) {
      data['provider_type'] = this.providerType!.toJson();
    }
    return data;
  }
}

class HospitalId {
  String? hospitalDistance;
  HospitalDetails? hospitalDetails;
  List<HospitalGallery>? hospitalGallery;

  HospitalId({this.hospitalDistance, this.hospitalDetails, this.hospitalGallery});

  HospitalId.fromJson(Map<String, dynamic> json) {
    hospitalDistance = json['hospital_distance'];
    hospitalDetails = json['hospital_details'] != null ? new HospitalDetails.fromJson(json['hospital_details']) : null;
    if (json['hospital_gallery'] != null) {
      hospitalGallery = <HospitalGallery>[];
      json['hospital_gallery'].forEach((v) {
        hospitalGallery!.add(new HospitalGallery.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['hospital_distance'] = this.hospitalDistance;
    if (this.hospitalDetails != null) {
      data['hospital_details'] = this.hospitalDetails!.toJson();
    }
    if (this.hospitalGallery != null) {
      data['hospital_gallery'] = this.hospitalGallery!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HospitalDetails {
  int? id;
  String? name;
  String? phone;
  String? address;
  String? facility;

  HospitalDetails({this.id, this.name, this.phone, this.address, this.facility});

  HospitalDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    phone = json['phone'];
    address = json['address'];
    facility = json['facility'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['address'] = this.address;
    data['facility'] = this.facility;
    return data;
  }
}

class HospitalGallery {
  String? image;
  String? fullImage;

  HospitalGallery({this.image, this.fullImage});

  HospitalGallery.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['image'] = this.image;
    data['fullImage'] = this.fullImage;
    return data;
  }
}

class Reviews {
  int? id;
  String? review;
  int? rate;
  int? appointmentId;
  int? doctorId;
  int? userId;
  String? createdAt;
  String? updatedAt;
  User? user;

  Reviews({this.id, this.review, this.rate, this.appointmentId, this.doctorId, this.userId, this.createdAt, this.updatedAt, this.user});

  Reviews.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    review = json['review']?.toString();
    rate = json['rate'] != null ? int.tryParse(json['rate'].toString()) : null;
    appointmentId = json['appointment_id'] != null ? int.tryParse(json['appointment_id'].toString()) : null;
    doctorId = json['doctor_id'] != null ? int.tryParse(json['doctor_id'].toString()) : null;
    userId = json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['review'] = this.review;
    data['rate'] = this.rate;
    data['appointment_id'] = this.appointmentId;
    data['doctor_id'] = this.doctorId;
    data['user_id'] = this.userId;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? image;
  String? fullImage;

  User({this.id, this.name, this.image, this.fullImage});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    image = json['image'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image'] = this.image;
    data['fullImage'] = this.fullImage;
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

class Expertise {
  int? id;
  String? name;

  Expertise({this.id, this.name});

  Expertise.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}

class ProviderTypeLite {
  int? id;
  String? name;

  ProviderTypeLite({this.id, this.name});

  ProviderTypeLite.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    return data;
  }
}
