import 'package:flutter/material.dart';

/// View-only service navigation. The hosting Patient screen supplies the
/// existing route handlers; this widget never obtains GPS, medical records,
/// authentication tokens, payment context or background network data.
class Care360ServiceAction {
  const Care360ServiceAction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.isPreview = false,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPreview;
}

class Care360ServiceGrid extends StatelessWidget {
  const Care360ServiceGrid({super.key, required this.actions});

  final List<Care360ServiceAction> actions;

  static const _navy = Color(0xFF123E4D);
  static const _teal = Color(0xFF087D76);
  static const _muted = Color(0xFF516970);
  static const _line = Color(0xFFE0E9E7);

  @override
  Widget build(BuildContext context) {
    // A light card grid keeps different services visually distinct without
    // repeating large carousels or overwhelming patients with long labels.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore care services',
            key: Key('care360-service-grid-title'),
            style: TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Find the right support in one place.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 620 ? 3 : 2;
            return GridView.builder(
              key: const Key('care360-services-grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 11,
                mainAxisSpacing: 11,
                mainAxisExtent: 130,
              ),
              itemBuilder: (context, index) {
                final action = actions[index];
                return Semantics(
                  button: true,
                  label: '${action.title}. ${action.description}',
                  child: Material(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                      side: const BorderSide(color: _line),
                    ),
                    child: InkWell(
                      key: Key('care360-service-${action.id}'),
                      onTap: action.onTap,
                      borderRadius: BorderRadius.circular(17),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 37,
                                height: 37,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5F1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(action.icon,
                                    size: 21, color: _teal),
                              ),
                              const Spacer(),
                              if (action.isPreview)
                                const Text('PILOT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: _teal,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .5,
                                  )),
                            ]),
                            const Spacer(),
                            Text(action.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              )),
                            const SizedBox(height: 3),
                            Text(action.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                                height: 1.2,
                              )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
