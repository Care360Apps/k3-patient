import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctro_patient/Chat/chat.dart';
import 'package:doctro_patient/api/retrofit_Api.dart';
import 'package:doctro_patient/api/network_api.dart';
import 'package:doctro_patient/model/appointment_detail_model.dart';
import 'package:doctro_patient/model/appointments_model.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/base_model.dart';
import '../../api/server_error.dart';
import '../../const/Palette.dart';
import '../../const/app_string.dart';
import '../../const/prefConstatnt.dart';
import '../../const/preference.dart';
import '../../localization/localization_constant.dart';
import '../../model/common_response.dart';

/// Read-only appointment details: provider/doctor info, summary, tabs (Information / Illness / Prescription), patient details.
class AppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailScreen({Key? key, required this.appointmentId}) : super(key: key);

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  AppointmentDetailData? _data;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await RestClient(RetroApi().dioData()).appointmentDetailsRequest(widget.appointmentId);
      if (response.success == true && response.data != null) {
        setState(() {
          _data = response.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = response.msg ?? 'Failed to load';
          _loading = false;
        });
      }
    } catch (e, st) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openChat() {
    final doctorId = _data?.doctorId ?? _data?.doctor?.id;
    if (doctorId == null) return;
    final d = _data!.doctor;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chat(
          doctorId: doctorId,
          where: 'appointment_detail',
          peerIdFallback: d?.userId?.toString(),
          peerNicknameFallback: d?.name,
          peerAvatarFallback: d?.fullImage,
        ),
      ),
    );
  }

  Future<void> _openCall() async {
    final phone = _data?.phoneNo?.trim();
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildAppBarTitle() {
    final doctor = _data?.doctor;
    if (doctor == null) {
      return Text(
        getTranslated(context, AppString.appointment_detail_title) ?? 'Appointment Details',
        style: TextStyle(color: Palette.dark_blue, fontWeight: FontWeight.w600, fontSize: 18),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox(
            width: 36,
            height: 36,
            child: (doctor.fullImage != null && doctor.fullImage!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: doctor.fullImage!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                    errorWidget: (_, __, ___) => Icon(Icons.person_rounded, size: 22, color: Palette.grey),
                  )
                : Icon(Icons.person_rounded, size: 22, color: Palette.grey),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              doctor.name ?? '-',
              style: TextStyle(color: Palette.dark_blue, fontWeight: FontWeight.w700, fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              doctor.treatment?.name ?? 'Provider',
              style: TextStyle(color: Palette.grey, fontWeight: FontWeight.w500, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.dark_white,
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: Palette.white,
        foregroundColor: Palette.dark_blue,
        elevation: 0,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _loading,
        progressIndicator: const CircularProgressIndicator(color: Palette.blue),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Palette.dark_blue)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetail,
                style: ElevatedButton.styleFrom(backgroundColor: Palette.blue, foregroundColor: Palette.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_data == null) return const SizedBox();

    final doctor = _data!.doctor;
    final hasPhone = _data!.phoneNo != null && _data!.phoneNo!.trim().isNotEmpty;
    final canChat = (_data!.doctorId ?? _data!.doctor?.id) != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _headerCard(doctor, hasPhone, canChat),
          const SizedBox(height: 14),
          _summaryCard(),
          const SizedBox(height: 18),
          _tabsBar(),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: TabBarView(
              controller: _tabController,
              children: [
                _informationTab(),
                _illnessTab(),
                _prescriptionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    final upper = (status ?? '').toUpperCase();
    if (upper == 'PENDING') return Palette.dark_blue.withOpacity(0.7);
    if (upper == 'CANCEL' || upper == 'CANCELED') return Palette.red;
    if (upper == 'COMPLETE' || upper == 'COMPLETED') return Palette.green;
    return Palette.green;
  }

  String _statusLabel(String? status) {
    final upper = (status ?? '').toUpperCase();
    if (upper == 'APPROVE') return 'APPROVED';
    if (upper == 'CANCEL') return 'CANCELED';
    if (upper == 'COMPLETE') return 'COMPLETED';
    return upper;
  }

  Widget _headerCard(Doctor? doctor, bool hasPhone, bool canChat) {
    final statusUpper = (_data!.appointmentStatus ?? '').toUpperCase();
    final sColor = _statusColor(_data!.appointmentStatus);
    final sLabel = _statusLabel(_data!.appointmentStatus);
    final treatmentName = doctor?.treatment?.name;
    final visitType = _data!.visitType;

    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleButton(icon: Icons.phone_rounded, onTap: hasPhone ? _openCall : null),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sLabel.isEmpty ? '-' : sLabel,
                  style: TextStyle(fontSize: 12, color: sColor, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
              _circleButton(icon: Icons.chat_bubble_outline_rounded, onTap: canChat ? _openChat : null),
            ],
          ),
          const SizedBox(height: 18),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Palette.blue, Palette.blue.withOpacity(0.6)],
                  ),
                ),
              ),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.white,
                ),
              ),
              ClipOval(
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: doctor != null && (doctor.fullImage != null && doctor.fullImage!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: doctor.fullImage!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Palette.dark_white, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.blue)))),
                          errorWidget: (_, __, ___) => Container(color: Palette.dark_white, child: Icon(Icons.person_rounded, size: 44, color: Palette.grey)),
                        )
                      : Container(color: Palette.dark_white, child: Icon(Icons.person_rounded, size: 44, color: Palette.grey)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            doctor?.name ?? '-',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Palette.dark_blue),
            textAlign: TextAlign.center,
          ),
          if (treatmentName != null && treatmentName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              treatmentName,
              style: TextStyle(fontSize: 13, color: Palette.grey, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Palette.dark_white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Palette.dash_line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.confirmation_number_outlined, size: 14, color: Palette.blue),
                SizedBox(width: 6),
                Text(
                  'Booking ID: #${_data!.appointmentId ?? '-'}',
                  style: TextStyle(fontSize: 12, color: Palette.dark_blue, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (visitType != null && visitType.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  visitType == 'home_visit' ? Icons.home_rounded : Icons.videocam_rounded,
                  size: 16,
                  color: Palette.blue,
                ),
                SizedBox(width: 6),
                Text(
                  visitType == 'home_visit' ? 'Home Visit' : 'Video Call',
                  style: TextStyle(fontSize: 12, color: Palette.blue, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Palette.blue.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Palette.blue, size: 24),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final amount = '${SharedPreferenceHelper.getString(Preferences.currency_symbol) ?? ''}${_data!.amount ?? '0'}';
    final date = _formatDate(_data!.date);
    final time = _data!.time ?? '-';
    return _card(
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                icon: Icons.payments_outlined,
                label: 'Amount',
                value: amount,
              ),
            ),
            Container(width: 1, margin: EdgeInsets.symmetric(vertical: 4), color: Palette.dash_line),
            Expanded(
              child: _summaryItem(
                icon: Icons.calendar_today_rounded,
                label: 'Date',
                value: date,
              ),
            ),
            Container(width: 1, margin: EdgeInsets.symmetric(vertical: 4), color: Palette.dash_line),
            Expanded(
              child: _summaryItem(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: time,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Palette.blue),
          SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: Palette.grey, fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, color: Palette.dark_blue, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _tabsBar() {
    return Container(
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Palette.dark_blue.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Palette.blue,
          borderRadius: BorderRadius.circular(28),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Palette.white,
        unselectedLabelColor: Palette.dark_blue,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Palette.grey),
        tabs: const [
          Tab(text: 'Information'),
          Tab(text: 'Illness'),
          Tab(text: 'Prescription'),
        ],
      ),
    );
  }

  Widget _informationTab() {
    return _card(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow(Icons.person_outline_rounded, getTranslated(context, AppString.appointment_patientName) ?? 'Patient Name', _data!.patientName ?? '-'),
            _detailRow(Icons.cake_outlined, 'Age', _data!.age?.toString() ?? '-'),
            _detailRow(Icons.phone_outlined, 'Phone Number', _data!.phoneNo ?? '-'),
            if (_data!.patientAddress != null && _data!.patientAddress!.isNotEmpty)
              _detailRow(Icons.location_on_outlined, 'Address', _data!.patientAddress!),
            if (_data!.hospital?.name != null)
              _detailRow(Icons.local_hospital_outlined, 'Hospital', _data!.hospital!.name!),
            _detailRow(Icons.event_outlined, 'Date & Time', '${_data!.date ?? '-'}  ${_data!.time ?? '-'}'),
            _detailRow(Icons.medical_services_outlined, 'Visit type', _data!.visitType ?? '-'),
            _detailRow(Icons.payments_outlined, 'Amount', '${SharedPreferenceHelper.getString(Preferences.currency_symbol) ?? ''}${_data!.amount ?? '0'}'),
            _detailRow(Icons.info_outline_rounded, 'Status', _data!.appointmentStatus ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Palette.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Palette.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, color: Palette.dark_blue, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _illnessTab() {
    final text = _data!.illnessInformation?.trim();
    return _card(
      child: text != null && text.isNotEmpty
          ? SingleChildScrollView(
              child: Text(text, style: TextStyle(fontSize: 14, color: Palette.dark_blue, height: 1.5)),
            )
          : Center(
              child: Text('No illness information', style: TextStyle(fontSize: 14, color: Palette.grey)),
            ),
    );
  }

  Widget _prescriptionTab() {
    final hasPdf = _data!.pdf != null && _data!.pdf!.trim().isNotEmpty;
    final note = _data!.note?.trim();
    return _card(
      child: hasPdf || (note != null && note.isNotEmpty)
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note != null && note.isNotEmpty) ...[
                    Text('Note', style: TextStyle(fontSize: 12, color: Palette.grey, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(note, style: TextStyle(fontSize: 14, color: Palette.dark_blue)),
                    if (hasPdf) const SizedBox(height: 16),
                  ],
                  if (hasPdf)
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf_outlined, color: Palette.blue),
                      label: const Text('View prescription PDF'),
                    ),
                ],
              ),
            )
          : Center(
              child: Text('No prescription', style: TextStyle(fontSize: 14, color: Palette.grey)),
            ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Palette.dark_blue.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
