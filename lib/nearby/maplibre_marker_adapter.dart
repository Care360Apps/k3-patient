import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google;

class NearbyMapPin {
  const NearbyMapPin({
    required this.id, required this.latitude, required this.longitude,
    required this.title, this.subtitle, this.onTap,
  });
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  static List<NearbyMapPin> fromGoogle(Set<google.Marker> markers) =>
      markers.where((m) =>
          m.position.latitude.isFinite && m.position.longitude.isFinite &&
          m.position.latitude.abs() <= 90 &&
          m.position.longitude.abs() <= 180)
      .map((m) => NearbyMapPin(
        id: m.markerId.value,
        latitude: m.position.latitude,
        longitude: m.position.longitude,
        title: m.infoWindow.title ?? '',
        subtitle: m.infoWindow.snippet,
        onTap: m.onTap ?? m.infoWindow.onTap,
      )).toList(growable: false);
}
