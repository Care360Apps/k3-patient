import 'package:flutter/material.dart';
import '../ai/care360_guide_screen.dart';
import '../localization/care360_language_picker.dart';
import '../diagnostics/k3_startup_diagnostics.dart';

/// A design-only walkthrough, compiled into the isolated synthetic debug APK.
///
/// Does not mount Home(), request permissions, call APIs, read patient data,
/// set an auth token, or navigate to any connected clinical feature.
class Care360OfflineDashboard extends StatefulWidget {
  const Care360OfflineDashboard({super.key});

  @override
  State<Care360OfflineDashboard> createState() =>
      _Care360OfflineDashboardState();
}

class _Care360OfflineDashboardState extends State<Care360OfflineDashboard> {
  int _tab = 0;
  String? _category;
  String _reviewLanguage = 'en';

  String _previewText(String key) {
    final copy = <String, Map<String, String>>{
      'Dashboard': {'ha': 'Shafin farko', 'ig': 'Ụlọ', 'yo': 'Ilé', 'fr': 'Accueil'},
      'Explore care': {'ha': 'Bincika kulawa', 'ig': 'Chọpụta nlekọta', 'yo': 'Ṣàwárí ìtọ́jú', 'fr': 'Explorer les soins'},
      'Appointments': {'ha': 'Alƙawura', 'ig': 'Oge nhọpụta', 'yo': 'Àwọn ìpàdé', 'fr': 'Rendez-vous'},
      'My profile': {'ha': 'Bayanan mutum', 'ig': 'Profaịlụ m', 'yo': 'Àkọọ́lẹ̀ mi', 'fr': 'Mon profil'},
      'Better care, closer to you.': {'ha': 'Ingantacciyar kulawa kusa da kai.', 'ig': 'Nlekọta ka mma dị gị nso.', 'yo': 'Ìtọ́jú tó dára, sún mọ́ ọ.', 'fr': 'De meilleurs soins, plus près de vous.'},
    };
    return copy[key]?[_reviewLanguage] ?? key;
  }

  static const _ink = Color(0xFF132D47);
  static const _green = Color(0xFF08785E);
  static const _muted = Color(0xFF5E6F7D);
  static const _background = Color(0xFFF5F8F7);

  static const _services = <_Service>[
    _Service('Doctors', Icons.medical_services_outlined,
        'Virtual care, notes and e-prescriptions'),
    _Service('Hospitals', Icons.local_hospital_outlined,
        'Find facilities and coordinate care'),
    _Service('Pharmacies', Icons.local_pharmacy_outlined,
        'Medicines, prescriptions and orders'),
    _Service('Care Providers', Icons.home_outlined,
        'Home visits, video, audio and chat'),
    _Service('MindCheck', Icons.favorite_border,
        'Everyday mental wellbeing tools'),
    _Service('Care360 Guide', Icons.auto_awesome_outlined,
        'Safe help with navigating the app'),
    _Service('Languages', Icons.translate_outlined,
        'English, Hausa, Igbo, Yoruba, French'),
  ];

  static const _detailLines = <String, List<String>>{
    'Doctors': [
      'Find a doctor by specialty',
      'Virtual consultations',
      'Consultation notes and history',
      'Electronic prescriptions',
    ],
    'Hospitals': [
      'Search hospitals and facilities',
      'Hospital details and directions',
      'Referrals and appointments',
    ],
    'Pharmacies': [
      'Browse available medicines',
      'Upload a prescription',
      'View cart and medicine orders',
    ],
    'Care Providers': [
      'Book a home visit',
      'Request video or audio consultations',
      'Secure in-app chat',
    ],
    'MindCheck': [
      'Mood check and wellbeing support',
      'Screening and self-help resources',
      'Connect to MindCheck after sign-in',
    ],
    'Languages': [
      'English',
      'Hausa',
      'Igbo',
      'Yoruba',
      'French',
    ],
    'Care360 Guide': [
      'Getting started',
      'Appointment booking',
      'Profile and settings',
      'Partner services',
    ],
  };

  void _open(String category) {
    if (category == 'Care360 Guide') {
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => Care360GuideScreen(
          allowRemote: false, languageCode: _reviewLanguage),
      ));
      return;
    }
    setState(() {
      _category = category;
      _tab = 1;
    });
  }

  void _switchTab(int tab) {
    setState(() {
      _tab = tab;
      _category = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Defense in depth: even a future accidental route registration must not
    // expose this walkthrough in staging/production builds.
    if (!k3OfflineSynthetic) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Offline design review is unavailable.')),
        ),
      );
    }
    final title = _category ?? _previewText(
        const ['Dashboard', 'Explore care', 'Appointments', 'My profile'][_tab]);
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        title: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Care360LanguagePicker(
              languageCode: _reviewLanguage,
              previewOnly: true,
              onSelected: (language) async {
                if (mounted) setState(() => _reviewLanguage = language);
              },
            )),
          ),
        ],
        leading: _category != null
            ? IconButton(
                tooltip: 'Back to explore',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _category = null),
              )
            : IconButton(
                tooltip: 'Back to sign in',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const _PreviewNotice(),
            Expanded(
              child: ListView(
                key: const Key('offline-dashboard-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  if (_category != null)
                    _detailView(_category!)
                  else if (_tab == 0)
                    _dashboard()
                  else if (_tab == 1)
                    _explore()
                  else if (_tab == 2)
                    _appointments()
                  else
                    _profile(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _tab,
        selectedItemColor: _green,
        unselectedItemColor: _muted,
        onTap: _switchTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_outlined), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _dashboard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_ink, Color(0xFF135A64)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Care360 Patient', style: TextStyle(
                  color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                Text(_previewText('Better care, closer to you.'),
                    key: const Key('care360-preview-headline'),
                    style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 25, height: 1.16)),
                const SizedBox(height: 12),
                const Text('Discover how patients can connect with care across Nigeria.',
                    style: TextStyle(color: Colors.white, height: 1.45)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('What would you like to do?',
              style: TextStyle(color: _ink, fontSize: 19,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          _serviceGrid(),
          const SizedBox(height: 22),
          _informationCard(
            Icons.info_outline,
            'Real appointments require sign-in',
            'This is a local design walkthrough. No real appointments, '
            'prescriptions, medical records or messages are available.',
          ),
        ],
      );

  Widget _explore() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explore Care360 services',
              style: TextStyle(color: _ink, fontSize: 21,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Select a service to review its planned patient journey.',
              style: TextStyle(color: _muted)),
          const SizedBox(height: 18),
          ..._services.map((service) => _serviceRow(service)),
        ],
      );

  Widget _appointments() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My appointments',
              style: TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _informationCard(
            Icons.calendar_today_outlined,
            'No appointments in design preview',
            'Connected staging will display bookings from a verified test account.',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _open('Doctors'),
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('Preview doctor booking journey'),
          ),
        ],
      );

  Widget _profile() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Patient profile',
              style: TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _informationCard(
            Icons.account_circle_outlined,
            'Sample patient profile',
            'Personal details, medical history, dependants and secure settings '
            'appear here only after authenticated sign-in.',
          ),
          const SizedBox(height: 16),
          _informationCard(
            Icons.lock_outline,
            'Your information stays private',
            'The offline walkthrough does not read or save patient information.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _open('Languages'),
            icon: const Icon(Icons.language_outlined),
            label: const Text('Preview supported languages'),
          ),
        ],
      );

  Widget _detailView(String category) {
    final service = _services.firstWhere((element) => element.title == category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F1EA),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(service.icon, color: _green, size: 34),
              const SizedBox(height: 14),
              Text(category,
                  style: const TextStyle(fontSize: 24,
                      fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 8),
              Text(service.subtitle, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
        if (category == 'Languages') ...[
          const SizedBox(height: 14),
          Care360LanguagePicker(
            languageCode: _reviewLanguage,
            previewOnly: true,
            onSelected: (language) async {
              if (mounted) setState(() => _reviewLanguage = language);
            },
          ),
          const SizedBox(height: 8),
          const Text('Preview language selection. Clinical wording remains in English '
            'until professionally reviewed.',
            style: TextStyle(fontSize: 12, color: _muted)),
        ],
        const SizedBox(height: 20),
        const Text('Patient experience to review',
            style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final line in _detailLines[category]!)
          Card(
            elevation: 0,
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline, color: _green),
              title: Text(line),
            ),
          ),
        const SizedBox(height: 12),
        _informationCard(Icons.shield_outlined,
          'Preview only — no live service',
          'This screen shows a proposed design journey, not actual connected '
          'doctors, hospitals, pharmacy stock, test results or bookings.'),
      ],
    );
  }

  Widget _serviceGrid() => LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final service in _services)
                SizedBox(width: tileWidth, child: _serviceCard(service)),
            ],
          );
        },
      );

  Widget _serviceCard(_Service service) => Card(
        elevation: 0,
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          key: Key('preview-${service.title.toLowerCase().replaceAll(' ', '-')}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(service.title),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(service.icon, size: 30, color: _green),
                const SizedBox(height: 12),
                Text(service.title,
                  style: const TextStyle(fontSize: 15,
                    fontWeight: FontWeight.w700, color: _ink)),
                const SizedBox(height: 5),
                Text(service.subtitle,
                  style: const TextStyle(fontSize: 12, color: _muted),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      );

  Widget _serviceRow(_Service service) => Card(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(service.icon, color: _green, size: 28),
          title: Text(service.title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(service.subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(service.title),
        ),
      );

  Widget _informationCard(IconData icon, String title, String description) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5EBE8)),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: _green, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _ink,
                    fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 7),
                Text(description, style: const TextStyle(color: _muted,
                    height: 1.45, fontSize: 13)),
              ],
            )),
          ],
        ),
      );
}

class _Service {
  const _Service(this.title, this.icon, this.subtitle);
  final String title;
  final IconData icon;
  final String subtitle;
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: const Color(0xFFFFF0C5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: const Row(
          children: [
            Icon(Icons.visibility_outlined, color: Color(0xFF694A00), size: 18),
            SizedBox(width: 10),
            Expanded(child: Text(
              'OFFLINE DESIGN PREVIEW • sample screens, no live data or sign-in',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF694A00)),
            )),
          ],
        ),
      );
}
