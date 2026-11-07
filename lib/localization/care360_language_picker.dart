import 'package:flutter/material.dart';

/// Simple, accessible language choice for auth and design-review screens.
/// The caller decides whether to persist the choice (real app) or keep it
/// local to a synthetic design walkthrough.
class Care360LanguagePicker extends StatelessWidget {
  const Care360LanguagePicker({
    super.key,
    required this.languageCode,
    required this.onSelected,
    this.previewOnly = false,
  });

  final String languageCode;
  final Future<void> Function(String code) onSelected;
  final bool previewOnly;

  static const languages = <String, String>{
    'en': 'English',
    'ha': 'Hausa',
    'ig': 'Igbo',
    'yo': 'Yorùbá',
    'fr': 'Français',
  };

  @override
  Widget build(BuildContext context) {
    final code = languages.containsKey(languageCode) ? languageCode : 'en';
    return PopupMenuButton<String>(
      key: const Key('care360-language-picker'),
      tooltip: previewOnly ? 'Preview screen language' : 'Change language',
      onSelected: (next) {
        if (next != code) onSelected(next);
      },
      itemBuilder: (context) => [
        for (final entry in languages.entries)
          PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                if (entry.key == code)
                  const Icon(Icons.check, color: Color(0xFF08785E), size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 10),
                Text(entry.value),
              ],
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4EF),
          border: Border.all(color: const Color(0xFFB2D4C5)),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.translate_rounded, size: 18, color: Color(0xFF08785E)),
          const SizedBox(width: 7),
          Text(languages[code]!, style: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF163A32))),
          const SizedBox(width: 4),
          const Icon(Icons.expand_more, size: 17, color: Color(0xFF08785E)),
        ]),
      ),
    );
  }
}
