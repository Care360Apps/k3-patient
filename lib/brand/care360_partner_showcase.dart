import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai/care360_guide_screen.dart';

/// Curated discovery only. This deliberately does not import, send, or link
/// Care360 identifiers, patient data, tokens, or navigation state.
class Care360PartnerShowcase extends StatelessWidget {
  const Care360PartnerShowcase({super.key, this.openExternal});
  final Future<bool> Function(Uri)? openExternal;

  static final Uri mindCheckUrl = Uri.https(
    'mindcheck.speakoutmentalhealth.org', '/');

  Future<void> _openMindCheck(BuildContext context) async {
    bool opened = false;
    try {
      opened = await (openExternal?.call(mindCheckUrl) ??
          launchUrl(mindCheckUrl, mode: LaunchMode.externalApplication));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open MindCheck. Check your connection.'),
      ));
    }
  }

  void _openLocalGuide(BuildContext context) {
    // The guide never accesses clinical views or sends unstructured content.
    // Optional server-assisted answers remain OFF without the explicit pilot
    // build flag and a per-session consent action.
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const Care360GuideScreen(allowRemote: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final heading = switch (lang) {
      'fr' => 'Explorer nos partenaires',
      'ha' => 'Bincika abokan haɗin gwiwa',
      'ig' => 'Chọpụta ndị mmekọ anyị',
      'yo' => 'Ṣàwárí àwọn alábàáṣiṣẹ́pọ̀',
      _ => 'Explore partner services',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        color: const Color(0xFFF0F7F6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(heading, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF102B48))),
            const SizedBox(height: 4),
            const Text('Independent, reviewed services. Opening a partner '
              'site takes you outside Care360.',
              style: TextStyle(fontSize: 12, color: Color(0xFF47606B))),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF087D76),
                child: Icon(Icons.psychology_alt_outlined,
                  color: Colors.white, size: 28),
              ),
              title: const Text('MindCheck', style: TextStyle(
                fontWeight: FontWeight.w700)),
              subtitle: const Text('Mental wellbeing • By SpeakOut Mental Health Outreach'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _openMindCheck(context),
            ),
            const Divider(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _openLocalGuide(context),
                icon: const Icon(Icons.help_outline),
                label: const Text('Care360 Guide · optional AI pilot'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
