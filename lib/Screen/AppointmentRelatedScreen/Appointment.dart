import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Screen/MedicineAndPharmacy/Myprescription.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/model/appointments_model.dart';
import 'package:flutter/material.dart';
import 'package:doctro_patient/Chat/loading_view.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../localization/localization_constant.dart';
import '../../model/common_response.dart';
import '../../model/detail_setting_model.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../VideoCall/videocall.dart';
import 'AppointmentDetailScreen.dart';

class Appointment extends StatefulWidget {
  @override
  _AppointmentState createState() => _AppointmentState();
}

class _AppointmentState extends State<Appointment> with SingleTickerProviderStateMixin {
  bool loading = false;
  bool _cancelling = false;
  bool _loadFailed = false;
  bool _hasLoaded = false;

  List<UpcomingAppointment> upcomingAppointment = [];
  List<PastAppointment> pastAppointment = [];
  List<PendingAppointment> pendingAppointment = [];

  List<String> cancelReason = [];
  String reason = "";

  int? id = 0;
  int value = 0;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    callApiAppointment();
    callApiSetting();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _feedback(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _safe(String? value, {String fallback = "-"}) {
    if (value == null) return fallback;
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Color _statusColor(String statusUpper) {
    final pendingLabel = getTranslated(context, AppString.appointment_pending).toString().toUpperCase();
    final cancelLabel = getTranslated(context, AppString.appointment_cancel).toString().toUpperCase();
    if (statusUpper == pendingLabel) return Palette.dark_blue.withOpacity(0.6);
    if (statusUpper == cancelLabel || statusUpper == 'CANCELED' || statusUpper == 'CANCEL') return Palette.red;
    return Palette.green;
  }

  String _formatStatus(String statusUpper, {required String tabType}) {
    if (tabType == 'past') {
      if (statusUpper == 'CANCEL') return 'CANCELED';
      if (statusUpper == 'COMPLETE') return 'COMPLETED';
      if (statusUpper == 'APPROVE') return 'APPROVED';
    } else if (tabType == 'upcoming') {
      if (statusUpper == 'APPROVE') return 'APPROVED';
    }
    return statusUpper;
  }

  Widget _buildAppointmentCard({
    required double width,
    required double height,
    required String? doctorImage,
    required String doctorName,
    required String? treatmentName,
    required String? hospitalName,
    required String? hospitalAddress,
    required String bookingId,
    required String statusLabel,
    required Color statusColor,
    required String date,
    required String time,
    required String patientName,
    required String? visitType,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: Palette.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Palette.dash_line),
              boxShadow: [
                BoxShadow(
                  color: Palette.dark_blue.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Palette.blue.withOpacity(0.2), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: doctorImage != null && doctorImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: doctorImage,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: Palette.dark_white,
                                    child: Center(child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.blue))),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    color: Palette.dark_white,
                                    child: Icon(Icons.person, color: Palette.grey, size: 26),
                                  ),
                                )
                              : Container(
                                  color: Palette.dark_white,
                                  child: Icon(Icons.person, color: Palette.grey, size: 26),
                                ),
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctorName,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (treatmentName != null && treatmentName.isNotEmpty) ...[
                              SizedBox(height: 2),
                              Text(
                                treatmentName,
                                style: TextStyle(fontSize: 12, color: Palette.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (hospitalName != null && hospitalName.isNotEmpty) ...[
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.local_hospital_rounded, size: 12, color: Palette.grey),
                                  SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hospitalName,
                                      style: TextStyle(fontSize: 11, color: Palette.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) trailing,
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Container(height: 1, color: Palette.dash_line),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _infoChip(
                          icon: Icons.calendar_today_rounded,
                          label: '$date  $time',
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel.isEmpty ? '-' : statusLabel,
                          style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        ),
                      ),
                      if (visitType != null && visitType.isNotEmpty) ...[
                        SizedBox(width: 8),
                        Icon(
                          visitType == 'home_visit' ? Icons.home_rounded : Icons.videocam_rounded,
                          size: 16,
                          color: Palette.blue,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Palette.dark_white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.dash_line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Palette.blue),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Palette.dark_blue, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_loadFailed || !_hasLoaded) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(loading ? 'Loading appointments…' : 'Unable to load appointments.'),
        if (!loading) TextButton(onPressed: callApiAppointment, child: const Text('Try again')),
      ]));
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 72,
              decoration: BoxDecoration(
                color: Palette.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy_rounded, size: 36, color: Palette.blue.withOpacity(0.4)),
            ),
            SizedBox(height: 16),
            Text(
              getTranslated(context, AppString.appointment_appointmentNotAvailable).toString(),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Palette.dark_blue),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(int appointmentIndex, {required String tabType}) {
    if (_cancelling) return;
    final appointmentId = tabType == 'pending' ? pendingAppointment[appointmentIndex].id : upcomingAppointment[appointmentIndex].id;
    value = 0;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: Palette.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: Palette.red.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.event_busy_rounded, color: Palette.red, size: 26),
                    ),
                    SizedBox(height: 14),
                    Text(
                      getTranslated(context, AppString.appointment_whyCancelAppointment).toString(),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Palette.dark_blue),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 14),
                    Container(
                      constraints: BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: cancelReason.length,
                        itemBuilder: (_, i) {
                          return RadioListTile(
                            value: i,
                            groupValue: value,
                            activeColor: Palette.blue,
                            onChanged: (int? v) {
                              setDialogState(() { value = v!; });
                            },
                            title: Text(cancelReason[i], style: TextStyle(fontSize: 14, color: Palette.dark_blue)),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: Palette.dash_line),
                            ),
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              getTranslated(context, AppString.bookAppointment_no).toString(),
                              style: TextStyle(fontSize: 14, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Palette.red,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () {
                              if (_cancelling) return;
                              id = appointmentId;
                              reason = cancelReason.isNotEmpty && value < cancelReason.length ? cancelReason[value] : "";
                              Navigator.pop(dialogContext);
                              callApiCancelAppointment();
                            },
                            child: Text(
                              getTranslated(context, AppString.bookAppointment_yes).toString(),
                              style: TextStyle(fontSize: 14, color: Palette.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingTab(double width, double height) {
    if (pendingAppointment.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      color: Palette.blue,
      onRefresh: callApiAppointment,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 8, bottom: 40),
        itemCount: pendingAppointment.length,
        itemBuilder: (context, index) {
          final a = pendingAppointment[index];
          final statusUpper = (a.appointmentStatus ?? '').toUpperCase();
          final sColor = _statusColor(statusUpper);
          return _buildAppointmentCard(
            width: width,
            height: height,
            doctorImage: a.doctor?.fullImage,
            doctorName: _safe(a.doctor?.name),
            treatmentName: a.doctor?.treatment?.name,
            hospitalName: a.hospital?.name,
            hospitalAddress: a.hospital?.address,
            bookingId: _safe(a.appointmentId),
            statusLabel: statusUpper,
            statusColor: sColor,
            date: _safe(a.date),
            time: _safe(a.time),
            patientName: _safe(a.patientName),
            visitType: a.visitType,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointmentId: a.id!)));
            },
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert_rounded, color: Palette.grey, size: 22),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 1,
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Palette.red, size: 18),
                      SizedBox(width: 8),
                      Text(getTranslated(context, AppString.appointment_cancelAppointment).toString(), style: TextStyle(color: Palette.red, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              onSelected: (v) {
                if (v == 1) _showCancelDialog(index, tabType: 'pending');
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingTab(double width, double height) {
    if (upcomingAppointment.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      color: Palette.blue,
      onRefresh: callApiAppointment,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 8, bottom: 40),
        itemCount: upcomingAppointment.length,
        itemBuilder: (context, index) {
          final a = upcomingAppointment[index];
          final statusUpper = (a.appointmentStatus ?? '').toUpperCase();
          final displayStatus = _formatStatus(statusUpper, tabType: 'upcoming');
          final sColor = _statusColor(statusUpper);

          final showVideoCall = (a.visitType ?? '') == 'video_call' &&
              statusUpper == 'APPROVE' &&
              a.doctorId != null &&
              SharedPreferenceHelper.getBoolean(Preferences.is_logged_in) == true;

          return _buildAppointmentCard(
            width: width,
            height: height,
            doctorImage: a.doctor?.fullImage,
            doctorName: _safe(a.doctor?.name),
            treatmentName: a.doctor?.treatment?.name,
            hospitalName: a.hospital?.name,
            hospitalAddress: a.hospital?.address,
            bookingId: _safe(a.appointmentId),
            statusLabel: displayStatus,
            statusColor: sColor,
            date: _safe(a.date),
            time: _safe(a.time),
            patientName: _safe(a.patientName),
            visitType: a.visitType,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointmentId: a.id!)));
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showVideoCall)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => VideoCall(doctorId: a.doctorId, flag: 'from_appointment')));
                    },
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: Palette.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.videocam_rounded, color: Palette.blue, size: 20),
                    ),
                  ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded, color: Palette.grey, size: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 1,
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Palette.red, size: 18),
                          SizedBox(width: 8),
                          Text(getTranslated(context, AppString.appointment_cancelAppointment).toString(), style: TextStyle(color: Palette.red, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (v) {
                    if (v == 1) _showCancelDialog(index, tabType: 'upcoming');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPastTab(double width, double height) {
    if (pastAppointment.isEmpty) return _buildEmptyState();
    return RefreshIndicator(
      color: Palette.blue,
      onRefresh: callApiAppointment,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: 8, bottom: 40),
        itemCount: pastAppointment.length,
        itemBuilder: (context, index) {
          final a = pastAppointment[index];
          final statusUpper = (a.appointmentStatus ?? '').toUpperCase();
          final displayStatus = _formatStatus(statusUpper, tabType: 'past');
          final sColor = _statusColor(statusUpper);

          return _buildAppointmentCard(
            width: width,
            height: height,
            doctorImage: a.doctor?.fullImage,
            doctorName: _safe(a.doctor?.name),
            treatmentName: a.doctor?.treatment?.name,
            hospitalName: a.hospital?.name,
            hospitalAddress: a.hospital?.address,
            bookingId: _safe(a.appointmentId),
            statusLabel: displayStatus,
            statusColor: sColor,
            date: _safe(a.date),
            time: _safe(a.time),
            patientName: _safe(a.patientName),
            visitType: a.visitType,
            onTap: () {
              if (statusUpper == "COMPLETE" && a.doctor != null && a.doctor!.treatment != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyPrescription(
                      doctorImage: a.doctor!.fullImage,
                      doctorName: a.doctor!.name,
                      doctorTreatmentName: a.doctor!.treatment!.name,
                      doctorAddress: _safe(a.hospital?.address, fallback: ""),
                      appointmentDate: a.date,
                      appointmentTime: a.time,
                      patientName: a.patientName,
                      appointmentIdPrescription: a.prescription == true ? a.id : 0,
                      appointmentId: a.id,
                      userRating: a.rate,
                    ),
                  ),
                );
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointmentId: a.id!)));
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return ModalProgressHUD(
      inAsyncCall: loading || _cancelling,
      opacity: 0.5,
      progressIndicator: SpinKitFadingCircle(color: Palette.blue, size: 50.0),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Palette.dark_white,
          body: SafeArea(
            child: NestedScrollView(
              floatHeaderSlivers: true,
              physics: NeverScrollableScrollPhysics(),
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios, size: 20, color: Palette.dark_blue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    centerTitle: true,
                    backgroundColor: Palette.white,
                    foregroundColor: Palette.blue,
                    title: Text(
                      getTranslated(context, AppString.appointment_title).toString(),
                      style: TextStyle(fontSize: 18, color: Palette.dark_blue, fontWeight: FontWeight.bold),
                    ),
                    pinned: true,
                    floating: true,
                    snap: true,
                    shadowColor: Palette.blue,
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(54),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Palette.tabBar,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TabBar(
                          labelColor: Palette.white,
                          unselectedLabelColor: Palette.dark_blue,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerHeight: 0,
                          indicator: BoxDecoration(
                            color: Palette.blue,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          tabs: <Tab>[
                            Tab(child: Text(getTranslated(context, AppString.appointment_title_tab1).toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                            Tab(child: Text(getTranslated(context, AppString.appointment_title_tab2).toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                            Tab(child: Text(getTranslated(context, AppString.appointment_title_tab3).toString(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                          ],
                          controller: _tabController,
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: Column(children: [
                if (_loadFailed && _hasLoaded) MaterialBanner(content: const Text('Could not refresh appointments. Previously loaded information may be outdated.'), actions: [TextButton(onPressed: callApiAppointment, child: const Text('Retry'))]),
                Expanded(child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildPendingTab(width, height),
                  _buildUpcomingTab(width, height),
                  _buildPastTab(width, height),
                ],
              )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<BaseModel<Appointments>> callApiAppointment() async {
    if (!mounted || loading) return BaseModel<Appointments>();
    setState(() { loading = true; _loadFailed = false; });
    try {
      final response = await RestClient(RetroApi().dioData()).appointmentsRequest();
      if (!mounted) return BaseModel<Appointments>()..data = response;
      final data = response.data;
      if (response.success != true || data == null ||
          data.upcomingAppointment == null || data.pastAppointment == null ||
          data.pendingAppointment == null) {
        setState(() => _loadFailed = true);
      } else {
        setState(() {
          upcomingAppointment = List.of(data.upcomingAppointment!);
          pastAppointment = List.of(data.pastAppointment!);
          pendingAppointment = List.of(data.pendingAppointment!);
          _hasLoaded = true;
        });
      }
      return BaseModel<Appointments>()..data = response;
    } catch (error) {
      if (mounted) setState(() => _loadFailed = true);
      return BaseModel<Appointments>()..setException(ServerError.withError(error: error));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<BaseModel<CommonResponse>> callApiCancelAppointment() async {
    if (!mounted || _cancelling || id == null) return BaseModel<CommonResponse>();
    setState(() => _cancelling = true);
    final body = <String, dynamic>{"appointment_id": id, "cancel_reason": reason};
    try {
      final response = await RestClient(RetroApi().dioData()).cancelAppointmentRequest(body);
      if (!mounted) return BaseModel<CommonResponse>()..data = response;
      if (response.success == true) {
        _feedback('Appointment cancelled.');
        await callApiAppointment();
      } else {
        _feedback('Cancellation was not confirmed. Refresh your appointments before trying again.');
      }
      return BaseModel<CommonResponse>()..data = response;
    } catch (error) {
      _feedback('Cancellation could not be confirmed. Refresh your appointments before trying again.');
      return BaseModel<CommonResponse>()..setException(ServerError.withError(error: error));
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<BaseModel<DetailSetting>> callApiSetting() async {
    try {
      final response = await RestClient(RetroApi().dioData()).settingRequest();
      final raw = response.data?.cancelReason;
      if (mounted && response.success == true && raw != null) {
        final decoded = json.decode(raw);
        if (decoded is List) {
          setState(() {
            cancelReason = decoded.whereType<String>().toList();
          });
        }
      }
      return BaseModel<DetailSetting>()..data = response;
    } catch (error) {
      return BaseModel<DetailSetting>()..setException(ServerError.withError(error: error));
    }
  }
}
