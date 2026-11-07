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
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../const/Palette.dart';

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
  bool _canShowUserLocation = false;
  String _selectedType = 'All';
  String? _lat;
  String? _lang;
  GoogleMapController? _mapController;
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

  // Custom marker hues: doctor = blue, provider = orange, hospital = red/rose, lab = green
  static const double _hueDoctor = BitmapDescriptor.hueAzure;
  static const double _hueProvider = BitmapDescriptor.hueOrange;
  static const double _hueHospital = BitmapDescriptor.hueRose;
  static const double _hueLab = BitmapDescriptor.hueGreen;
  static const double _hueUser = BitmapDescriptor.hueViolet;

  BitmapDescriptor? _markerDoctor;
  BitmapDescriptor? _markerProvider;
  BitmapDescriptor? _markerHospital;
  BitmapDescriptor? _markerLab;
  BitmapDescriptor? _markerUser;

  @override
  void initState() {
    super.initState();
    _createMarkerIcons();
    _loadLocationAndData();
  }

  void _createMarkerIcons() {
    _markerDoctor = BitmapDescriptor.defaultMarkerWithHue(_hueDoctor);
    _markerProvider = BitmapDescriptor.defaultMarkerWithHue(_hueProvider);
    _markerHospital = BitmapDescriptor.defaultMarkerWithHue(_hueHospital);
    _markerLab = BitmapDescriptor.defaultMarkerWithHue(_hueLab);
    _markerUser = BitmapDescriptor.defaultMarkerWithHue(_hueUser);
  }

  Future<void> _loadLocationAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionGranted = (await Permission.location.status).isGranted;
    if (!mounted) return;
    setState(() {
      _lat = prefs.getString('lat');
      _lang = prefs.getString('lang');
      _canShowUserLocation = permissionGranted;
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

  BitmapDescriptor _icon(BitmapDescriptor? custom) =>
      custom ?? BitmapDescriptor.defaultMarker;

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};
    final userLat = double.tryParse(_lat ?? '');
    final userLng = double.tryParse(_lang ?? '');
    if (userLat != null && userLng != null) {
      markers.add(
        Marker(
          markerId: MarkerId('user'),
          position: LatLng(userLat, userLng),
          icon: _icon(_markerUser),
          infoWindow: InfoWindow(title: 'Your location'),
        ),
      );
    }
    for (final doctor in doctorList) {
      if (doctor.lat != null && doctor.lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('doctor_${doctor.id}'),
            position: LatLng(doctor.lat!, doctor.lng!),
            icon: _icon(_markerDoctor),
            infoWindow: InfoWindow(
              title: doctor.name ?? 'Doctor',
              snippet: doctor.treatment?.name,
            ),
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
    for (final provider in providerList) {
      final lat = _parseCoord(provider.lat);
      final lng = _parseCoord(provider.lng);
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('provider_${provider.id}'),
            position: LatLng(lat, lng),
            icon: _icon(_markerProvider),
            infoWindow: InfoWindow(
              title: provider.name ?? 'Provider',
              snippet: provider.providerType?.name,
            ),
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
    for (final hospital in hospitalList) {
      final lat = _parseCoord(hospital.lat);
      final lng = _parseCoord(hospital.lng);
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('hospital_${hospital.id}'),
            position: LatLng(lat, lng),
            icon: _icon(_markerHospital),
            infoWindow: InfoWindow(title: hospital.name ?? 'Hospital', snippet: hospital.address),
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
    for (final lab in labList) {
      final lat = _parseCoord(lab.lat);
      final lng = _parseCoord(lab.lng);
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            markerId: MarkerId('lab_${lab.id}'),
            position: LatLng(lat, lng),
            icon: _icon(_markerLab),
            infoWindow: InfoWindow(title: lab.name ?? 'Lab', snippet: lab.address),
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
        inAsyncCall: loading,
        opacity: 0.6,
        progressIndicator: SpinKitFadingCircle(color: Palette.blue, size: 50),
        child: Builder(
          builder: (context) {
            if (_lat == null || _lat!.isEmpty || _lang == null || _lang!.isEmpty) {
              return _buildNoLocationView();
            }
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _getInitialPosition(),
                      zoom: 12,
                    ),
                    markers: _buildMarkers(),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    onMapCreated: (c) => _mapController = c,
                    padding: EdgeInsets.only(bottom: 140),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _buildLegendCard(),
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
              'Enable location and open Home first so we can show doctors, hospitals and labs near you on the map.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.grey, fontSize: 15, height: 1.4),
            ),
          ],
        ),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _legendItem(Icons.person_pin_circle_rounded, Palette.blue, 'Doctor'),
              _legendItem(Icons.local_hospital_rounded, Color(0xFFE91E63), 'Hospital'),
              _legendItem(Icons.science_rounded, Palette.green, 'Lab'),
              _legendItem(Icons.my_location_rounded, Color(0xFF9C27B0), 'You'),
            ],
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

  Widget _buildSummaryCard() {
    final doctorsCount = doctorList.where((d) => d.lat != null && d.lng != null).length;
    final hospitalsCount = hospitalList.where((h) => _parseCoord(h.lat) != null && _parseCoord(h.lng) != null).length;
    final labsCount = labList.where((l) => _parseCoord(l.lat) != null && _parseCoord(l.lng) != null).length;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.dash_line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Tap a marker to see details',
              style: TextStyle(
                color: Palette.grey,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _summaryChip(doctorsCount, 'Doctor', Palette.blue),
                SizedBox(width: 10),
                _summaryChip(hospitalsCount, 'Hospital', Color(0xFFE91E63)),
                SizedBox(width: 10),
                _summaryChip(labsCount, 'Lab', Palette.green),
              ],
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
