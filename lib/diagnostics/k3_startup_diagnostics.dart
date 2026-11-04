import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug-only, opt-in UI diagnostics for the private LAN test APK.
/// No exception values, app state, credentials, or patient details are logged.
const bool k3StartupDiagnosticsEnabled =
    kDebugMode && bool.fromEnvironment('K3_STARTUP_DIAGNOSTICS');

/// Return only a local source path and line number from application stack frames.
/// The full exception and stack can contain sensitive runtime values.
String k3ApplicationFrame(StackTrace? trace) {
  if (trace == null) return 'unknown';
  final matcher = RegExp(
    r'(?:package:doctro_patient/|\blib/)([A-Za-z0-9_./-]+\.dart):(\d+)',
  );
  final match = matcher.firstMatch(trace.toString());
  if (match == null) return 'unknown';
  return '${match.group(1)}:${match.group(2)}';
}

String k3ExceptionType(FlutterErrorDetails details) =>
    details.exception.runtimeType.toString().replaceAll(
        RegExp(r'[^A-Za-z0-9_]'), '');

/// Install only in disposable LAN debug builds. Production remains unchanged.
void installK3StartupDiagnostics() {
  if (!k3StartupDiagnosticsEnabled) return;

  FlutterError.onError = (details) {
    debugPrint('K3_UI_FAILURE type=${k3ExceptionType(details)} '
        'location=${k3ApplicationFrame(details.stack)}');
  };

  ErrorWidget.builder = (details) {
    final type = k3ExceptionType(details);
    final source = k3ApplicationFrame(details.stack);
    // Don't display exception messages, server responses, tokens or user data.
    return ColoredBox(
      color: const Color(0xFFF4F9F6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Care360 test build: a screen could not be displayed.\n\n'
            'Error type: $type\n'
            'Application location: $source\n\n'
            'Please send a screenshot of this message.',
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Color(0xFF153D33)),
          ),
        ),
      ),
    );
  };
}

void k3ReportInitialRoute(String route) {
  if (k3StartupDiagnosticsEnabled) {
    debugPrint('K3_UI_ROUTE $route');
  }
}
