import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/workforce/workforce_access_screen.dart';
import 'package:doctro_patient/workforce/workforce_api.dart';
import 'package:doctro_patient/workforce/workforce_data_use_notice.dart';
import 'package:doctro_patient/workforce/workforce_notice_gate.dart';

void main() {
  test('Recruitment notice must use a dedicated HTTPS Care360 URL', () {
    expect(WorkforceNoticeGate.approvedUrl(
      'https://care360apps.com/privacy/workforce'), isNotNull);
    expect(WorkforceNoticeGate.approvedUrl(
      'https://privacy.care360apps.com/workforce'), isNotNull);

    for (final unsafe in [
      '',
      'http://care360apps.com/privacy/workforce',
      'https://care360apps.com/',
      'https://care360apps.com.evil.test/privacy/workforce',
      'https://evil.test/privacy/workforce',
      'https://staff:password@care360apps.com/privacy/workforce',
      'https://care360apps.com/privacy/workforce#accept',
      'https://care360apps.com/privacy/workforce?token=foo',
    ]) {
      expect(WorkforceNoticeGate.approvedUrl(unsafe), isNull, reason: unsafe);
    }
  });

  testWidgets('Applicants see explicit data use and unresolved notice status',
      (tester) async {
    final api = WorkforceApi(dio: Dio(BaseOptions(
      baseUrl: 'https://care360apps.com/api/',
    )));
    await tester.pumpWidget(MaterialApp(home: WorkforceAccessScreen(
      accountType: 'candidate',
      api: api,
    )));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workforce-data-use-notice')), findsOneWidget);
    expect(find.textContaining('Your name, training, qualifications'), findsOneWidget);
    expect(find.textContaining('Workforce does not grant access'), findsOneWidget);

    if (!WorkforceNoticeGate.configured) {
      expect(find.byKey(const Key('workforce-notice-pending')), findsOneWidget);
      // The form uses a lazily constructed ListView. Reach the checkbox
      // and submit controls before reading their widget state.
      await tester.scrollUntilVisible(
        find.byKey(const Key('workforce-terms')), 180,
        scrollable: find.byType(Scrollable).first,
      );
      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('workforce-terms')));
      expect(checkbox.onChanged, isNull);
      await tester.scrollUntilVisible(
        find.byKey(const Key('workforce-submit')), 150,
        scrollable: find.byType(Scrollable).first,
      );
      final submit = tester.widget<ElevatedButton>(
        find.byKey(const Key('workforce-submit')));
      expect(submit.onPressed, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Employers see separate organization data use',
      (tester) async {
    final api = WorkforceApi(dio: Dio(BaseOptions(
      baseUrl: 'https://care360apps.com/api/',
    )));
    await tester.pumpWidget(MaterialApp(home: WorkforceAccessScreen(
      accountType: 'employer',
      api: api,
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your organization details'), findsOneWidget);
    expect(find.textContaining('approved employers may access'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Workforce registration is fail-closed without a notice, independent of pilot flags',
      () async {
    final source = File('lib/workforce/workforce_api.dart').readAsStringSync();
    final access = File('lib/workforce/workforce_access_screen.dart')
        .readAsStringSync();
    expect(source, contains('if (!WorkforceNoticeGate.configured)'));
    expect(source, contains('_requireSecureWorkforceOrigin();'));
    expect(access, contains('WorkforceDataUseNotice('));
    expect(access, contains('_registering && !WorkforceNoticeGate.configured'));
    expect(access, contains('!WorkforceNoticeGate.configured'));

    if (!WorkforceNoticeGate.configured) {
      final api = WorkforceApi(dio: Dio(BaseOptions(
        baseUrl: 'https://care360apps.com/api/',
      )));
      await expectLater(
        api.register(
          name: 'Synthetic Applicant',
          email: 'example@example.test',
          password: 'not-a-live-password',
          accountType: 'candidate',
          adultAttestation: true,
          acceptedTerms: true,
        ),
        throwsA(isA<WorkforceApiException>()),
      );
    }
  });
}
