class LabsModel {
  bool? success;
  List<LabData>? data;
  String? msg;

  LabsModel({this.success, this.data, this.msg});

  LabsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new LabData.fromJson(v));
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

class LabData {
  int? id;
  String? name;
  String? image;
  String? address;
  String? lat;
  String? lng;
  String? fullImage;
  String? description;
  String? email;
  String? phone;
  String? startTime;
  String? endTime;
  List<LabGallery>? labGallery;

  LabData({
    this.id,
    this.name,
    this.image,
    this.address,
    this.lat,
    this.lng,
    this.fullImage,
    this.description,
    this.email,
    this.phone,
    this.startTime,
    this.endTime,
    this.labGallery,
  });

  LabData.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    image = json['image'];
    address = json['address'];
    lat = json['lat'];
    lng = json['lng'];
    fullImage = json['fullImage'];
    description = json['description'];
    email = json['email'];
    phone = json['phone'];
    startTime = json['start_time'];
    endTime = json['end_time'];
    if (json['lab_gallery'] != null) {
      labGallery = <LabGallery>[];
      json['lab_gallery'].forEach((v) {
        labGallery!.add(new LabGallery.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['image'] = this.image;
    data['address'] = this.address;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['fullImage'] = this.fullImage;
    data['description'] = this.description;
    data['email'] = this.email;
    data['phone'] = this.phone;
    data['start_time'] = this.startTime;
    data['end_time'] = this.endTime;
    if (this.labGallery != null) {
      data['lab_gallery'] = this.labGallery!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class LabGallery {
  int? id;
  int? labId;
  String? image;
  String? fullImage;

  LabGallery({this.id, this.labId, this.image, this.fullImage});

  LabGallery.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    labId = json['lab_id'] != null ? int.tryParse(json['lab_id'].toString()) : null;
    image = json['image'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['lab_id'] = this.labId;
    data['image'] = this.image;
    data['fullImage'] = this.fullImage;
    return data;
  }
}

class LabDetailModel {
  bool? success;
  LabData? data;
  String? msg;

  LabDetailModel({this.success, this.data, this.msg});

  LabDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? LabData.fromJson(json['data']) : null;
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

class HospitalsModel {
  bool? success;
  List<HospitalData>? data;
  String? msg;

  HospitalsModel({this.success, this.data, this.msg});

  HospitalsModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new HospitalData.fromJson(v));
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

class HospitalData {
  int? id;
  String? name;
  String? phone;
  String? address;
  String? facility;
  String? lat;
  String? lng;
  List<HospitalGallery>? hospitalGallery;

  HospitalData({
    this.id,
    this.name,
    this.phone,
    this.address,
    this.facility,
    this.lat,
    this.lng,
    this.hospitalGallery,
  });

  HospitalData.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['name'];
    phone = json['phone']?.toString();
    address = json['address'];
    facility = json['facility'];
    lat = json['lat']?.toString();
    lng = json['lng']?.toString();
    if (json['hospital_gallery'] != null) {
      hospitalGallery = <HospitalGallery>[];
      json['hospital_gallery'].forEach((v) {
        hospitalGallery!.add(new HospitalGallery.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['address'] = this.address;
    data['facility'] = this.facility;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    if (this.hospitalGallery != null) {
      data['hospital_gallery'] = this.hospitalGallery!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class HospitalGallery {
  int? id;
  int? hospitalId;
  String? image;
  String? fullImage;

  HospitalGallery({this.id, this.hospitalId, this.image, this.fullImage});

  HospitalGallery.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    hospitalId = json['hospital_id'] != null ? int.tryParse(json['hospital_id'].toString()) : null;
    image = json['image'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['hospital_id'] = this.hospitalId;
    data['image'] = this.image;
    data['fullImage'] = this.fullImage;
    return data;
  }
}

class HospitalDetailModel {
  bool? success;
  HospitalData? data;
  String? msg;

  HospitalDetailModel({this.success, this.data, this.msg});

  HospitalDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? HospitalData.fromJson(json['data']) : null;
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
