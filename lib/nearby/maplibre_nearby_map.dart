import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'maplibre_marker_adapter.dart';
import 'maplibre_configuration.dart';

class MapLibreNearbyMap extends StatefulWidget {
  const MapLibreNearbyMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.pins,
    this.zoom = 12,
    this.showRecenter = true,
    this.showAttribution = true,
    this.showDeviceLocation = false,
    this.onMapTap,
  });
  final double zoom;
  final bool showRecenter;
  final bool showAttribution;
  final bool showDeviceLocation;
  final ValueChanged<ml.LatLng>? onMapTap;
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
  Timer? _loadTimeout;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    if (MapLibreConfiguration.enabled) _startTimeout();
  }

  void _startTimeout() {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 25), () {
      if (mounted && !_ready) setState(() => _failed = true);
    });
  }

  void _retry() {
    _controller?.onCircleTapped.remove(_tap);
    _controller = null;
    _callbacks.clear();
    setState(() {
      _generation++;
      _ready = false;
      _failed = false;
    });
    _startTimeout();
  }

  Future<void> _recenter({bool updateZoom = false}) async {
    try {
      final center = ml.LatLng(widget.latitude, widget.longitude);
      final update = updateZoom
          ? ml.CameraUpdate.newLatLngZoom(center, widget.zoom)
          : ml.CameraUpdate.newLatLng(center);
      await _controller?.animateCamera(update);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  final _callbacks = <String, NearbyMapPin>{};

  @override
  void didUpdateWidget(covariant MapLibreNearbyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final zoomChanged = oldWidget.zoom != widget.zoom;
    if (_ready &&
        (zoomChanged ||
            oldWidget.latitude != widget.latitude ||
            oldWidget.longitude != widget.longitude)) {
      _recenter(updateZoom: zoomChanged);
    }
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
          if (!pin.latitude.isFinite ||
              !pin.longitude.isFinite ||
              pin.latitude.abs() > 90 ||
              pin.longitude.abs() > 180)
            continue;
          final circle = await controller.addCircle(
            ml.CircleOptions(
              geometry: ml.LatLng(pin.latitude, pin.longitude),
              circleRadius: 9,
              circleColor: _pinColor(pin.id),
              circleStrokeColor: '#FFFFFF',
              circleStrokeWidth: 2,
            ),
          );
          if (mounted && !_dirty) _callbacks[circle.id] = pin;
        }
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      _busy = false;
    }
  }

  String _pinColor(String id) {
    if (id == 'user') return '#7952AE';
    if (id.startsWith('on-duty-')) return '#087F8C';
    if (id.startsWith('provider_')) return '#FF8C00';
    if (id.startsWith('hospital_')) return '#E91E63';
    if (id.startsWith('lab_')) return '#16834A';
    return '#1769AA';
  }

  void _tap(ml.Circle circle) {
    if (_busy || _dirty || !mounted) return;
    final pin = _callbacks[circle.id];
    if (pin == null || !widget.pins.any((p) => p.id == pin.id)) return;
    if (widget.onMapTap != null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListTile(
          title: Text(pin.title),
          subtitle: pin.subtitle == null ? null : Text(pin.subtitle!),
          trailing: pin.onTap == null ? null : const Icon(Icons.chevron_right),
          onTap: pin.onTap == null
              ? null
              : () {
                  Navigator.pop(sheet);
                  if (!mounted) return;
                  for (final current in widget.pins) {
                    if (current.id == pin.id) {
                      current.onTap?.call();
                      break;
                    }
                  }
                },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _ready = false;
    _controller?.onCircleTapped.remove(_tap);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!MapLibreConfiguration.enabled) {
      return const Center(child: Text('Map unavailable.'));
    }
    if (_failed)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Map unavailable.', textAlign: TextAlign.center),
            TextButton(
              onPressed: _busy ? null : _retry,
              child: const Text('Retry map'),
            ),
          ],
        ),
      );
    final generation = _generation;
    return Stack(
      children: [
        ml.MapLibreMap(
          key: ValueKey(generation),
          styleString: MapLibreConfiguration.style,
          myLocationEnabled: widget.showDeviceLocation,
          onMapClick: (_, point) => widget.onMapTap?.call(point),
          initialCameraPosition: ml.CameraPosition(
            target: ml.LatLng(widget.latitude, widget.longitude),
            zoom: widget.zoom,
          ),
          onMapCreated: (controller) {
            if (!mounted || generation != _generation || _failed) return;
            _controller = controller;
            controller.onCircleTapped.add(_tap);
          },
          onStyleLoadedCallback: () {
            if (!mounted || generation != _generation || _failed) return;
            _loadTimeout?.cancel();
            setState(() => _ready = true);
            _sync();
          },
        ),
        if (!_ready) const Center(child: CircularProgressIndicator()),
        if (_ready && widget.showRecenter)
          Positioned(
            top: 12,
            right: 12,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Centre on selected location',
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
        if (_ready && widget.showAttribution)
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Text(
              MapLibreConfiguration.attribution,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                backgroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
