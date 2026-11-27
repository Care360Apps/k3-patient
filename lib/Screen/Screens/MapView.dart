import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/const/prefConstatnt.dart';
import 'package:doctro_patient/const/preference.dart';
import 'package:doctro_patient/database/form_helper.dart';
import 'package:doctro_patient/model/doctors_model.dart';
import 'package:doctro_patient/model/labs_model.dart';
import 'package:doctro_patient/model/providers_model.dart';
import 'package:doctro_patient/Screen/Doctor/doctordetail.dart';
import 'package:doctro_patient/Screen/Provider/ProviderDetail.dart';
import 'package:doctro_patient/Screen/Screens/Laboratory.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' show LatLng;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../const/Palette.dart';
import '../../nearby/nearby_on_duty_service.dart';
import '../../nearby/maplibre_configuration.dart';
import '../../nearby/maplibre_marker_adapter.dart';
import '../../nearby/maplibre_nearby_map.dart';

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  List<DoctorModel> doctorList = [];
  List<HospitalData> hospitalList = [];
  List<LabData> labList = [];
  List<ProviderModel> providerList = [];
  bool loading = true;
  bool _onDutyOnly = false;
  bool _onDutyLoading = false;
  bool _onDutyError = false;
  String? _selectedVisitType;
  List<NearbyOnDutyProfessional> _onDuty = [];
  int _onDutyFetchId = 0;
  Timer? _presenceExpiryTimer;
  String _selectedType = 'All';
  String? _lat;
  String? _lang;
  // Nigeria fallback only; never presented as the patient's actual location.
  static const LatLng _defaultCenter = LatLng(9.0820, 8.6753);

  @override
  void initState() {
    super.initState();
    _loadLocationAndData();
  }

  @override
  void dispose() {
    _onDutyFetchId++;
    _presenceExpiryTimer?.cancel();
    super.dispose();
  }

  void _scheduleExpiry() {
    _presenceExpiryTimer?.cancel();
    if (!mounted || !_onDutyOnly || _onDuty.isEmpty) return;
    final now = DateTime.now().toUtc();
    final future = _onDuty
        .where((p) => p.expiresAt.isAfter(now))
        .map((p) => p.expiresAt)
        .toList()..sort();
    if (future.isEmpty) {
      setState(() => _onDuty.clear());
      return;
    }
    _presenceExpiryTimer = Timer(future.first.difference(now), () {
      if (!mounted || !_onDutyOnly) return;
      setState(() => _onDuty.removeWhere((p) => !p.isStillAccepting));
      _scheduleExpiry();
    });
  }

  Future<void> _loadLocationAndData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _lat = prefs.getString('lat');
      _lang = prefs.getString('lang');
    });
    await _fetchAll();
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() => loading = true);
    try {
      await Future.wait([
        _fetchDoctors(),
        _fetchProviders(),
        _fetchHospitals(),
        _fetchLabs(),
      ]);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _fetchDoctors() async {
    if (_lat == null || _lat!.isEmpty || _lang == null || _lang!.isEmpty) {
      doctorList = [];
      return;
    }
    try {
      final body = {'lat': _lat, 'lang': _lang};
      final response = SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true
          ? await RestClient(RetroApi().dioData()).doctorList(body)
          : await RestClient(RetroApi2().dioData2()).doctorList(body);
      final doctors = response.data ?? [];
      doctors.sort((a, b) {
        final da = _distanceKmForDoctor(a) ?? double.infinity;
        final db = _distanceKmForDoctor(b) ?? double.infinity;
        return da.compareTo(db);
      });
      if (mounted) setState(() => doctorList = doctors);
    } catch (_) {
      if (mounted) setState(() => doctorList = []);
    }
  }

  Future<void> _fetchProviders() async {
    if (_lat == null || _lat!.isEmpty || _lang == null || _lang!.isEmpty) {
      providerList = [];
      return;
    }
    try {
      final body = {
        'lat': _lat,
        'lang': _lang,
        'limit': 50, // API validates a maximum of 50; 100 returned HTTP 422.
      };
      final response = await RestClient(RetroApi2().dioData2()).providersRequest(body);
      final list = response.data ?? [];
      list.sort((a, b) {
        final da = _distanceKmForProvider(a) ?? double.infinity;
        final db = _distanceKmForProvider(b) ?? double.infinity;
        return da.compareTo(db);
      });
      if (mounted) setState(() => providerList = list);
    } catch (_) {
      if (mounted) setState(() => providerList = []);
    }
  }

  Future<void> _fetchHospitals() async {
    try {
      final response = await RestClient(RetroApi2().dioData2()).hospitalsRequest();
      final list = response.data ?? [];
      list.sort((a, b) {
        final da = _distanceKmForHospital(a) ?? double.infinity;
        final db = _distanceKmForHospital(b) ?? double.infinity;
        return da.compareTo(db);
      });
      if (mounted) setState(() => hospitalList = list);
    } catch (_) {
      if (mounted) setState(() => hospitalList = []);
    }
  }

  Future<void> _fetchLabs() async {
    try {
      final response = await RestClient(RetroApi2().dioData2()).labsRequest();
      final list = response.data ?? [];
      list.sort((a, b) {
        final da = _distanceKmForLab(a) ?? double.infinity;
        final db = _distanceKmForLab(b) ?? double.infinity;
        return da.compareTo(db);
      });
      if (mounted) setState(() => labList = list);
    } catch (_) {
      if (mounted) setState(() => labList = []);
    }
  }

  Future<void> _toggleOnDuty(bool enabled) async {
    if (!mounted) return;
    _onDutyFetchId++;
    _presenceExpiryTimer?.cancel();
    setState(() {
      _onDutyOnly = enabled;
      _selectedType = 'All';
      _selectedVisitType = null;
      _onDutyError = false;
      if (!enabled) {
        _onDuty = [];
        _onDutyLoading = false;
      }
    });
    if (enabled) await _fetchOnDuty();
  }

  Future<void> _fetchOnDuty() async {
    final requestId = ++_onDutyFetchId;
    final lat = double.tryParse(_lat ?? '');
    final lng = double.tryParse(_lang ?? '');
    if (lat == null || lng == null || lat < -90 || lat > 90 ||
        lng < -180 || lng > 180) {
      if (mounted && _onDutyOnly && requestId == _onDutyFetchId) setState(() {
        _onDuty = [];
        _onDutyError = true;
      });
      return;
    }
    if (mounted) setState(() {
      _onDutyLoading = true;
      _onDutyError = false;
    });
    try {
      final matches = await const NearbyOnDutyService().find(
        lat: lat, lng: lng, visitType: _selectedVisitType);
      if (mounted && _onDutyOnly && requestId == _onDutyFetchId) {
        setState(() => _onDuty = matches.where((p) => p.isStillAccepting).toList());
        _scheduleExpiry();
      }
    } catch (_) {
      // Missing endpoint or network failure must never create fake
      // availability or reveal precise patient coordinates in debug logs.
      if (mounted && _onDutyOnly && requestId == _onDutyFetchId) {
        setState(() {
          _onDutyError = true;
          _onDuty = [];
        });
      }
    } finally {
      if (mounted && _onDutyOnly && requestId == _onDutyFetchId) {
        setState(() => _onDutyLoading = false);
      }
    }
  }

  double? _distanceKmFromUser(double? lat, double? lng) {
    if (lat == null || lng == null || lat == 0 && lng == 0 ||
        lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    final userLat = double.tryParse(_lat ?? '');
    final userLng = double.tryParse(_lang ?? '');
    if (userLat == null || userLng == null ||
        userLat < -90 || userLat > 90 || userLng < -180 || userLng > 180) {
      return null;
    }
    const earthRadiusKm = 6371.0;
    final dLat = (lat - userLat) * (pi / 180.0);
    final dLon = (lng - userLng) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(userLat * (pi / 180.0)) * cos(lat * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double? _distanceKmForDoctor(DoctorModel d) {
    final dFromApi = d.distanceKm != null ? double.tryParse(d.distanceKm!.trim()) : null;
    if (dFromApi != null && dFromApi.isFinite && dFromApi >= 0) return dFromApi;
    return _distanceKmFromUser(d.lat, d.lng);
  }

  double? _distanceKmForProvider(ProviderModel p) {
    final dFromApi = p.distanceKm != null ? double.tryParse(p.distanceKm!.trim()) : null;
    if (dFromApi != null && dFromApi.isFinite && dFromApi >= 0) return dFromApi;
    return _distanceKmFromUser(p.lat, p.lng);
  }

  double? _distanceKmForHospital(HospitalData h) {
    return _distanceKmFromUser(_parseCoord(h.lat), _parseCoord(h.lng));
  }

  double? _distanceKmForLab(LabData l) {
    return _distanceKmFromUser(_parseCoord(l.lat), _parseCoord(l.lng));
  }

  bool get _hasValidChosenLocation {
    final lat = double.tryParse(_lat ?? '');
    final lng = double.tryParse(_lang ?? '');
    return lat != null && lng != null &&
        lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  LatLng _getInitialPosition() {
    final lat = double.tryParse(_lat ?? '');
    final lng = double.tryParse(_lang ?? '');
    if (lat != null && lng != null &&
        lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
      return LatLng(lat, lng);
    }
    return _defaultCenter;
  }

  double? _parseCoord(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty || s == 'N_A') return null;
    final n = double.tryParse(s);
    return n != null && n.isFinite ? n : null;
  }

  bool _showType(String type) => _selectedType == 'All' || _selectedType == type;

  List<NearbyMapPin> _buildMarkers() {
    final markers = <NearbyMapPin>[];
    final userLat = double.tryParse(_lat ?? '');
    final userLng = double.tryParse(_lang ?? '');
    if (userLat != null && userLng != null) {
      markers.add(
        NearbyMapPin(
          id: 'user',
          latitude: userLat, longitude: userLng,

          title: 'Your location',
        ),
      );
    }
    if (_onDutyOnly) {
      for (final professional in _onDuty.where((p) => p.isStillAccepting)) {
        if (!_showType(professional.role == 'doctor'
            ? 'Doctors' : 'Providers')) continue;
        markers.add(NearbyMapPin(
          id: 'on-duty-${professional.role}-${professional.id}',
          latitude: professional.lat, longitude: professional.lng,

            title: professional.name,
            subtitle: 'Accepting requests · about '
                '${professional.distanceKm.toStringAsFixed(1)} km',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => professional.role == 'doctor'
                  ? DoctorDetail(id: professional.id)
                  : ProviderDetail(id: professional.id),
            ));
          },
        ));
      }
      return markers;
    }
    if (_showType('Doctors')) for (final doctor in doctorList) {
      if (doctor.lat != null && doctor.lng != null) {
        markers.add(
          NearbyMapPin(
            id: 'doctor_${doctor.id}',
            latitude: doctor.lat!, longitude: doctor.lng!,

              title: doctor.name ?? 'Doctor',
              subtitle: doctor.treatment?.name,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetail(id: doctor.id),
                ),
              );
            },
          ),
        );
      }
    }
    if (_showType('Providers')) for (final provider in providerList) {
      final lat = _parseCoord(provider.lat);
      final lng = _parseCoord(provider.lng);
      if (lat != null && lng != null) {
        markers.add(
          NearbyMapPin(
            id: 'provider_${provider.id}',
            latitude: lat, longitude: lng,

              title: provider.name ?? 'Provider',
              subtitle: provider.providerType?.name,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProviderDetail(id: provider.id),
                ),
              );
            },
          ),
        );
      }
    }
    if (_showType('Hospitals')) for (final hospital in hospitalList) {
      final lat = _parseCoord(hospital.lat);
      final lng = _parseCoord(hospital.lng);
      if (lat != null && lng != null) {
        markers.add(
          NearbyMapPin(
            id: 'hospital_${hospital.id}',
            latitude: lat, longitude: lng,

            title: hospital.name ?? 'Hospital', subtitle: hospital.address,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HospitalDetailScreen(hospital: hospital),
                ),
              );
            },
          ),
        );
      }
    }
    if (_showType('Labs')) for (final lab in labList) {
      final lat = _parseCoord(lab.lat);
      final lng = _parseCoord(lab.lng);
      if (lat != null && lng != null) {
        markers.add(
          NearbyMapPin(
            id: 'lab_${lab.id}',
            latitude: lat, longitude: lng,

            title: lab.name ?? 'Lab', subtitle: lab.address,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LabDetailScreen(lab: lab),
                ),
              );
            },
          ),
        );
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.dark_white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Palette.white, size: 22),
          onPressed: () => Navigator.pushReplacementNamed(context, 'Home'),
        ),
        title: Text(
          'Map View',
          style: TextStyle(
            color: Palette.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Palette.blue,
        foregroundColor: Palette.white,
        elevation: 0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: loading || _onDutyLoading,
        opacity: 0.6,
        progressIndicator: SpinKitFadingCircle(color: Palette.blue, size: 50),
        child: Builder(
          builder: (context) {
            if (!_hasValidChosenLocation) {
              return _buildNoLocationView();
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  child: MapLibreNearbyMap(
                    latitude: _getInitialPosition().latitude,
                    longitude: _getInitialPosition().longitude,
                    pins: _buildMarkers(),
                    showAttribution: false,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      _buildCategoryFilters(),
                      if (_onDutyOnly) ...[
                        const SizedBox(height: 8),
                        _buildServiceFilters(),
                      ],
                      const SizedBox(height: 8),
                      _buildLegendCard(),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildSummaryCard(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoLocationView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 72, color: Palette.grey),
            SizedBox(height: 24),
            Text(
              'Location required',
              style: TextStyle(
                color: Palette.dark_blue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Choose a location in Care360 Home to find nearby doctors, care providers, hospitals and labs. You can browse without granting precise GPS access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.grey, fontSize: 15, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              key: const Key('nearby-on-duty-filter'),
              label: const Text('Accepting requests'),
              selected: _onDutyOnly,
              showCheckmark: false,
              onSelected: _toggleOnDuty,
            ),
          ),
          for (final type in (_onDutyOnly
              ? const ['All', 'Doctors', 'Providers']
              : const ['All', 'Doctors', 'Providers', 'Hospitals', 'Labs']))
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                key: Key('nearby-filter-${type.toLowerCase()}'),
                label: Text(type),
                selected: _selectedType == type,
                showCheckmark: false,
                onSelected: (_) => setState(() => _selectedType = type),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _buildServiceFilters() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Row(children: [
          _serviceFilterChip(null, 'All services', 'all'),
          _serviceFilterChip('home_visit', 'Home visits', 'home'),
          _serviceFilterChip('video_call', 'Virtual care', 'virtual'),
        ]),
      ),
    );
  }

  Widget _serviceFilterChip(String? type, String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        key: Key('nearby-service-$key'),
        label: Text(label),
        selected: _selectedVisitType == type,
        showCheckmark: false,
        onSelected: (_) {
          if (!_onDutyOnly || _onDutyLoading) return;
          setState(() {
            _selectedVisitType = type;
            // Old pins must not remain visible under a different service.
            _onDuty = [];
          });
          _presenceExpiryTimer?.cancel();
          _fetchOnDuty();
        },
      ),
    );
  }

  Widget _buildLegendCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Palette.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendItem(Icons.person_pin_circle_rounded, Palette.blue, 'Doctor'),
              _legendItem(Icons.health_and_safety_outlined, const Color(0xFFFF8C00), 'Provider'),
              _legendItem(Icons.local_hospital_rounded, const Color(0xFFE91E63), 'Hospital'),
              _legendItem(Icons.science_rounded, Palette.green, 'Lab'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 6),
        Text(label, style: TextStyle(color: Palette.dark_blue, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  List<_NearbyCareOption> _nearestCare() {
    final result = <_NearbyCareOption>[];
    if (_onDutyOnly) {
      for (final professional in _onDuty.where((p) => p.isStillAccepting)) {
        if (!_showType(professional.role == 'doctor'
            ? 'Doctors' : 'Providers')) continue;
        result.add(_NearbyCareOption(
          title: professional.name,
          type: professional.role == 'doctor'
              ? 'Doctor · accepting requests'
              : 'Provider · accepting requests',
          distanceKm: professional.distanceKm,
          onOpen: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => professional.role == 'doctor'
                  ? DoctorDetail(id: professional.id)
                  : ProviderDetail(id: professional.id))),
        ));
      }
      result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return result.take(8).toList();
    }
    if (_showType('All') || _showType('Doctors')) {
      for (final doctor in doctorList) {
        if (doctor.id == null) continue;
        final distance = _distanceKmForDoctor(doctor);
        if (distance == null || !distance.isFinite || distance < 0) continue;
        result.add(_NearbyCareOption(
          title: doctor.name ?? 'Doctor',
          type: 'Doctor',
          distanceKm: distance,
          onOpen: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => DoctorDetail(id: doctor.id))),
        ));
      }
    }
    if (_showType('All') || _showType('Providers')) {
      for (final provider in providerList) {
        if (provider.id == null) continue;
        final distance = _distanceKmForProvider(provider);
        if (distance == null || !distance.isFinite || distance < 0) continue;
        result.add(_NearbyCareOption(
          title: provider.name ?? 'Care provider',
          type: provider.providerType?.name ?? 'Care provider',
          distanceKm: distance,
          onOpen: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProviderDetail(id: provider.id))),
        ));
      }
    }
    result.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return result.take(8).toList();
  }

  Widget _buildSummaryCard() {
    final doctorsCount = _onDutyOnly
        ? _onDuty.where((p) => p.role == 'doctor' && p.isStillAccepting).length
        : doctorList.where((d) => _distanceKmForDoctor(d) != null).length;
    final providersCount = _onDutyOnly
        ? _onDuty.where((p) => p.role == 'provider' && p.isStillAccepting).length
        : providerList.where((p) => _distanceKmForProvider(p) != null).length;
    final hospitalsCount = _onDutyOnly ? 0 : hospitalList.where((h) =>
        _parseCoord(h.lat) != null && _parseCoord(h.lng) != null).length;
    final labsCount = _onDutyOnly ? 0 : labList.where((l) =>
        _parseCoord(l.lat) != null && _parseCoord(l.lng) != null).length;
    final nearest = _nearestCare();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MapLibreConfiguration.enabled)
              Text(MapLibreConfiguration.attribution, style: const TextStyle(fontSize: 12)),
            Center(child: Container(height: 4, width: 40,
              decoration: BoxDecoration(color: Palette.dash_line,
                  borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: [
                _summaryChip(doctorsCount, 'Doctors', Palette.blue),
                _summaryChip(providersCount, 'Providers', const Color(0xFFFF8C00)),
                _summaryChip(hospitalsCount, 'Hospitals', const Color(0xFFE91E63)),
                _summaryChip(labsCount, 'Labs', Palette.green),
              ],
            ),
            const SizedBox(height: 10),
            Text(_onDutyOnly
                ? 'Professionals accepting requests'
                : 'Closest care professionals',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            const Text('Approximate straight-line distance · booking requires confirmation',
              style: TextStyle(fontSize: 11, color: Colors.black54)),
            if (_onDutyOnly && _onDutyError) ...[
              const SizedBox(height: 8),
              const Text('The verified availability service is not enabled '
                'on this backend or is temporarily unreachable.',
                key: Key('nearby-on-duty-unavailable'),
                style: TextStyle(fontSize: 12, color: Colors.deepOrange)),
              TextButton.icon(
                onPressed: _onDutyLoading ? null : _fetchOnDuty,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: nearest.isEmpty
                  ? const Center(child: Text(
                      'No professionals are listed for this filter and location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: nearest.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 9),
                      itemBuilder: (context, index) {
                        final item = nearest[index];
                        return SizedBox(
                          width: 215,
                          child: OutlinedButton(
                            key: Key('nearby-professional-$index'),
                            onPressed: item.onOpen,
                            style: OutlinedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(item.title, maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(item.type, maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11)),
                                Text('~${item.distanceKm.toStringAsFixed(1)} km · View profile',
                                  style: const TextStyle(fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _summaryChip(int count, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(width: 4),
          Text(label, style: TextStyle(color: Palette.dark_blue, fontSize: 12)),
        ],
      ),
    );
  }
}
class _NearbyCareOption {
  const _NearbyCareOption({
    required this.title,
    required this.type,
    required this.distanceKm,
    required this.onOpen,
  });

  final String title;
  final String type;
  final double distanceKm;
  final VoidCallback onOpen;
}

