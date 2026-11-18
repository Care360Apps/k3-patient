import 'package:flutter/material.dart';

import 'care360_navigation_copy.dart';

/// Reusable visual heading for existing Care360 Patient service directories.
/// The component is intentionally presentation-only; no network requests,
/// geolocation permissions or private medical details are read here.
class Care360ServiceIntro extends StatelessWidget {
  const Care360ServiceIntro({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.titleKey,
    this.descriptionKey,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? titleKey;
  final String? descriptionKey;

  static const navy = Color(0xFF123E4D);
  static const teal = Color(0xFF087D76);

  @override
  Widget build(BuildContext context) {
    final localizedTitle = care360NavigationText(context, titleKey ?? '', title);
    final localizedDescription = care360NavigationText(
      context, descriptionKey ?? '', description);
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 7),
      child: Semantics(
        container: true,
        label: '$localizedTitle. $localizedDescription',
        child: ExcludeSemantics(
          child: Container(
            key: const Key('care360-service-intro'),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F5F1),
              border: Border.all(color: const Color(0xFFD5E8E2)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localizedTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(localizedDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF506B70),
                    ),
                  ),
                ],
              )),
            ]),
          ),
        ),
      ),
    );
  }
}
