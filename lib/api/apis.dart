class Apis {

  /// TODO Setup: Enter your base url here, Make sure you have added a "/" at the end of the URL
  /// Make sure wether you are using http or https
  /// Make sure wether you need /public/ in the base URL or not
  /// After changing here, also change in the [network_api.g.dart] file
  /// if that file doesn't exist, run the following command in the project terminal
  // TODO Setup: Enter your base URL here then run following command from project terminal:
  // dart run build_runner build --delete-conflicting-outputs

  // Must be supplied explicitly for each environment; no production fallback.
  static const String baseUrl = String.fromEnvironment('K3_API_BASE_URL', defaultValue: 'http://127.0.0.1:9/api/'); // Don't remove /api/

  
  static const String login = "login";
  static const String register = "register";
  static const String doctors_list = "doctors";
  static const String doctor_detail = "doctor_details/{id}";
  static const String providers = "providers";
  static const String provider_detail = "provider_details/{id}";
  static const String healthTip = "blogs";
  static const String healthTip_detail = "blog_details/{id}";
  static const String treatment_list = "treatments";
  static const String book_appointment_list = "appointments";
  static const String appointment_details = "appointment_details/{id}";
  static const String complete_appointment = "complete_appointment";
  static const String medicine_detail = "medicine_details/{id}";
  static const String user_book_appointment = "book_appointment";
  static const String check_otp = "check_otp";
  static const String timeSlot = "timeslot";
  static const String add_address = "add_address";
  static const String show_address = "address";
  static const String delete_address = "delete_address/{id}";
  static const String user_detail = "user";
  static const String setting = "setting";
  static const String all_pharamacy = "pharamacies";
  static const String pharamacy_detail = "pharmacy_details/{id}";
  static const String labs = "labs";
  static const String lab_detail = "lab_details/{id}";
  static const String hospitals = "public_hospitals";
  static const String hospital_detail = "public_hospital_details/{id}";
  static const String lab_pathology = "lab_pathology/{id}";
  static const String lab_radiology = "lab_radiology/{id}";
  static const String lab_timeslot = "lab_timeslot";
  static const String lab_book = "lab_book";
  static const String book_medicine = "book_medicine";
  static const String add_review = "add_review";
  static const String cancel_appointment = "cancel_appointment";
  static const String medicine_order_list = "medicines";
  static const String update_profile = "update_profile";
  static const String medicine_order_detail = "single_medicine/{id}";
  static const String offer = "offers";
  static const String courses = "courses";
  static const String treatmentWise_doctor = "treatment_wise_doctor/{id}";
  static const String update_image = "update_image";
  static const String user_notification = "user_notification";
  static const String banner = "banner";
  static const String add_favorite_doctor = "add_bookmark/{id}";
  static const String show_favorite_doctor = "faviroute_doctor";
  static const String forgot_password = "forgot_password";
  static const String apply_offer = "check_offer";
  static const String change_password = "doctor_change_password";
  static const String resend_otp = "resendOtp/{id}";
  static const String prescription = "prescription/{id}";
  static const String videoCallToken = "generateAgoraToken";
  static const String AddVideoCallHistory = "add_call_history";
  static const String ShowVideoCallHistory = "video_call_history";
  static const String deleteAccount = "delete-account";
  static const String refresh_token = "refresh_token";
  static const String insurers="insurers";
}
