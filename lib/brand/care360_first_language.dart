import 'package:flutter/material.dart';

/// First-launch entry only. Existing logins bypass this page, and the choice
/// is persisted by the hosting route before the user enters onboarding.
/// Everything is built from the shipped Care360 logo and clinician photos.
class Care360FirstLanguageScreen extends StatefulWidget {
  const Care360FirstLanguageScreen({
    super.key,
    required this.onContinue,
    this.initialLanguage = 'en',
  });

  final String initialLanguage;
  final Future<void> Function(String language) onContinue;

  @override
  State<Care360FirstLanguageScreen> createState() =>
      _Care360FirstLanguageScreenState();
}

class _Care360FirstLanguageScreenState
    extends State<Care360FirstLanguageScreen> {
  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);
  static const _labels = <String, String>{
    'en': 'English',
    'ha': 'Hausa',
    'ig': 'Igbo',
    'yo': 'Yorùbá',
    'fr': 'Français',
  };

  /// Short first-launch instructions update immediately when a language
  /// is chosen, even before the root locale has been persisted.
  /// This is navigation copy only; clinical translations need review.
  static const _firstLaunchCopy = <String, Map<String, String>>{
    'en': {
      'welcome': 'Welcome to Care360',
      'instruction': 'Choose the language that feels right for you.',
      'select': 'Select language',
      'continue': 'Continue',
      'review': 'You can change language later on any screen. Some text may remain in English while translations are being reviewed.',
      'error': 'Could not save your language. Please try again.',
    },
    'ha': {
      'welcome': 'Barka da zuwa Care360',
      'instruction': 'Zaɓi harshen da ya fi dacewa da kai.',
      'select': 'Zaɓi harshe',
      'continue': 'Ci gaba',
      'review': 'Za ka iya sauya harshe daga baya. Wasu rubuce-rubuce za su kasance da Turanci yayin da ake duba fassara.',
      'error': 'Ba a iya ajiye harshen ba. Sake gwadawa.',
    },
    'ig': {
      'welcome': 'Nnọọ na Care360',
      'instruction': 'Họrọ asụsụ masịrị gị.',
      'select': 'Họrọ asụsụ',
      'continue': "Gaa n'ihu",
      'review': "Ị nwere ike ịgbanwe asụsụ n'oge ọzọ. Ụfọdụ ederede nwere ike ịdị n'asụsụ Bekee ka a na-enyocha ntụgharị asụsụ.",
      'error': 'Enweghị ike ịchekwa asụsụ. Gbalịa ọzọ.',
    },
    'yo': {
      'welcome': 'Ẹ káàbọ̀ sí Care360',
      'instruction': 'Yan èdè tó rọrùn fún ọ.',
      'select': 'Yan èdè',
      'continue': 'Tẹ̀síwájú',
      'review': 'O lè yí èdè padà nígbà míì. Díẹ̀ lára àwọn ọ̀rọ̀ lè wà ní èdè Gẹ̀ẹ́sì nígbà tí a ń ṣàyẹ̀wò ìtumọ̀.',
      'error': 'A kò lè fi èdè náà pamọ́. Gbìyànjú lẹ́ẹ̀kan síi.',
    },
    'fr': {
      'welcome': 'Bienvenue sur Care360',
      'instruction': 'Choisissez la langue qui vous convient.',
      'select': 'Choisir une langue',
      'continue': 'Continuer',
      'review': 'Vous pourrez changer de langue à tout moment. Certains textes peuvent rester en anglais pendant la révision des traductions.',
      'error': 'Impossible d’enregistrer la langue. Réessayez.',
    },
  };

  String _screenText(String name) =>
      _firstLaunchCopy[_selected]?[name] ??
      _firstLaunchCopy['en']![name]!;

  late String _selected;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = _labels.containsKey(widget.initialLanguage)
        ? widget.initialLanguage
        : 'en';
  }

  Future<void> _continue() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.onContinue(_selected);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _error = _screenText('error'));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 520,
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/care360_master_logo.webp',
                            width: 62,
                            height: 62,
                            semanticLabel: 'Care360 official logo',
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Care360',
                                    style: TextStyle(
                                        color: _navy,
                                        fontSize: 27,
                                        fontWeight: FontWeight.w800)),
                                Text('Care, closer to home',
                                    style: TextStyle(
                                        color: Color(0xFF526F77),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(21),
                        child: AspectRatio(
                          aspectRatio: 2.05,
                          child: Image.asset(
                            'assets/images/care360_clinician_team.webp',
                            fit: BoxFit.cover,
                            semanticLabel: 'African healthcare professionals',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _screenText('welcome'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 25,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _screenText('instruction'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF536B72),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 19),
                      Text(
                        _screenText('select'),
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._labels.entries.map((entry) {
                        final active = _selected == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: active
                                ? const Color(0xFFE6F4EE)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                              side: BorderSide(
                                color: active
                                    ? _teal
                                    : const Color(0xFFE0E8E7),
                                width: active ? 1.8 : 1,
                              ),
                            ),
                            child: InkWell(
                              key: Key('first-language-${entry.key}'),
                              onTap: _submitting
                                  ? null
                                  : () => setState(() => _selected = entry.key),
                              borderRadius: BorderRadius.circular(13),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 9),
                                child: Row(
                                  children: [
                                    Icon(
                                      active
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: active
                                          ? _teal
                                          : const Color(0xFF73888D),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          color: _navy,
                                          fontWeight: active
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (active)
                                      const Icon(Icons.check_circle_rounded,
                                          color: _teal, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            _error!,
                            key: const Key('first-language-error'),
                            style: const TextStyle(color: Color(0xFFA33F25)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          key: const Key('first-language-continue'),
                          onPressed: _submitting ? null : _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text(
                                  _screenText('continue'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _screenText('review'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: Color(0xFF63757C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'A product of CNU Medical Institute',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF526F77),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
