import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai/care360_guide_screen.dart';

/// A curated external placement. This intentionally contains no patient ID,
/// booking state, symptoms, authentication credentials or tracking parameters.
class Care360PartnerSlide {
  const Care360PartnerSlide({
    required this.title,
    required this.subtitle,
    required this.url,
    this.imageUrl,
    this.sponsored = false,
  });

  final String title;
  final String subtitle;
  final Uri url;
  final String? imageUrl;
  final bool sponsored;

  static Uri? safeDestination(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty || uri.userInfo.isNotEmpty || uri.port != 443) {
      return null;
    }
    final host = uri.host.toLowerCase();
    if (host == 'localhost' || host.endsWith('.local') ||
        host.endsWith('.localhost') || host.endsWith('.internal') ||
        host.endsWith('.invalid') || host.endsWith('.test') ||
        !host.contains('.') ||
        RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host) ||
        host.contains(':')) {
      return null;
    }
    return uri;
  }

  /// Remote assets use HTTPS. The locally configured staging Laravel host is
  /// also permitted to serve uploaded images in debug builds only.
  static Uri? safeImageUri(String? raw) {
    final https = safeDestination(raw);
    if (https != null) return https;
    if (!kDebugMode || raw == null) return null;
    final image = Uri.tryParse(raw);
    const apiBase = String.fromEnvironment('K3_API_BASE_URL');
    final api = Uri.tryParse(apiBase);
    if (image != null && api != null && api.host.isNotEmpty &&
        image.scheme == 'http' && api.scheme == 'http' &&
        image.host == api.host && image.port == api.port &&
        image.userInfo.isEmpty &&
        image.path.startsWith('/images/upload/')) {
      return image;
    }
    return null;
  }
}

/// Rotating discovery area on authenticated Patient Home only. No advertising
/// appears in clinical records, prescription, call, or Care360 Plus screens.
class Care360PartnerShowcase extends StatefulWidget {
  const Care360PartnerShowcase({
    super.key,
    this.slides = const [],
    this.openExternal,
    this.interval = const Duration(seconds: 10),
  });

  final List<Care360PartnerSlide> slides;
  final Future<bool> Function(Uri)? openExternal;
  final Duration interval;

  static final Uri mindCheckUrl =
      Uri.https('mindcheck.speakoutmentalhealth.org', '/');

  @override
  State<Care360PartnerShowcase> createState() => _Care360PartnerShowcaseState();
}

class _Care360PartnerShowcaseState extends State<Care360PartnerShowcase>
    with WidgetsBindingObserver {
  late final PageController _pages;
  Timer? _rotation;
  int _current = 0;
  bool _hovered = false;
  bool _foreground = true;
  bool _reducedMotion = false;

  // Nonclinical interface labels; medical, privacy and sponsor terms require
  // native-speaker acceptance before the product is marketed as fully localized.
  static const Map<String, Map<String, String>> _labels = {
    'en': {
      'sponsored': 'Sponsored',
      'partner': 'Partner',
      'explore': 'Explore service',
      'previous': 'Previous partner',
      'next': 'Next partner',
      'guide': 'Care360 Guide · app help',
    },
    'ha': {
      'sponsored': 'Talla',
      'partner': 'Abokin hulɗa',
      'explore': 'Duba sabis',
      'previous': 'Na baya',
      'next': 'Na gaba',
      'guide': 'Jagorar Care360 · taimakon manhaja',
    },
    'ig': {
      'sponsored': 'Mgbasa ozi',
      'partner': 'Onye mmekọ',
      'explore': 'Lelee ọrụ',
      'previous': 'Nke gara aga',
      'next': 'Nke na-esote',
      'guide': 'Ntuziaka Care360 · enyemaka',
    },
    'yo': {
      'sponsored': 'Ìpolówó',
      'partner': 'Alábàáṣiṣẹ́pọ̀',
      'explore': 'Wo iṣẹ́ náà',
      'previous': 'Tẹ́lẹ̀',
      'next': 'Tó kàn',
      'guide': 'Ìtọ́sọ́nà Care360 · ìrànlọ́wọ́',
    },
    'fr': {
      'sponsored': 'Sponsorisé',
      'partner': 'Partenaire',
      'explore': 'Découvrir le service',
      'previous': 'Partenaire précédent',
      'next': 'Partenaire suivant',
      'guide': 'Guide Care360 · aide',
    },
  };

  String _label(String key) {
    final language = Localizations.localeOf(context).languageCode;
    return _labels[language]?[key] ?? _labels['en']![key]!;
  }

  List<Care360PartnerSlide> get _slides => [
        Care360PartnerSlide(
          title: 'MindCheck',
          subtitle: 'Everyday mental wellbeing by SpeakOut Mental Health Outreach',
          url: Care360PartnerShowcase.mindCheckUrl,
        ),
        ...widget.slides.where((slide) =>
            Care360PartnerSlide.safeDestination(slide.url.toString()) != null),
      ];

  @override
  void initState() {
    super.initState();
    _pages = PageController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    _reducedMotion =
        (media?.disableAnimations ?? false) || (media?.accessibleNavigation ?? false);
    _resetTimer();
  }

  bool _sameSlides(
      List<Care360PartnerSlide> previous, List<Care360PartnerSlide> current) {
    if (identical(previous, current)) return true;
    if (previous.length != current.length) return false;
    for (var i = 0; i < previous.length; i++) {
      final a = previous[i];
      final b = current[i];
      if (a.title != b.title || a.subtitle != b.subtitle ||
          a.url != b.url || a.imageUrl != b.imageUrl ||
          a.sponsored != b.sponsored) {
        return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant Care360PartnerShowcase oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent/dashboard rebuilds often allocate an equivalent new List.
    // Do not restart the 10-second timer unless content actually changed.
    if (!_sameSlides(oldWidget.slides, widget.slides) ||
        oldWidget.interval != widget.interval) {
      final count = _slides.length;
      if (_current >= count) {
        _current = 0;
        if (_pages.hasClients) {
          _pages.jumpToPage(0);
        }
      }
      _resetTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _resetTimer();
  }

  void _resetTimer() {
    _rotation?.cancel();
    if (!mounted || !_foreground || _hovered || _reducedMotion ||
        _slides.length <= 1 || widget.interval <= Duration.zero) return;
    _rotation = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_pages.hasClients) return;
      _pages.animateToPage(
        (_current + 1) % _slides.length,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _goTo(int page) {
    if (!_pages.hasClients || page < 0 || page >= _slides.length) return;
    _rotation?.cancel();
    _pages.animateToPage(
      page,
      duration: _reducedMotion
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    _resetTimer();
  }

  Future<void> _openPartner(Care360PartnerSlide slide) async {
    final safe = Care360PartnerSlide.safeDestination(slide.url.toString());
    if (safe == null) return;
    bool opened = false;
    try {
      opened = await (widget.openExternal?.call(safe) ??
          launchUrl(safe, mode: LaunchMode.externalApplication));
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not open the partner site. Check your connection.'),
      ));
    }
  }

  void _openLocalGuide() {
    // Preserve the reviewed curated Care360 Guide. Optional remote AI is
    // disabled by default and separately gated by HTTPS, auth, and consent.
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const Care360GuideScreen(allowRemote: true),
    ));
  }

  Widget _slideCard(Care360PartnerSlide slide) {
    final img = Care360PartnerSlide.safeImageUri(slide.imageUrl);
    final accent = slide.sponsored
        ? const Color(0xFF173A5F)
        : const Color(0xFF096E67);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          key: ValueKey('care360-slide-${slide.title}'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openPartner(slide),
          child: Semantics(
            button: true,
            label: '${_label(slide.sponsored ? 'sponsored' : 'partner')}: '
                '${slide.title}. Opens external website.',
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD8E6E9)),
                gradient: const LinearGradient(
                  colors: [Color(0xFFF7FBFA), Color(0xFFE9F3F4)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withOpacity(.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                        child: Text(_label(slide.sponsored ? 'sponsored' : 'partner'),
                          style: TextStyle(fontSize: 11,
                            fontWeight: FontWeight.w800, color: accent)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(slide.title, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 19,
                        height: 1.15, fontWeight: FontWeight.w800,
                        color: Color(0xFF122D43))),
                    const SizedBox(height: 5),
                    Text(slide.subtitle, maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.35,
                        color: Color(0xFF3A5565))),
                    const SizedBox(height: 10),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(_label('explore'),
                        style: TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 12, color: accent)),
                      const SizedBox(width: 5),
                      Icon(Icons.open_in_new, size: 14, color: accent),
                    ]),
                  ],
                )),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 88, height: 126,
                    child: img == null
                        ? ColoredBox(
                            color: accent,
                            child: const Icon(Icons.health_and_safety_outlined,
                              color: Colors.white, size: 38))
                        : Image.network(img.toString(), fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: accent,
                              child: const Icon(Icons.public,
                                color: Colors.white, size: 34))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
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
    final slides = _slides;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(heading, style: const TextStyle(
            fontSize: 19, fontWeight: FontWeight.w800,
            color: Color(0xFF122D43)))),
          Text('${_current + 1}/${slides.length}',
            style: const TextStyle(fontSize: 12,
              fontWeight: FontWeight.w600, color: Color(0xFF47606B))),
        ]),
        const SizedBox(height: 4),
        const Text('Useful services and featured partners. '
          'External websites have their own privacy policies.',
          style: TextStyle(fontSize: 12, color: Color(0xFF47606B))),
        const SizedBox(height: 9),
        MouseRegion(
          onEnter: (_) { _hovered = true; _resetTimer(); },
          onExit: (_) { _hovered = false; _resetTimer(); },
          child: SizedBox(
            height: 204,
            child: PageView.builder(
              key: const ValueKey('care360-partner-carousel'),
              controller: _pages,
              itemCount: slides.length,
              onPageChanged: (index) {
                setState(() => _current = index);
                _resetTimer();
              },
              itemBuilder: (context, index) => _slideCard(slides[index]),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(children: [
          IconButton(
            tooltip: _label('previous'),
            icon: const Icon(Icons.chevron_left),
            onPressed: slides.length > 1
                ? () => _goTo((_current - 1 + slides.length) % slides.length)
                : null,
          ),
          Expanded(child: slides.length <= 6
              ? Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Semantics(
                      label: 'Show slide ${index + 1} of ${slides.length}',
                      button: true,
                      child: InkWell(
                        key: ValueKey('care360-slide-dot-$index'),
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _goTo(index),
                        child: SizedBox(
                          height: 32, width: 22,
                          child: Center(child: Icon(_current == index
                            ? Icons.circle : Icons.circle_outlined,
                            size: 12, color: const Color(0xFF096E67))),
                        ),
                      ),
                    ),
                  )),
                )
              : Text('Slide ${_current + 1} of ${slides.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12,
                    color: Color(0xFF47606B)))),
          IconButton(
            tooltip: _label('next'),
            icon: const Icon(Icons.chevron_right),
            onPressed: slides.length > 1
                ? () => _goTo((_current + 1) % slides.length)
                : null,
          ),
        ]),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _openLocalGuide,
            icon: const Icon(Icons.help_outline, size: 16),
            label: Text(_label('guide')),
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _rotation?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }
}
