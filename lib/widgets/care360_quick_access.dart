import 'package:flutter/material.dart';

import '../const/Palette.dart';
import '../const/care360_theme.dart';
import 'care360_brand_signature.dart';

/// Visual-only shortcuts into existing Care360 routes.
/// The destination screens retain their own permission and login checks.
class Care360QuickAccess extends StatelessWidget {
  const Care360QuickAccess({super.key});

  static const List<_QuickAction> _actions = [
    _QuickAction('Find doctors', 'Specialist', Icons.medical_services_outlined),
    _QuickAction('Appointments', 'Appointment', Icons.event_available_outlined),
    _QuickAction('Pharmacies', 'AllPharamacy', Icons.local_pharmacy_outlined),
    _QuickAction('Hospitals', 'Hospitals', Icons.local_hospital_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your care, one place',
            style: TextStyle(
              color: Care360Theme.ink,
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Quick access to the services you need',
            style: TextStyle(color: Care360Theme.muted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 570;
              final columns = isWide ? 4 : 2;
              const spacing = 12.0;
              final cardWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final action in _actions)
                    SizedBox(
                      width: cardWidth,
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(19),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(19),
                          onTap: () => Navigator.pushNamed(context, action.route),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 114),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: Care360Theme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Care360Theme.softBlue,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Icon(action.icon, color: Palette.dark_blue, size: 22),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  action.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Care360Theme.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const Center(child: Care360BrandSignature(compact: true)),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.route, this.icon);

  final String label;
  final String route;
  final IconData icon;
}
