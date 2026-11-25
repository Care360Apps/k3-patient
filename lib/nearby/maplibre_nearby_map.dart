import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'maplibre_marker_adapter.dart';

class MapLibreNearbyMap extends StatefulWidget {
  const MapLibreNearbyMap({super.key, required this.style,
    required this.latitude, required this.longitude, required this.pins});
  final String style;
  final double latitude, longitude;
  final List<NearbyMapPin> pins;

  @override
  State<MapLibreNearbyMap> createState() => _MapLibreNearbyMapState();
}

class _MapLibreNearbyMapState extends State<MapLibreNearbyMap> {
  ml.MapLibreMapController? _controller;
  bool _ready = false;
  bool _busy = false;
  bool _dirty = false;
  bool _failed = false;
  final _callbacks = <String, NearbyMapPin>{};

  @override
  void didUpdateWidget(covariant MapLibreNearbyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  Future<void> _sync() async {
    _dirty = true;
    if (!_ready || _busy || !mounted) return;
    _busy = true;
    try {
      while (_dirty && mounted) {
        _dirty = false;
        final controller = _controller!;
        final pins = List<NearbyMapPin>.of(widget.pins);
        _callbacks.clear();
        await controller.clearCircles();
        for (final pin in pins) {
          if (!mounted || _dirty) break;
          final circle = await controller.addCircle(ml.CircleOptions(
            geometry: ml.LatLng(pin.latitude, pin.longitude),
            circleRadius: 9,
            circleColor: '#1769AA',
            circleStrokeColor: '#FFFFFF',
            circleStrokeWidth: 2,
          ));
          if (mounted && !_dirty) _callbacks[circle.id] = pin;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      _busy = false;
    }
  }

  void _tap(ml.Circle circle) {
    if (_busy || _dirty || !mounted) return;
    final pin = _callbacks[circle.id];
    if (pin == null || !widget.pins.any((p) => p.id == pin.id)) return;
    showModalBottomSheet<void>(context: context, builder: (sheet) =>
      SafeArea(child: ListTile(
        title: Text(pin.title),
        subtitle: pin.subtitle == null ? null : Text(pin.subtitle!),
        trailing: pin.onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: pin.onTap == null ? null : () {
          Navigator.pop(sheet);
          if (mounted && widget.pins.any((p) => p.id == pin.id)) pin.onTap!();
        },
      )));
  }

  @override
  void dispose() {
    _ready = false;
    _controller?.onCircleTapped.remove(_tap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const Center(child: Text(
      'Map unavailable. Nearby care listings remain accessible.'));
    return ml.MapLibreMap(
      styleString: widget.style,
      initialCameraPosition: ml.CameraPosition(
        target: ml.LatLng(widget.latitude, widget.longitude), zoom: 12),
      onMapCreated: (controller) {
        _controller = controller;
        controller.onCircleTapped.add(_tap);
      },
      onStyleLoadedCallback: () {
        _ready = true;
        _sync();
      },
    );
  }
}
