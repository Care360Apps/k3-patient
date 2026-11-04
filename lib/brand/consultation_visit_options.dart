/// Client-side presentation of backend-approved visit types.
/// The Laravel API remains authoritative for role and permissions.
class ConsultationVisitOptions {
  static const video = 'video_call';
  static const home = 'home_visit';

  static List<String> allowed({
    required bool isProvider,
    required bool offersVideoCall,
    required bool offersHomeVisit,
  }) => [
    if (offersVideoCall) video,
    if (isProvider && offersHomeVisit) home,
  ];

  static String? selected({
    required List<String> allowed,
    String? preferred,
  }) {
    if (allowed.isEmpty) return null;
    return allowed.contains(preferred) ? preferred : allowed.first;
  }

  static bool flag(dynamic value) =>
      value == true || value == 1 || value?.toString() == '1';
}
