import 'package:flutter/material.dart';

import '../const/care360_theme.dart';

/// The original Care360 master logo, with an app-specific product label.
/// Both Care360 Patient and Care360 Plus use the same underlying brand mark.
/// Do not replace the master logo with a generic healthcare icon.
class Care360MasterBrand extends StatelessWidget {
  const Care360MasterBrand({
    super.key,
    required this.productName,
    this.onDark = false,
    this.logoSize = 64,
  });

  final String productName;
  final bool onDark;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Care360, quality healthcare for all. $productName',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/care360_master_logo.webp',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 5),
          Text(
            productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onDark ? Colors.white : Care360Theme.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.2,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
