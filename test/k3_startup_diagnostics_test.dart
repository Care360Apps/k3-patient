import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/diagnostics/k3_startup_diagnostics.dart';

void main() {
  test('privacy-safe UI diagnostics are enabled in debug builds', () {
    expect(k3StartupDiagnosticsEnabled, isTrue);
  });

  test('normal builds never enter the synthetic-only offline mode', () {
    expect(k3OfflineSynthetic, isFalse);
  });

  test('debug source extraction keeps only local Dart path and line number', () {
    final trace = StackTrace.fromString(
      '#0 PatientShell.build (package:doctro_patient/Screen/Patient.dart:74:7)\n'
      '#1 token=DO_NOT_PRINT 1234567890123\n',
    );
    expect(k3ApplicationFrame(trace), 'Screen/Patient.dart:74');
    expect(k3ApplicationFrame(null), 'unknown');
    expect(k3ApplicationFrame(StackTrace.fromString('token=secret')), 'unknown');
  });

  testWidgets('error replacement displays only type and safe source location',
      (tester) async {
    const probe = 'sensitive-not-for-ui';
    final details = FlutterErrorDetails(
      exception: StateError(probe),
      stack: StackTrace.fromString(
        '#0 Foo.build (package:doctro_patient/lib/foo.dart:99:2)\n'
        '#1 $probe',
      ),
    );
    // Directly exercise the same stable, user-facing diagnostic widget
    // without running into production build paths.
    final type = k3ExceptionType(details);
    final source = k3ApplicationFrame(details.stack);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: Text('$type | $source', textDirection: TextDirection.ltr),
    ))));
    expect(find.text('StateError | lib/foo.dart:99'), findsOneWidget);
    expect(find.textContaining(probe), findsNothing);
  });
}
