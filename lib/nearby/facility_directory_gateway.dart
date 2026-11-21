import 'package:dio/dio.dart';
import '../api/apis.dart';

class DirectoryFacility {
  const DirectoryFacility({required this.id, required this.name, required this.type,
    required this.state, this.address, this.latitude, this.longitude, this.phone});
  final int id;
  final String name, type, state;
  final String? address, phone;
  final double? latitude, longitude;

  factory DirectoryFacility.fromJson(Map<String, dynamic> data) {
    double? coordinate(dynamic value) => value is num
        ? value.toDouble() : double.tryParse(value?.toString() ?? '');
    return DirectoryFacility(
      id: (data['id'] as num).toInt(),
      name: data['name'] as String,
      type: data['type'] as String,
      state: data['state'] as String,
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      latitude: coordinate(data['latitude']),
      longitude: coordinate(data['longitude']),
    );
  }
}

class FacilityDirectoryGateway {
  FacilityDirectoryGateway({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;

  Future<List<DirectoryFacility>> search({String? state, String? type,
    String? query, int page = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${Apis.baseUrl}directory/v1/facilities',
      queryParameters: {
        if (state != null && state.isNotEmpty) 'state': state,
        if (type != null && type.isNotEmpty) 'type': type,
        if (query != null && query.trim().isNotEmpty) 'search': query.trim(),
        'per_page': 50,\n        'page': page,
      },
      options: Options(sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8)),
    );
    final data = response.data?['data'];
    if (data is! List) throw const FormatException('Invalid directory response');
    return data.whereType<Map<String, dynamic>>()
      .map(DirectoryFacility.fromJson).toList(growable: false);
  }
}
