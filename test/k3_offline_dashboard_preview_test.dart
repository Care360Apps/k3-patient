import 'dart:io';

import 'package:doctro_patient/diagnostics/k3_startup_diagnostics.dart';
import 'package:doctro_patient/preview/care360_offline_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('design walkthrough is isolated from account and network dependencies', () {
    final preview = File('lib/preview/care360_offline_dashboard.dart')
        .readAsStringSync();
    final signIn = File('lib/Screen/Authentication/SignIn.dart')
        .readAsStringSync();

    expect(signIn, contains("import '../../diagnostics/k3_startup_diagnostics.dart';"));
    expect(signIn, contains('care360-offline-preview-open'));
    expect(signIn, contains('k3OfflineSynthetic &&'));
    expect(signIn, contains('Care360ConnectionError.isOfflinePreview(Apis.baseUrl)'));

    for (final forbidden in [
      'package:dio',
      'package:http',
      'package:firebase_auth',
      'package:cloud_firestore',
      'SharedPreferenceHelper',
      'Preferences.is_logged_in',
      'RetroApi',
      'RestClient(',
      'Navigator.pushNamed(',
    ]) {
      expect(preview, isNot(contains(forbidden)),
          reason: 'A design walkthrough must never access real patient services.');
    }
    expect(preview, contains('if (!k3OfflineSynthetic)'));
  });

  if (k3OfflineSynthetic) {
    testWidgets('isolated dashboard browses care sections without authentication',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(
        home: Care360OfflineDashboard(),
      ));
      expect(find.textContaining('OFFLINE DESIGN PREVIEW'), findsOneWidget);
      expect(find.text('Better care, closer to you.'), findsOneWidget);

      final doctor = find.byKey(const Key('preview-doctors'));
      await tester.ensureVisible(doctor);
      await tester.tap(doctor);
      await tester.pumpAndSettle();
      expect(find.text('Patient experience to review'), findsOneWidget);
      expect(find.text('Electronic prescriptions'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Bookings'));
      await tester.pumpAndSettle();
      expect(find.text('No appointments in design preview'), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Sample patient profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  } else {
    testWidgets('preview is blocked in normal debug and release builds',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Care360OfflineDashboard(),
      ));
      expect(find.text('Offline design review is unavailable.'),
          findsOneWidget);
      expect(find.text('Better care, closer to you.'), findsNothing);
    });
  }
}
