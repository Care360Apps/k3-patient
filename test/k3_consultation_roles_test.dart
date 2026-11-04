import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/consultation_visit_options.dart';
import 'package:doctro_patient/model/provider_detail_model.dart';

void main() {
  test('doctors cannot offer home visits regardless of outdated server flags', () {
    expect(ConsultationVisitOptions.allowed(
      isProvider: false,
      offersVideoCall: true,
      offersHomeVisit: true,
    ), ['video_call']);
  });

  test('providers can choose either offered consultation type', () {
    final both = ConsultationVisitOptions.allowed(
      isProvider: true, offersVideoCall: true, offersHomeVisit: true);
    expect(both, ['video_call', 'home_visit']);
    expect(ConsultationVisitOptions.selected(
      allowed: both, preferred: ConsultationVisitOptions.home),
      ConsultationVisitOptions.home);
    expect(ConsultationVisitOptions.selected(
      allowed: both, preferred: ConsultationVisitOptions.video),
      ConsultationVisitOptions.video);
  });

  test('unconfigured providers cannot book video or unsupported visit types', () {
    final homeOnly = ConsultationVisitOptions.allowed(
      isProvider: true, offersVideoCall: false, offersHomeVisit: true);
    expect(homeOnly, ['home_visit']);
    expect(ConsultationVisitOptions.selected(allowed: homeOnly,
      preferred: ConsultationVisitOptions.video), 'home_visit');
    expect(ConsultationVisitOptions.selected(allowed: []), isNull);
  });

  test('provider API service flags map from bool, integer and string values', () {
    final configured = ProviderDetailData.fromJson({
      'id': 4, 'name': 'Test provider',
      'offers_video_call': '1', 'offers_home_visit': 1,
    });
    expect(configured.offersVideoCall, isTrue);
    expect(configured.offersHomeVisit, isTrue);
    final disabled = ProviderDetailData.fromJson({
      'id': 5, 'offers_video_call': 0, 'offers_home_visit': null,
    });
    expect(disabled.offersVideoCall, isFalse);
    expect(disabled.offersHomeVisit, isFalse);
  });
}
