import 'package:dio/dio.dart';
import '../api/apis.dart';
import '../api/retrofit_Api.dart';

/// Public minimum-necessary snapshot of a VERIFIED professional who opted
/// into accepting requests for a bounded shift at a published service area.
/// Not a live GPS coordinate, road ETA, appointment slot or guaranteed booking.
class NearbyOnDutyProfessional {
  const NearbyOnDutyProfessional({
    required this.id,
    required this.name,
    required this.role,
    required this.lat,
    required this.lng,
    required this.distanceKm,
  });

  final int id;
  final String name;
  final String role;
  final double lat;
  final double lng;
  final double distanceKm;

  static NearbyOnDutyProfessional? fromJson(dynamic input) {
    if (input is! Map) return null;
    final id = input['id'];
    final role = input['role'];
    final name = input['name'];
    final lat = input['lat'];
    final lng = input['lng'];
    final distance = input['distance_km'];
    final nLat = lat is num ? lat.toDouble() : double.tryParse('$lat');
    final nLng = lng is num ? lng.toDouble() : double.tryParse('$lng');
    final nDistance = distance is num
        ? distance.toDouble() : double.tryParse('$distance');
    if (id is! int || id <= 0 ||
        name is! String || name.trim().isEmpty ||
        (role != 'doctor' && role != 'provider') ||
        nLat == null || !nLat.isFinite || nLat < -90 || nLat > 90 ||
        nLng == null || !nLng.isFinite || nLng < -180 || nLng > 180 ||
        nDistance == null || !nDistance.isFinite || nDistance < 0 ||
        input['accepting_requests'] != true) {
      return null;
    }
    return NearbyOnDutyProfessional(
      id: id, name: name.trim(), role: role as String,
      lat: nLat, lng: nLng, distanceKm: nDistance);
  }
}

class NearbyOnDutyService {
  const NearbyOnDutyService();

  Future<List<NearbyOnDutyProfessional>> find({
    required double lat,
    required double lng,
    double radiusKm = 20,
  }) async {
    final base = Uri.tryParse(Apis.baseUrl);
    if (base == null || base.scheme != 'https' ||
        base.host.isEmpty || lat < -90 || lat > 90 ||
        lng < -180 || lng > 180) {
      throw const FormatException('Nearby care requires a verified HTTPS API.');
    }
    final uri = base.resolve('nearby-care');
    final Response<dynamic> response =
        await RetroApi2().dioData2().postUri<dynamic>(
      uri,
      // Coarse search point is sufficient for finding a service area,
      // and a POST body avoids logging exact device coordinates in URLs.
      data: {
        'lat': double.parse(lat.toStringAsFixed(2)),
        'lng': double.parse(lng.toStringAsFixed(2)),
        'radius_km': radiusKm.clamp(1, 50),
        'limit': 30,
      },
    );
    final root = response.data;
    if (root is! Map || root['success'] != true || root['data'] is! List) {
      throw const FormatException('Nearby care unavailable.');
    }
    final results = <NearbyOnDutyProfessional>[];
    for (final item in root['data'] as List) {
      final p = NearbyOnDutyProfessional.fromJson(item);
      if (p != null) results.add(p);
    }
    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }
}
