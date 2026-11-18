import 'dart:io';

import 'package:doctro_patient/preview/care360_nearby_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('synthetic Nearby Care view never accesses real clinicians or GPS', () {
    final source =
        File('lib/preview/care360_nearby_preview.dart').readAsStringSync();
    final dashboard = File('lib/preview/care360_offline_dashboard.dart')
        .readAsStringSync();
    expect(dashboard, contains("_Service('Nearby Care'"));
    expect(dashboard, contains('Care360NearbyPreview()'));
    expect(source, contains('SYNTHETIC DEMO'));
    expect(source, contains('Illustrative map'));
    expect(source, contains('not real streets or GPS'));
    expect(source, isNot(contains('RestClient(')));
    expect(source, isNot(contains('getCurrentPosition(')));
    expect(source, isNot(contains('FirebaseAuth')));
    expect(source, isNot(contains('GoogleMap(')));
  });

  testWidgets('synthetic map filters roles and simulates accepting requests',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Care360NearbyPreview()));
    expect(find.textContaining('SYNTHETIC DEMO'), findsOneWidget);
    expect(find.byKey(const Key('sample-nearby-filter-all')), findsOneWidget);
    final providers = find.byKey(
        const Key('sample-nearby-filter-care-provider'));
    await tester.ensureVisible(providers);
    await tester.pumpAndSettle();
    await tester.tap(providers);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sample-nearby-filter-care-provider')),
        findsOneWidget);
    expect(find.byKey(const Key('sample-pin-0')), findsNothing);
    expect(find.byKey(const Key('sample-pin-1')), findsOneWidget);

    final homeVisits = find.byKey(const Key('sample-service-home-visits'));
    await tester.ensureVisible(homeVisits);
    await tester.pumpAndSettle();
    await tester.tap(homeVisits);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sample-pin-0')), findsNothing);
    expect(find.byKey(const Key('sample-pin-1')), findsOneWidget);

    final accepting = find.byKey(const Key('sample-accepting-requests'));
    await tester.ensureVisible(accepting);
    await tester.pumpAndSettle();
    await tester.tap(accepting);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sample-pin-3')), findsNothing);
    expect(find.byKey(const Key('sample-pin-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
