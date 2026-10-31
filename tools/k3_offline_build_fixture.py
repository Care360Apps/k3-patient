#!/usr/bin/env python3
"""Prepare synthetic-only Android CI compile configuration, never real K3 services.

Generates throwaway Firebase metadata and a .invalid API endpoint in the
temporary runner checkout only. Debug APK receives a distinct package ID.
Never use such builds for clinical/user acceptance or payments.
"""
import json
import os
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
gradle = root / 'android/app/build.gradle'
text = gradle.read_text()
match = re.search(r'(?m)^\s*applicationId\s+["\'](com\.cnu\.(?:patient|doctor))["\']', text)
if not match:
    sys.exit('Expected K3 Android applicationId missing or changed')
package = match.group(1)
if 'applicationIdSuffix' in text:
    sys.exit('Existing app ID suffix present: inspect build setup manually')
needle = '    buildTypes {\n'
if text.count(needle) != 1:
    sys.exit('Cannot add offline-only debug application suffix safely')
text = text.replace(needle, needle + '        debug {\n            applicationIdSuffix ".k3sandbox"\n        }\n', 1)
gradle.write_text(text)

manifest = root / 'android/app/src/main/AndroidManifest.xml'
xml = manifest.read_text()
label_match = re.search(r'android:label="[^"]+"', xml)
if not label_match:
    sys.exit('Missing Android application label')
xml = xml[:label_match.start()] + 'android:label="K3 OFFLINE TEST"' + xml[label_match.end():]
manifest.write_text(xml)

firebase = {
    'project_info': {
        'project_number': '123456789012',
        'project_id': 'k3-synthetic-build-invalid',
        'storage_bucket': 'k3-synthetic-build-invalid.invalid',
    },
    'client': [{
        'client_info': {
            'mobilesdk_app_id': '1:123456789012:android:0123456789abcdef01234567',
            'android_client_info': {'package_name': package + '.k3sandbox'},
        },
        'api_key': [{'current_key': 'k3-synthetic-not-a-valid-firebase-key'}],
    }],
    'configuration_version': '1',
}
path = root / 'android/app/google-services.json'
if path.exists():
    sys.exit('Refusing to overwrite existing Firebase config')
path.write_text(json.dumps(firebase, indent=2))
config = {
    'K3_API_BASE_URL': 'https://k3-offline.invalid/api/',
    'K3_FIREBASE_API_KEY': 'k3-synthetic-not-a-valid-firebase-key',
    'K3_FIREBASE_APP_ID': '1:123456789012:android:0123456789abcdef01234567',
    'K3_FIREBASE_SENDER_ID': '123456789012',
    'K3_FIREBASE_PROJECT_ID': 'k3-synthetic-build-invalid',
    'K3_FIREBASE_STORAGE_BUCKET': 'k3-synthetic-build-invalid.invalid',
}
config_path = Path(os.environ.get('RUNNER_TEMP', '/tmp')) / 'k3_offline_dart_defines.json'
config_path.write_text(json.dumps(config))
config_path.chmod(0o600)
print('OFFLINE SYNTHETIC CONFIG: no production/staging Firebase or API used')
print('Debug Android ID:', package + '.k3sandbox')
print('Use only for offline installation/compile checks; NOT clinical testing')

# Synthetic smoke-test build: replace startup entrypoint only in the ephemeral
# CI checkout. The actual app source and production build remain untouched.
# A fully isolated UI is required: dummy Firebase must never block runApp().
preview_main = "import 'package:flutter/material.dart';\n\nvoid main() {\n  WidgetsFlutterBinding.ensureInitialized();\n  runApp(const OfflineCare360Preview());\n}\n\nclass OfflineCare360Preview extends StatelessWidget {\n  const OfflineCare360Preview({super.key});\n\n  @override\n  Widget build(BuildContext context) {\n    return MaterialApp(\n      debugShowCheckedModeBanner: false,\n      title: 'Care360 Offline Preview',\n      theme: ThemeData(\n        useMaterial3: true,\n        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1765B3)),\n      ),\n      home: const PreviewHome(),\n    );\n  }\n}\n\nclass PreviewHome extends StatefulWidget {\n  const PreviewHome({super.key});\n\n  @override\n  State<PreviewHome> createState() => _PreviewHomeState();\n}\n\nclass _PreviewHomeState extends State<PreviewHome> {\n  int selected = 0;\n  static const sections = <String>['Overview', 'Appointments', 'Doctors', 'Profile'];\n  static const icons = <IconData>[\n    Icons.dashboard_outlined, Icons.calendar_month_outlined,\n    Icons.medical_services_outlined, Icons.person_outline,\n  ];\n\n  @override\n  Widget build(BuildContext context) {\n    return Scaffold(\n      appBar: AppBar(title: const Text('Care360 Patient'), centerTitle: false),\n      body: SafeArea(\n        child: ListView(\n          padding: const EdgeInsets.all(20),\n          children: [\n            Container(\n              padding: const EdgeInsets.all(14),\n              decoration: BoxDecoration(\n                color: const Color(0xFFFFF3CD),\n                borderRadius: BorderRadius.circular(12),\n              ),\n              child: const Text(\n                'OFFLINE UI PREVIEW ONLY — Synthetic test build. No real accounts, '\n                'appointments, medical advice, payments or patient records.',\n                style: TextStyle(fontWeight: FontWeight.w600),\n              ),\n            ),\n            const SizedBox(height: 24),\n            Text(sections[selected], style: Theme.of(context).textTheme.headlineMedium),\n            const SizedBox(height: 10),\n            const Text('This is a safe navigation and visual smoke test, not the live Care360 application.'),\n            const SizedBox(height: 24),\n            Card(\n              child: Padding(\n                padding: const EdgeInsets.all(20),\n                child: Column(\n                  crossAxisAlignment: CrossAxisAlignment.start,\n                  children: [\n                    Icon(icons[selected], size: 38),\n                    const SizedBox(height: 12),\n                    Text('${sections[selected]} preview', style: Theme.of(context).textTheme.titleLarge),\n                    const SizedBox(height: 8),\n                    const Text('Service data and interactive clinical workflows are intentionally unavailable in this build.'),\n                  ],\n                ),\n              ),\n            ),\n          ],\n        ),\n      ),\n      bottomNavigationBar: NavigationBar(\n        selectedIndex: selected,\n        onDestinationSelected: (index) => setState(() => selected = index),\n        destinations: [\n          for (var i = 0; i < sections.length; i++)\n            NavigationDestination(icon: Icon(icons[i]), label: sections[i]),\n        ],\n      ),\n    );\n  }\n}\n"
# Use the original Care360 onboarding screen in the offline preview while
# redirecting its completion action to the isolated preview dashboard.
# Do not initialize Firebase, auth, or production services.
onboarding_path = root / 'lib/Screen/Onboarding/Onboarding.dart'
onboarding_source = onboarding_path.read_text()
onboarding_source = onboarding_source.replace(
    "import '../Authentication/SignIn.dart';",
    "import '../../offline_preview_home.dart';",
)
onboarding_source = onboarding_source.replace(
    'await SharedPreferenceHelper.setBoolean(Preferences.onboarding_seen, true);',
    '// Offline preview: do not persist authentication or onboarding state.',
)
onboarding_source = onboarding_source.replace(
    'MaterialPageRoute(builder: (_) => SignIn()),',
    'MaterialPageRoute(builder: (_) => const PreviewHome()),',
)
onboarding_path.write_text(onboarding_source)
# The preview's real onboarding is imported from a separate generated Dart file.
preview_main = preview_main.replace(
    "import 'package:flutter/material.dart';",
    "import 'package:flutter/material.dart';\\nimport 'Screen/Onboarding/Onboarding.dart';",
).replace('home: const PreviewHome(),', 'home: const OnboardingScreen(),')
(root / 'lib/offline_preview_home.dart').write_text(
    preview_main.replace('void main() {', 'void previewOnlyUnusedMain() {')
    .replace("import 'Screen/Onboarding/Onboarding.dart';", '')
    .replace('home: const OnboardingScreen(),', 'home: const PreviewHome(),')
)
(root / 'lib/main.dart').write_text(preview_main)
print('OFFLINE PREVIEW: replaced entrypoint in temporary CI checkout; no Firebase startup')
