import 'package:doctro_patient/model/providers_model.dart';

/// Filters only the returned discovery page; server still decides who is
/// approved, active and permitted to offer each service.
class ProviderDiscoveryFilter {
  static const all = 'all';
  static const video = 'video_call';
  static const home = 'home_visit';

  static List<ProviderModel> apply(
    List<ProviderModel> items, {
    String query = '',
    String service = all,
  }) {
    final needle = query.trim().toLowerCase();
    return items.where((provider) {
      final name = (provider.name ?? '').toLowerCase();
      final speciality = (provider.providerType?.name ?? '').toLowerCase();
      if (needle.isNotEmpty &&
          !name.contains(needle) && !speciality.contains(needle)) {
        return false;
      }
      if (service == video) return provider.offersVideoCall;
      if (service == home) return provider.offersHomeVisit;
      return true;
    }).toList();
  }
}
