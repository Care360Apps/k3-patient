import 'package:flutter/material.dart';

import '../const/care360_theme.dart';

/// Institutional recognition shared by Android and iOS.
/// This is product attribution, not a claim of worldwide clinical coverage.
class Care360BrandSignature extends StatelessWidget {
  const Care360BrandSignature({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context);
    return Semantics(
      container: true,
      label: 'Care360. Nigeria to the World. A product of CNU Medical Institute.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public_rounded, size: 16, color: Color(0xFF16815C)),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'NIGERIA TO THE WORLD',
                  textAlign: TextAlign.center,
                  textScaler: textScale,
                  style: const TextStyle(
                    color: Care360Theme.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 3 : 7),
          const Text(
            'A product of CNU Medical Institute',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Care360Theme.muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
