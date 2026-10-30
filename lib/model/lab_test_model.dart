class LabTestResponse {
  bool? success;
  List<LabTestItem>? data;
  String? msg;

  LabTestResponse({this.success, this.data, this.msg});

  LabTestResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(new LabTestItem.fromJson(v));
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

class LabTestItem {
  int? id;
  String? name;
  String? charge;

  LabTestItem({this.id, this.name, this.charge});

  LabTestItem.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null ? int.tryParse(json['id'].toString()) : null;
    name = json['test_name'] ?? json['screening_for'] ?? json['name'];
    charge = json['charge']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['charge'] = this.charge;
    return data;
  }
}
