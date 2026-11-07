import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../api/apis.dart';
import '../../api/retrofit_Api.dart';

/// Results are limited by Care360's authenticated backend proxy.
/// Neither Google API keys nor any patient health data enter these requests.
class Care360PlaceSuggestion {
  const Care360PlaceSuggestion({required this.id, required this.label});
  final String id;
  final String label;
}

class Care360PlaceSelection {
  const Care360PlaceSelection({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  final String address;
  final double latitude;
  final double longitude;
}

class Care360PlacesGateway {
  Care360PlacesGateway({Dio? dio}) : _dio = dio ?? RetroApi().dioData();
  final Dio _dio;

  Future<List<Care360PlaceSuggestion>> search(
      String query, String sessionToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${Apis.baseUrl}places/autocomplete',
      data: {'query': query, 'session_token': sessionToken},
      options: Options(sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8)),
    );
    if (response.data?['success'] != true) {
      throw const FormatException('Places search unavailable');
    }
    final raw = response.data?['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) => Care360PlaceSuggestion(
      id: (item['place_id'] ?? '').toString(),
      label: (item['description'] ?? '').toString(),
    )).where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .take(8).toList(growable: false);
  }

  Future<Care360PlaceSelection> resolve(
      String placeId, String sessionToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${Apis.baseUrl}places/details',
      data: {'place_id': placeId, 'session_token': sessionToken},
      options: Options(sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8)),
    );
    if (response.data?['success'] != true ||
        response.data?['data'] is! Map) {
      throw const FormatException('Place details unavailable');
    }
    final result = response.data!['data'] as Map;
    final lat = (result['latitude'] as num?)?.toDouble();
    final lng = (result['longitude'] as num?)?.toDouble();
    final address = result['address'];
    if (lat == null || lng == null || !lat.isFinite || !lng.isFinite ||
        lat.abs() > 90 || lng.abs() > 180 ||
        address is! String || address.trim().isEmpty) {
      throw const FormatException('Invalid place coordinates');
    }
    return Care360PlaceSelection(
        address: address.trim(), latitude: lat, longitude: lng);
  }
}

/// Opt-in text search. When backend Places is unconfigured, this screen
/// remains usable: close it and tap the map to choose coordinates manually.
class Care360PlaceSearchSheet extends StatefulWidget {
  const Care360PlaceSearchSheet({super.key, this.gateway});

  final Care360PlacesGateway? gateway;

  @override
  State<Care360PlaceSearchSheet> createState() =>
      _Care360PlaceSearchSheetState();
}

class _Care360PlaceSearchSheetState extends State<Care360PlaceSearchSheet> {
  late final Care360PlacesGateway _gateway =
      widget.gateway ?? Care360PlacesGateway();
  final TextEditingController _query = TextEditingController();
  final String _sessionToken = const Uuid().v4();
  Timer? _debounce;
  int _sequence = 0;
  bool _loading = false;
  String? _message;
  List<Care360PlaceSuggestion> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _schedule(String value) {
    _debounce?.cancel();
    final seq = ++_sequence;
    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _results = const [];
        _message = null;
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted || seq != _sequence) return;
      setState(() {
        _loading = true;
        _message = null;
      });
      try {
        final places = await _gateway.search(query, _sessionToken);
        if (!mounted || seq != _sequence) return;
        setState(() {
          _results = places;
          _loading = false;
          _message = places.isEmpty ? 'No results. Try a more specific address.' : null;
        });
      } catch (_) {
        if (!mounted || seq != _sequence) return;
        setState(() {
          _loading = false;
          _results = const [];
          _message = 'Search unavailable. Close this window and tap the map to select a location.';
        });
      }
    });
  }

  Future<void> _select(Care360PlaceSuggestion place) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final selected = await _gateway.resolve(place.id, _sessionToken);
      if (!mounted) return;
      Navigator.of(context).pop(selected);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _message = 'Could not load this address. Choose another or select a point on the map.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Expanded(child: Text('Search for an address',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              IconButton(
                key: const Key('places-search-close'),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Close address search',
                icon: const Icon(Icons.close),
              ),
            ]),
            TextField(
              key: const Key('care360-place-query'),
              controller: _query,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Street, area or facility',
                hintText: 'e.g. Keffi General Hospital',
                border: OutlineInputBorder(),
              ),
              onChanged: _schedule,
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_message!, style: const TextStyle(
                    color: Color(0xFF713C13)), textAlign: TextAlign.center),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight:
                  MediaQuery.sizeOf(context).height * .43),
              child: ListView.builder(
                key: const Key('care360-place-results'),
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final entry = _results[index];
                  return ListTile(
                    key: Key('care360-place-$index'),
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(entry.label),
                    onTap: _loading ? null : () => _select(entry),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Place suggestions by Google. Only the address you select is saved.',
              style: TextStyle(fontSize: 11, color: Color(0xFF526F77)),
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Select manually on map'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Care360PlaceSelection?> showCare360PlaceSearch(BuildContext context) {
  return showModalBottomSheet<Care360PlaceSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const Care360PlaceSearchSheet(),
  );
}
