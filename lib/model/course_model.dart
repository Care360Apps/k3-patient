class CoursesResponse {
  bool? success;
  List<CourseData>? data;
  String? msg;

  CoursesResponse({this.success, this.data, this.msg});

  CoursesResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new CourseData.fromJson(v));
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

class CourseData {
  int? id;
  String? title;
  String? summary;
  String? details;
  String? image;
  String? duration;
  num? amount;
  String? link;
  String? fullImage;

  CourseData({this.id, this.title, this.summary, this.details, this.image, this.duration, this.amount, this.link, this.fullImage});

  CourseData.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    title = json['title'];
    summary = json['summary'];
    details = json['details'];
    image = json['image'];
    duration = json['duration'];
    amount = _parseAmount(json['amount']);
    link = json['link'];
    fullImage = json['fullImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['title'] = this.title;
    data['summary'] = this.summary;
    data['details'] = this.details;
    data['image'] = this.image;
    data['duration'] = this.duration;
    data['amount'] = this.amount;
    data['link'] = this.link;
    data['fullImage'] = this.fullImage;
    return data;
  }

  num? _parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value.trim());
    }
    return null;
  }
}
