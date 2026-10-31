import 'package:flutter/material.dart';

import '../../const/Palette.dart';
import '../../const/care360_theme.dart';
import '../../widgets/care360_brand_signature.dart';
import '../../widgets/care360_master_brand.dart';
import '../../const/preference.dart';
import '../../const/prefConstatnt.dart';
import '../Authentication/SignIn.dart';

/// Care360 Patient onboarding. Clinical features remain unchanged and the
/// completed journey still persists the existing preference before sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _finishing = false;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.video_call_rounded,
      eyebrow: 'VIRTUAL CONSULTATIONS',
      title: 'Care that fits your life.',
      subtitle: 'Connect with healthcare professionals and manage consultations from wherever you are.',
      detail: 'Connect with your care team',
      accent: Color(0xFF1DA7B5),
    ),
    _OnboardingPageData(
      icon: Icons.local_pharmacy_outlined,
      eyebrow: 'MEDICINES & PHARMACY',
      title: 'Healthcare, made simpler.',
      subtitle: 'Explore pharmacies, review available medicines and manage your orders in one place.',
      detail: 'Pharmacy & medicine services',
      accent: Color(0xFF4379D9),
    ),
    _OnboardingPageData(
      icon: Icons.medical_services_outlined,
      eyebrow: 'FIND A SPECIALIST',
      title: 'The right care starts here.',
      subtitle: 'Discover specialists, book appointments and keep your care journey organized.',
      detail: 'Find the right professional',
      accent: Color(0xFF7D68D6),
    ),
  ];

  Future<void> _finishOnboarding(BuildContext context) async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await SharedPreferenceHelper.setBoolean(Preferences.onboarding_seen, true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SignIn()),
    );
  }

  void _nextOrFinish(BuildContext context) {
    if (_finishing) return;
    if (_currentIndex == _pages.length - 1) {
      _finishOnboarding(context);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastPage = _currentIndex == _pages.length - 1;
    return Scaffold(
      backgroundColor: Care360Theme.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 18, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Care360MasterBrand(
                            productName: 'Care360 Patient',
                            logoSize: 60,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _finishing ? null : () => _finishOnboarding(context),
                        child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final heroHeight = (constraints.maxHeight * 0.48).clamp(180.0, 310.0);
                      return PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (index) {
                          if (mounted) setState(() => _currentIndex = index);
                        },
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildIllustration(page, heroHeight),
                                const SizedBox(height: 26),
                                Text(
                                  page.eyebrow,
                                  style: TextStyle(
                                    color: page.accent,
                                    fontSize: 12,
                                    letterSpacing: 1.4,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.title,
                                  style: Theme.of(context).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  page.subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Care360Theme.muted,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (var index = 0; index < _pages.length; index++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: index == _currentIndex ? 30 : 9,
                              height: 7,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: index == _currentIndex
                                    ? Palette.dark_blue
                                    : Care360Theme.border,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            '${_currentIndex + 1} / ${_pages.length}',
                            style: const TextStyle(
                              color: Care360Theme.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _finishing ? null : () => _nextOrFinish(context),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 56),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(lastPage ? 'Get started' : 'Continue'),
                              const SizedBox(width: 10),
                              Icon(lastPage ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 21),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(child: Care360BrandSignature(compact: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(_OnboardingPageData page, double height) {
    return Semantics(
      label: page.detail,
      image: true,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Palette.dark_blue, page.accent],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              Positioned(
                top: -74,
                right: -55,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.09),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -70,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.5),
                  ),
                  child: Icon(page.icon, color: Colors.white, size: height * 0.32),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user_outlined, color: page.accent, size: 21),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          page.detail,
                          style: const TextStyle(
                            color: Care360Theme.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Care360Theme.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.accent,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String detail;
  final Color accent;
}
