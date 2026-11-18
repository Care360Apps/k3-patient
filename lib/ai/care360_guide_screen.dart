import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/apis.dart';
import '../const/prefConstatnt.dart';
import '../const/preference.dart';
import '../diagnostics/k3_startup_diagnostics.dart';

/// Nonclinical platform-navigation guidance only.
///
/// The review build and all default production builds are CURATED / OFFLINE.
/// Server-assisted responses require an explicit compile-time pilot flag,
/// verified HTTPS backend, signed-in user and affirmative, per-session opt-in.
/// Patient symptoms, prompts, chats, appointments and medical records are never
/// read or placed in requests. No model credentials exist in the Flutter app.
class Care360GuideScreen extends StatefulWidget {
  const Care360GuideScreen({
    super.key,
    this.allowRemote = false,
    this.languageCode,
  });

  final bool allowRemote;
  final String? languageCode;

  @override
  State<Care360GuideScreen> createState() => _Care360GuideScreenState();
}

class _Care360GuideScreenState extends State<Care360GuideScreen> {
  static const _pilotEnabled =
      bool.fromEnvironment('K3_AI_GUIDE_PILOT', defaultValue: false);
  static const _ink = Color(0xFF17334C);
  static const _green = Color(0xFF08785E);

  static const topics = <String, ({String label, String answer, IconData icon})>{
    'get_started': (
      label: 'Getting started',
      answer: 'Use Care360 Patient to find care, manage appointments and access supported services.\n\n'
          '1. Choose your preferred language on the welcome or sign-in screen.\n\n'
          '2. Tap Sign Up if you are new. Enter your own contact details, create a password and complete the verification requested by the app. Already registered? Use Sign In instead.\n\n'
          '3. After signing in, use Select Address to add a location when a service needs it. Give the address a recognisable label and check it before saving.\n\n'
          '4. Explore the dashboard: Hospitals, Doctors, Providers, Pharmacies, Laboratories and Appointments. Open a category to see available options. Availability depends on your location and the service setup.\n\n'
          '5. Open the menu for your account and Settings. Review your details and privacy information before using a service.\n\n'
          '6. If you cannot sign in, use Forgot Password rather than creating a duplicate account. A local test build needs its test server running; an offline preview cannot sign in.',
      icon: Icons.how_to_reg_outlined,
    ),
    'appointments': (
      label: 'Booking appointments',
      answer: 'Book only after checking the professional, appointment details and any stated charge.\n\n'
          '1. Sign in and open Doctors, or search for a doctor from the dashboard. You can also explore the supported care categories.\n\n'
          '2. Select a professional and read the profile, speciality, location and available appointment options. Do not assume that every listed professional offers video consultations.\n\n'
          '3. Choose an available date, time and consultation option. Check the displayed time carefully. If no slot is available, choose another date or professional.\n\n'
          '4. Review the booking summary, patient details, location and displayed fee before continuing. Provide only the information requested for the appointment.\n\n'
          '5. If payment is required, use the supported checkout. Wait for confirmation; do not submit another payment while the first result is uncertain.\n\n'
          '6. Open Appointments to confirm the booking status and review its details. A payment attempt or loading screen alone is not a confirmed appointment.\n\n'
          '7. For changes or cancellation, open that appointment and review the options and any stated conditions. For a supported video appointment, open its call option at the appropriate time and allow camera or microphone only when needed.\n\n'
          '8. If confirmation is missing or a payment result is unclear, check Appointments first, then contact the service support shown in the app. Do not share your password or payment PIN.',
      icon: Icons.event_available_outlined,
    ),
    'account': (
      label: 'Account and settings',
      answer: 'Keep your account details and device preferences up to date.\n\n'
          '1. Open the dashboard menu, then choose your profile or Settings. Review the details attached to your account before making changes.\n\n'
          '2. Edit supported profile fields and save. Check that the updated information appears when you return.\n\n'
          '3. Use Select Address to manage a location for supported services. Check the map or search result and the written address; do not save an incorrect location.\n\n'
          '4. Use the language control to choose the interface language. Some guide content may still be in English.\n\n'
          '5. Enable notifications from Settings if you want supported reminders. Camera, microphone and location permissions should be requested only when you use the related feature.\n\n'
          '6. For a forgotten password, return to Sign In and use Forgot Password. Follow verification instructions using your registered contact details.\n\n'
          '7. Review the privacy information before requesting account deletion. Read the confirmation carefully: deletion can affect access to your account and associated services.\n\n'
          '8. Use Log Out on a shared device. Never give another person your password, verification code or payment PIN.',
      icon: Icons.manage_accounts_outlined,
    ),
    'partners': (
      label: 'Partner services',
      answer: 'Partner services are separate from the core Care360 appointment flow.\n\n'
          '1. Scroll to Explore partner services on the dashboard and read the service name and description.\n\n'
          '2. Select the service you intend to use. For example, MindCheck is provided by SpeakOut Mental Health Outreach.\n\n'
          '3. Check the destination before continuing. A partner may open in your browser and have its own account, terms, privacy notice and charges. Your Care360 sign-in does not guarantee access.\n\n'
          '4. Read that service\'s information before sharing personal details. Do not enter your Care360 password into a partner website.\n\n'
          '5. Return to Care360 with your device\'s back control or reopen the app. Check Care360 Appointments separately if you need to verify a Care360 booking.\n\n'
          'This guide explains app navigation. It does not assess symptoms, interpret results or replace advice from a qualified healthcare professional.',
      icon: Icons.diversity_3_outlined,
    ),
  };

  String _topic = 'get_started';
  String? _answer;
  String _source = 'curated';
  bool _loading = false;
  bool _consent = false;

  bool get _canConnect =>
      widget.allowRemote && !k3OfflineSynthetic && _pilotEnabled;

  String get _language {
    final selected = widget.languageCode ??
        Localizations.localeOf(context).languageCode;
    return const {'en', 'ha', 'ig', 'yo', 'fr'}.contains(selected)
        ? selected : 'en';
  }

  Future<void> _showGuidance() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _answer = topics[_topic]!.answer;
      _source = 'curated';
    });

    // Local answer is always usable; no network, auth or health-data access.
    if (!_canConnect || !_consent) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Server calls are only possible from the opted-in authenticated pilot.
    try {
      final api = Uri.tryParse(Apis.baseUrl);
      if (api == null ||
          api.scheme != 'https' ||
          api.path != '/api/' ||
          api.host.endsWith('.invalid') ||
          api.host.endsWith('.test') ||
          api.host == 'localhost') {
        return;
      }
      final token =
          await SharedPreferenceHelper.getSecureString(Preferences.auth_token);
      if (token == null || token.trim().isEmpty) return;
      final response = await http.post(
        api.resolve('ai/guide'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'topic': _topic, 'language': _language}),
      ).timeout(const Duration(seconds: 9));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map &&
            data['success'] == true &&
            data['topic'] == _topic &&
            data['answer'] is String &&
            data['source'] is String &&
            (data['source'] == 'ai' || data['source'] == 'curated')) {
          final answer = (data['answer'] as String).trim();
          if (answer.isNotEmpty && mounted) {
            setState(() {
              _answer = answer.length > 4500
                  ? answer.substring(0, 4500) : answer;
              _source = data['source'] as String;
            });
          }
        }
      }
    } catch (_) {
      // Safely retain the curated answer. Never surface HTTP exception bodies,
      // private auth tokens or provider errors in the UI or logs.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = _language;
    final caption = switch (language) {
      'ha' => 'Jagorar Care360',
      'ig' => 'Ntuziaka Care360',
      'yo' => 'Ìtọ́sọ́nà Care360',
      'fr' => 'Guide Care360',
      _ => 'Care360 Guide',
    };
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: Text(caption),
        foregroundColor: _ink,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_ink, Color(0xFF145D68)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 30),
                SizedBox(height: 12),
                Text('Find your way around Care360',
                  style: TextStyle(color: Colors.white, fontSize: 23,
                      fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                Text('Choose a topic below. Guidance is limited to '
                  'using the app, not interpreting symptoms or health records.',
                  style: TextStyle(color: Colors.white, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFFE8F3EF),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(_canConnect
                ? 'Optional AI pilot: no symptoms, records or free-form '
                  'messages are sent. You can use curated answers without AI.'
                : 'Offline, curated app help. Generative AI is not enabled '
                  'in this build. Some languages still use English guidance.',
                key: const Key('care360-guide-status'),
                style: const TextStyle(color: _ink, height: 1.4)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('What do you need help with?',
            style: TextStyle(color: _ink, fontSize: 18,
                fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final entry in topics.entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.white,
              elevation: 0,
              child: RadioListTile<String>(
                key: Key('guide-topic-${entry.key}'),
                title: Text(entry.value.label),
                secondary: Icon(entry.value.icon, color: _green),
                value: entry.key,
                groupValue: _topic,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _topic = value;
                    _answer = null;
                  });
                },
              ),
            ),
          if (_canConnect)
            CheckboxListTile(
              key: const Key('guide-ai-consent'),
              value: _consent,
              onChanged: (value) => setState(() =>
                  _consent = value ?? false),
              title: const Text('Use optional AI navigation help'),
              subtitle: const Text('Only the selected topic and language '
                  'are sent through Care360 to the AI provider. '
                  'The app does not send your medical records.'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('care360-guide-show'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _loading ? null : _showGuidance,
            icon: _loading ? const SizedBox(
              height: 17, width: 17,
              child: CircularProgressIndicator(strokeWidth: 2,
                  color: Colors.white)) : const Icon(Icons.lightbulb_outline),
            label: Text(_loading ? 'Loading help…' :
                _canConnect && _consent ? 'Get navigation help' : 'Show guide'),
          ),
          if (_answer != null) ...[
            const SizedBox(height: 20),
            Container(
              key: const Key('care360-guide-answer'),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFDAE8E3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_source == 'ai' ? 'AI-assisted answer (pilot)'
                      : 'Step-by-step app guide',
                    style: const TextStyle(color: _green,
                        fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Text(_answer!, style: const TextStyle(
                      color: _ink, fontSize: 15, height: 1.5)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'This guide cannot diagnose conditions, advise on medication, '
            'replace a healthcare professional or manage an emergency. '
            'For urgent medical help, contact a qualified local service.',
            style: TextStyle(color: Color(0xFF53656C),
                fontSize: 12, height: 1.5),
          ),
        ],
      )),
    );
  }
}
