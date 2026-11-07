import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_entry.dart';

void main() {
  testWidgets('Healthcare login shell is navigable with keyboard on narrow screens',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          viewInsets: EdgeInsets.only(bottom: 260),
          textScaler: TextScaler.linear(1.4),
        ),
        child: Care360AuthShell(
          professional: false,
          child: Column(children: [
            const Text('Patient access'),
            const TextField(
              key: Key('sample-email'),
              decoration: InputDecoration(labelText: 'Email'),
            ),
            const TextField(
              key: Key('sample-password'),
              decoration: InputDecoration(labelText: 'Password'),
            ),
            ElevatedButton(
              key: const Key('sample-signin'),
              onPressed: () {},
              child: const Text('Sign in'),
            ),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Care360 Patient'), findsOneWidget);
    expect(find.byWidgetPredicate((widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName
            .endsWith('care360_family_care.webp')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('sample-signin')));
    await tester.ensureVisible(find.text('CNU Medical Institute'));
    expect(tester.takeException(), isNull);
  });

  test('Redesigned Patient sign-in preserves authentication and account routes',
      () {
    final code = File('lib/Screen/Authentication/SignIn.dart')
        .readAsStringSync();
    for (final key in [
      "Key('care360-signin-email')",
      "Key('care360-signin-password')",
      "Key('care360-signin-submit')",
      "Key('care360-signin-forgot-password')",
      "Key('care360-signin-create-account')",
    ]) {
      expect(code, contains(key));
    }
    expect(code, contains("onPressed: () => Navigator.pushNamed(context, 'SignUp')"));
    expect(code, contains("Navigator.pushNamed(context, 'ForgotPasswordScreen')"));
    expect(code, contains('callForLogin();'));
    expect(code, contains("Navigator.pushReplacementNamed(context, \"Home\")"));
    expect(code, contains("PhoneVerification(id: idValue)"));
    expect(code, contains("Preferences.auth_token"));
    expect(code, isNot(contains('badCertificateCallback')));
    expect(code, isNot(contains('print("Exception occur: $error')));
  });

  test('Patient registration is still present with real branding and original services',
      () {
    final code = File('lib/Screen/Authentication/signup.dart')
        .readAsStringSync();
    expect(code, contains('const Care360Brand(professional: false)'));
    expect(code, contains("Key('care360-signup-submit')"));
    expect(code, contains('callApiRegister();'));
    expect(code, contains('registerRequest(body)'));
    expect(code, contains('PhoneVerification(id: id)'));
    expect(code, contains("Navigator.pushReplacementNamed(context, 'SignIn')"));
    expect(code, contains('const CnuAttribution()'));
    expect(code, isNot(contains('Exception occur: $error')));
  });

  testWidgets('Patient onboarding retains three unique African care photos',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(MaterialApp(
      home: Care360Welcome(professional: false,
        onComplete: () async { finished++; }),
    ));
    await tester.pumpAndSettle();
    for (var step = 0; step < 3; step++) {
      final image = [
        'care360_family_care.webp',
        'care360_appointments.webp',
        'care360_clinician_team.webp',
      ][step];
      expect(find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName.endsWith(image)),
          findsOneWidget);
      if (step < 2) {
        await tester.ensureVisible(find.text('Continue'));
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();
      }
    }
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(finished, 1);
    expect(tester.takeException(), isNull);
  });
}
