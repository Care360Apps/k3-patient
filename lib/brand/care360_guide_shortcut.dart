import 'package:flutter/material.dart';
import '../ai/care360_guide_screen.dart';

/// Direct Patient Home shortcut to the existing curated, nonclinical Guide.
/// This does not enable remote AI or add any clinical data to model requests.
class Care360GuideShortcut extends StatelessWidget {
  const Care360GuideShortcut({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final title = switch (lang) {
      'ha' => 'Jagorar Care360',
      'ig' => 'Ntuziaka Care360',
      'yo' => 'Ìtọ́sọ́nà Care360',
      'fr' => 'Guide Care360',
      _ => 'Care360 Guide',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Material(
        color: const Color(0xFFE8F3EF),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('home-care360-guide'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => const Care360GuideScreen(allowRemote: true),
          )),
          child: Semantics(
            button: true,
            label: '$title. App navigation help, not medical advice.',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.support_agent_outlined,
                      color: Color(0xFF087D76), size: 29),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(
                          color: Color(0xFF123E4D),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        )),
                        const SizedBox(height: 3),
                        const Text(
                          'Help with appointments and using the app — not medical advice.',
                          style: TextStyle(
                            color: Color(0xFF405E66),
                            height: 1.35,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF087D76), size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
