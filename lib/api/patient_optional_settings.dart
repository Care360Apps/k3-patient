import 'package:doctro_patient/model/detail_setting_model.dart';

/// Backend settings may be successful even when optional notification settings
/// are absent. Do not let an unconfigured OneSignal ID prevent Patient login.
String? validPatientOneSignalAppId(DetailSetting settings) {
  if (settings.success != true) return null;
  final appId = settings.data?.patientAppId?.trim();
  if (appId == null || appId.isEmpty || appId.toLowerCase() == 'null' ||
      appId.toLowerCase() == 'n_a') {
    return null;
  }
  return appId;
}
