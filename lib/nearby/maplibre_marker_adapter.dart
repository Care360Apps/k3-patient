import 'package:flutter/foundation.dart';

class NearbyMapPin {
  const NearbyMapPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    this.onTap,
  });
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
}
