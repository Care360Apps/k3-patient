import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/workforce/workforce_landing.dart';

void main() {
  testWidgets('Workforce has discoverable candidate and hospital hiring journeys',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Care360WorkforceLanding(pilotEnabled: false)),
    );
    expect(find.text('Join Workforce'), findsOneWidget);
    expect(find.text('Hire Workforce'), findsOneWidget);
    expect(find.textContaining('not yet open'), findsOneWidget);

    await tester.tap(find.byKey(const Key('workforce-join')));
    await tester.pumpAndSettle();
    expect(find.text('Workforce applications are not open yet'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('workforce-hire')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No credentials or contact'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Patient home service tile opens Workforce when tapped',
      (tester) async {
    var opens = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: Care360WorkforceHomeTile(onTap: () => opens++),
    )));
    expect(find.text('Workforce'), findsOneWidget);
    expect(find.textContaining('Verified healthcare talent'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home-workforce')));
    expect(opens, 1);
  });

  testWidgets('Workforce preview stays readable on narrow devices',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 650));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Care360WorkforceLanding(pilotEnabled: false),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workforce-join')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Workforce is a distinct role-scoped API, never clinical bearer auth', () {
    final home = File('lib/Screen/Screens/Home.dart').readAsStringSync();
    final api = File('lib/workforce/workforce_api.dart').readAsStringSync();
    final access = File('lib/workforce/workforce_access_screen.dart')
        .readAsStringSync();
    final dashboard = File('lib/workforce/workforce_dashboard.dart')
        .readAsStringSync();
    expect(home, contains("import '../../workforce/workforce_landing.dart';"));
    expect(home, contains("Key('drawer-workforce')"));
    expect(home, contains('Care360WorkforceHomeTile('));
    expect(api, contains("static const tokenKey = 'care360_workforce_session'"));
    expect(api, isNot(contains('Preferences.auth_token')));
    expect(api, isNot(contains('RetroApi().dioData()')));
    expect(api, isNot(contains('FirebaseFirestore')));
    expect(api, contains("workforce/v1/candidates"));
    expect(access, contains('adultAttestation'));
    expect(access, contains('acceptedTerms'));
    expect(dashboard, contains("'consent_to_list': _consentToList"));
    expect(dashboard, isNot(contains('MedicalFile')));
  });
}
