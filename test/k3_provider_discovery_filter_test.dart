import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/provider_discovery_filter.dart';
import 'package:doctro_patient/model/providers_model.dart';

void main() {
  final items = [
    ProviderModel(
      id: 1, name: 'Amaka Ada',
      providerType: ProviderTypeLite(name: 'Physiotherapist'),
      offersVideoCall: true, offersHomeVisit: false,
    ),
    ProviderModel(
      id: 2, name: 'Bola Bello',
      providerType: ProviderTypeLite(name: 'Nursing care'),
      offersVideoCall: false, offersHomeVisit: true,
    ),
    ProviderModel(
      id: 3, name: 'Chioma Chika',
      providerType: ProviderTypeLite(name: 'Nutrition counsellor'),
      offersVideoCall: true, offersHomeVisit: true,
    ),
  ];
  test('search matches provider name or professional specialty', () {
    expect(ProviderDiscoveryFilter.apply(items, query: 'amaka').map((x) => x.id), [1]);
    expect(ProviderDiscoveryFilter.apply(items, query: 'nursing').map((x) => x.id), [2]);
  });
  test('video and home-visit chips show only offered services', () {
    expect(ProviderDiscoveryFilter.apply(items, service: ProviderDiscoveryFilter.video)
      .map((x) => x.id), [1, 3]);
    expect(ProviderDiscoveryFilter.apply(items, service: ProviderDiscoveryFilter.home)
      .map((x) => x.id), [2, 3]);
  });
  test('combined query and mode filters apply with no fabricated listings', () {
    expect(ProviderDiscoveryFilter.apply(items,
      query: 'nutrition', service: ProviderDiscoveryFilter.home).map((x) => x.id), [3]);
    expect(ProviderDiscoveryFilter.apply(items,
      query: 'Amaka', service: ProviderDiscoveryFilter.home), isEmpty);
  });
}
