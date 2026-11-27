import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'maplibre_configuration.dart';
import 'maplibre_marker_adapter.dart';

class MapLibreNearbyMap extends StatefulWidget {
  const MapLibreNearbyMap({super.key, required this.style,
    required this.latitude, required this.longitude, required this.pins,
    this.zoom = 12, this.showRecenter = true, this.showAttribution = true,
    this.onPointSelected});
  final double zoom;
  final bool showRecenter;
  final bool showAttribution;
  final void Function(double latitude, double longitude)? onPointSelected;
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
  Timer? _loadTimeout;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _startTimeout();
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

  Future<void> _recenter() async {
    try {
      await _controller?.animateCamera(ml.CameraUpdate.newLatLng(
        ml.LatLng(widget.latitude, widget.longitude)));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  final _callbacks = <String, NearbyMapPin>{};

  @override
  void didUpdateWidget(covariant MapLibreNearbyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      if (_ready) _recenter();
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
          final circle = await controller.addCircle(ml.CircleOptions(
            geometry: ml.LatLng(pin.latitude, pin.longitude),
            circleRadius: 9,
            circleColor: _pinColor(pin.id),
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

  String _pinColor(String id) {
    if (id.startsWith('on-duty-')) return '#087F8C';
    if (id.startsWith('provider_')) return '#FF8C00';
    if (id.startsWith('hospital_')) return '#E91E63';
    if (id.startsWith('lab_')) return '#16834A';
    return '#1769AA';
  }

  void _tap(ml.Circle circle) {
    if (widget.onPointSelected != null || _busy || _dirty || !mounted) return;
    final pin = _callbacks[circle.id];
    if (pin == null || !widget.pins.any((p) => p.id == pin.id)) return;
    showModalBottomSheet<void>(context: context, builder: (sheet) =>
      SafeArea(child: ListTile(
        title: Text(pin.title),
        subtitle: pin.subtitle == null ? null : Text(pin.subtitle!),
        trailing: pin.onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: pin.onTap == null ? null : () {
          Navigator.pop(sheet);
          if (!mounted) return;
          for (final current in widget.pins) {
            if (current.id == pin.id) {
              current.onTap?.call();
              break;
            }
          }
        },
      )));
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
    if (_failed) return Center(child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Map unavailable.',
          textAlign: TextAlign.center),
        TextButton(onPressed: _busy ? null : _retry, child: const Text('Retry map')),
      ],
    ));
    final generation = _generation;
    return Stack(children: [
      ml.MapLibreMap(
      key: ValueKey(generation),
      styleString: widget.style,
      initialCameraPosition: ml.CameraPosition(
        target: ml.LatLng(widget.latitude, widget.longitude), zoom: widget.zoom),
      onMapClick: (_, point) {
        if (_ready) {
          widget.onPointSelected?.call(point.latitude, point.longitude);
        }
      },
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
      if (_ready && widget.showAttribution)
        Positioned(left: 12, bottom: 12, right: 12, child: Align(
          alignment: Alignment.bottomRight,
          child: _attribution(context),
        )),
      if (_ready && widget.showRecenter) Positioned(top: 72, right: 12,
        child: FloatingActionButton.small(
          heroTag: null, tooltip: 'Centre on selected location',
          onPressed: _recenter, child: const Icon(Icons.my_location))),
    ]);
  }

  Widget _attribution(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(4),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Text(MapLibreConfiguration.attribution,
        style: TextStyle(fontSize: 11)),
    ),
  );
}
