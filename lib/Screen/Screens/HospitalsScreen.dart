import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../nearby/maplibre_configuration.dart';
import '../../nearby/maplibre_marker_adapter.dart';
import '../../nearby/maplibre_nearby_map.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../nearby/facility_directory_gateway.dart';

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});
  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final _gateway = FacilityDirectoryGateway();
  final _search = TextEditingController();
  String _state = 'FCT';
  String _type = 'hospital';
  bool _loading = false;
  String? _error;
  List<DirectoryFacility> _facilities = [];
  int _requestId = 0;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _requestId++; _search.dispose(); super.dispose(); }

  Future<void> _load({bool append = false}) async {
    if (append && (_loading || !_hasMore)) return;
    final nextPage = append ? _page + 1 : 1;
    final request = ++_requestId;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _gateway.search(state: _state, type: _type, query: _search.text, page: nextPage);
      if (!mounted || request != _requestId) return;
      setState(() {
        _facilities = append ? [..._facilities, ...data] : data;
        _page = nextPage;
        _hasMore = data.length == 50;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _requestId) return;
      setState(() { _error = 'Unable to load verified facilities. Please retry.';
        _loading = false; if (!append) _facilities = []; });
    }
  }

  Future<void> _directions(DirectoryFacility f) async {
    if (f.latitude == null || f.longitude == null) return;
    final url = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1', 'destination': '${f.latitude},${f.longitude}',
    });
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final mapped = _facilities.where((f) => f.latitude != null && f.longitude != null
      && f.latitude!.abs() <= 90 && f.longitude!.abs() <= 180).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Find verified facilities')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(controller: _search, textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(labelText: 'Search facility name',
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: _load))),
          Row(children: [
            Expanded(child: DropdownButtonFormField<String>(value: _state,
              decoration: const InputDecoration(labelText: 'State'),
              items: ['FCT','Nasarawa','Plateau'].map((s) =>
                DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (s) { if (s != null) { setState(() => _state = s); _load(); } })),
            const SizedBox(width: 12),
            Expanded(child: DropdownButtonFormField<String>(value: _type,
              decoration: const InputDecoration(labelText: 'Facility'),
              items: const [DropdownMenuItem(value: 'hospital', child: Text('Hospitals')),
                DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacies'))],
              onChanged: (s) { if (s != null) { setState(() => _type = s); _load(); } })),
          ]),
        ])),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(12),
          child: Column(children: [Text(_error!), TextButton(onPressed: () => _load(append: _page > 0 && _facilities.isNotEmpty),
            child: const Text('Retry'))])),
        if (!_loading && _error == null && _facilities.isEmpty)
          const Padding(padding: EdgeInsets.all(16),
            child: Text('No reviewed facilities found for these filters.')),
        if (mapped.isNotEmpty) SizedBox(height: 220, child: MapLibreConfiguration.available
          ? MapLibreNearbyMap(
              style: MapLibreConfiguration.style,
              latitude: mapped.first.latitude!,
              longitude: mapped.first.longitude!,
              zoom: 10,
              showRecenter: false,
              pins: mapped.map((facility) => NearbyMapPin(
                id: '${facility.id}',
                latitude: facility.latitude!,
                longitude: facility.longitude!,
                title: facility.name,
                subtitle: facility.address ?? facility.state,
              )).toList(growable: false),
            )
          : GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(mapped.first.latitude!, mapped.first.longitude!), zoom: 10),
          myLocationEnabled: false, myLocationButtonEnabled: false,
          markers: mapped.map((f) => Marker(markerId: MarkerId('${f.id}'),
            position: LatLng(f.latitude!, f.longitude!),
            infoWindow: InfoWindow(title: f.name, snippet: f.address ?? f.state))).toSet(),
        )),
        Expanded(child: ListView.builder(itemCount: _facilities.length + (_hasMore && _facilities.isNotEmpty ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _facilities.length) {
              return TextButton(onPressed: _loading ? null : () => _load(append: true),
                child: const Text('Load more facilities'));
            }
            final f = _facilities[index];
            return ListTile(title: Text(f.name),
              subtitle: Text('${f.state} • ${f.address ?? 'Address unavailable'}'),
              trailing: f.latitude != null && f.longitude != null
                ? IconButton(tooltip: 'Directions', icon: const Icon(Icons.directions),
                    onPressed: () => _directions(f)) : null);
          })),
      ]),
    );
  }
}
