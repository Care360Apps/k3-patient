import 'package:flutter/material.dart';

/// A calm, Nigerian-first entry to existing nearby-care discovery.
/// This widget never reads patient location, health data or authentication.
/// The host chooses whether and where to navigate when it is tapped.
class Care360NearbyCareHero extends StatelessWidget {
  const Care360NearbyCareHero({super.key, required this.onExplore});

  final VoidCallback onExplore;

  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 350;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Semantics(
        button: true,
        label: 'Find nearby care. Explore doctors, providers and facilities.',
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_navy, Color(0xFF125761)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: InkWell(
              key: const Key('home-find-nearby-care'),
              onTap: onExplore,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CARE360  •  HEALTHCARE',
                            style: TextStyle(
                              color: Color(0xFFBDEAE0),
                              fontSize: 10,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            'Care closer to home',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Find nearby doctors, care providers and facilities.',
                            style: TextStyle(
                              color: Color(0xFFE2F0EF),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.location_on_outlined,
                                  color: Color(0xFFBDEAE0), size: 20),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Find nearby care',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(width: 7),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Existing branded African-clinician artwork; no new
                    // third-party image host or image-tracking request.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: narrow ? 73 : 112,
                        height: narrow ? 118 : 146,
                        child: Image.asset(
                          'assets/images/care360_clinician_team.webp',
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: _teal,
                            child: Center(
                              child: Icon(
                                Icons.health_and_safety_outlined,
                                color: Colors.white,
                                size: 39,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
