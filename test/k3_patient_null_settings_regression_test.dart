import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/api/patient_optional_settings.dart';
import '../lib/localization/localization_constant.dart';
import '../lib/model/detail_setting_model.dart';

void main() {
  test('optional patient_app_id missing from successful LAN settings', () {
    expect(validPatientOneSignalAppId(DetailSetting(success: true)), isNull);
    expect(validPatientOneSignalAppId(DetailSetting(
      success: true, data: Data(patientAppId: null))), isNull);
    for (final invalid in <String>['', '  ', 'null', 'N_A']) {
      expect(validPatientOneSignalAppId(DetailSetting(
        success: true, data: Data(patientAppId: invalid))), isNull);
    }
  });

  test('OneSignal only starts with a valid app ID from successful settings', () {
    expect(validPatientOneSignalAppId(DetailSetting(
      success: true, data: Data(patientAppId: '  test-app-id  '))), 'test-app-id');
    expect(validPatientOneSignalAppId(DetailSetting(
      success: false, data: Data(patientAppId: 'test-app-id'))), isNull);
  });

  testWidgets('sign-in strings do not crash before localization delegate exists',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Builder(
      builder: (context) => Text(getTranslated(context, 'signIn_welcome') ?? ''),
    )));
    expect(tester.takeException(), isNull);
    expect(find.text('signIn_welcome'), findsOneWidget);
  });
}
