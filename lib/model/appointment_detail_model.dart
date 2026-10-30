import 'appointments_model.dart';

class AppointmentDetailResponse {
  bool? success;
  AppointmentDetailData? data;
  String? msg;

  AppointmentDetailResponse({this.success, this.data, this.msg});

  AppointmentDetailResponse.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    data = json['data'] != null ? AppointmentDetailData.fromJson(json['data']) : null;
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['msg'] = msg;
    return data;
  }
}

class AppointmentDetailData {
  int? id;
  String? appointmentId;
  int? userId;
  int? doctorId;
  String? amount;
  String? paymentType;
  String? appointmentFor;
  String? patientName;
  int? age;
  List<String>? reportImage;
  String? drugEffect;
  String? patientAddress;
  String? phoneNo;
  String? date;
  String? time;
  String? endTime;
  int? durationMinutes;
  int? paymentStatus;
  String? appointmentStatus;
  String? visitType;
  String? illnessInformation;
  String? note;
  String? pdf;
  int? rate;
  int? review;
  int? isInsured;
  String? policyInsurerName;
  String? policyNumber;
  Doctor? doctor;
  Hospital? hospital;

  AppointmentDetailData({
    this.id,
    this.appointmentId,
    this.userId,
    this.doctorId,
    this.amount,
    this.paymentType,
    this.appointmentFor,
    this.patientName,
    this.age,
    this.reportImage,
    this.drugEffect,
    this.patientAddress,
    this.phoneNo,
    this.date,
    this.time,
    this.endTime,
    this.durationMinutes,
    this.paymentStatus,
    this.appointmentStatus,
    this.visitType,
    this.illnessInformation,
    this.note,
    this.pdf,
    this.rate,
    this.review,
    this.isInsured,
    this.policyInsurerName,
    this.policyNumber,
    this.doctor,
    this.hospital,
  });

  factory AppointmentDetailData.fromJson(Map<String, dynamic> json) {
    List<String>? reportList;
    if (json['report_image'] != null && json['report_image'] is List) {
      reportList = (json['report_image'] as List).map((e) => e.toString()).toList();
    }
    return AppointmentDetailData(
      id: json['id'],
      appointmentId: json['appointment_id'],
      userId: json['user_id'],
      doctorId: json['doctor_id'],
      amount: json['amount']?.toString(),
      paymentType: json['payment_type'],
      appointmentFor: json['appointment_for'],
      patientName: json['patient_name'],
      age: json['age'],
      reportImage: reportList,
      drugEffect: json['drug_effect'],
      patientAddress: json['patient_address'],
      phoneNo: json['phone_no'],
      date: json['date'],
      time: json['time'],
      endTime: json['end_time'],
      durationMinutes: json['duration_minutes'],
      paymentStatus: json['payment_status'],
      appointmentStatus: json['appointment_status'],
      visitType: json['visit_type'],
      illnessInformation: json['illness_information'],
      note: json['note'],
      pdf: json['pdf'],
      rate: json['rate'],
      review: json['review'],
      isInsured: json['is_insured'],
      policyInsurerName: json['policy_insurer_name'],
      policyNumber: json['policy_number'],
      doctor: json['doctor'] != null ? Doctor.fromJson(json['doctor']) : null,
      hospital: json['hospital'] != null ? Hospital.fromJson(json['hospital']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['appointment_id'] = appointmentId;
    data['user_id'] = userId;
    data['doctor_id'] = doctorId;
    data['amount'] = amount;
    data['payment_type'] = paymentType;
    data['appointment_for'] = appointmentFor;
    data['patient_name'] = patientName;
    data['age'] = age;
    data['report_image'] = reportImage;
    data['drug_effect'] = drugEffect;
    data['patient_address'] = patientAddress;
    data['phone_no'] = phoneNo;
    data['date'] = date;
    data['time'] = time;
    data['end_time'] = endTime;
    data['duration_minutes'] = durationMinutes;
    data['payment_status'] = paymentStatus;
    data['appointment_status'] = appointmentStatus;
    data['visit_type'] = visitType;
    data['illness_information'] = illnessInformation;
    data['note'] = note;
    data['pdf'] = pdf;
    data['rate'] = rate;
    data['review'] = review;
    data['is_insured'] = isInsured;
    data['policy_insurer_name'] = policyInsurerName;
    data['policy_number'] = policyNumber;
    if (doctor != null) data['doctor'] = doctor!.toJson();
    if (hospital != null) data['hospital'] = hospital!.toJson();
    return data;
  }
}
