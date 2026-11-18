import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/brand/care360_discovery.dart';
import '../lib/const/preference.dart';
import '../lib/model/display_offer_model.dart';
import '../lib/model/health_tip_model.dart' as tips;
import '../lib/Screen/Screens/Offer.dart';
import '../lib/Screen/MedicineAndPharmacy/HealthTips.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SharedPreferenceHelper.init(offlineSandbox: true);
  });
  testWidgets('discovery remains available before campaigns exist', (tester) async {
    await tester.pumpWidget(MaterialApp(home: const Scaffold(body: Care360Discovery()),
      routes: {'HealthTips': (_) => const Text('Tips destination'),
        'Offer': (_) => const Text('Offers destination')}));
    await tester.tap(find.text('Health tips')); await tester.pumpAndSettle();
    expect(find.text('Tips destination'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Offers')); await tester.pumpAndSettle();
    expect(find.text('Offers destination'), findsOneWidget);
  });
  testWidgets('empty offers distinguish absence from connection failure', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Offer(loadOffers: () async =>
      DisplayOffer(success: true, data: []))));
    await tester.pumpAndSettle();
    expect(find.text('No offers available right now'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });
  testWidgets('offer connection failure can retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(home: Offer(loadOffers: () async {
      if (++attempts == 1) throw StateError('offline');
      return DisplayOffer(success: true, data: []);
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try again')); await tester.pumpAndSettle();
    expect(find.text('No offers available right now'), findsOneWidget);
    expect(attempts, 2);
  });
  testWidgets('offer terms fit large text and copy only the code', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320,640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
      (call) async { if (call.method == 'Clipboard.setData') copied = call.arguments['text']; return null; });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final offer=OfferModel.fromJson({'name':'Selected appointment promotion',
      'offer_code':'TESTONLY','discount':10.5,'discount_type':'percentage',
      'desc':'Selected clinicians only','start_end_date':'2026-11-01 - 2026-11-30',
      'min_discount':25});
    await tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: const MediaQueryData(size: Size(320,640),textScaler: TextScaler.linear(2)),
      child: Scaffold(body: SingleChildScrollView(child:
        Care360OfferCard(offer: offer,currency:'NGN '))))));
    expect(tester.takeException(), isNull);
    expect(find.text('10.5% discount'), findsOneWidget);
    await tester.ensureVisible(find.text('Copy offer code'));
    await tester.tap(find.text('Copy offer code')); await tester.pump();
    expect(copied, 'TESTONLY'); expect(tester.takeException(), isNull);
  });
  testWidgets('offline tips remain readable when articles fail', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HealthTips(loadTips: () async =>
      throw StateError('offline'))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build a varied plate')); await tester.pumpAndSettle();
    expect(find.text('Read the source'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('article refresh replaces existing content', (tester) async {
    var attempts=0;
    await tester.pumpWidget(MaterialApp(home: HealthTips(loadTips: () async =>
      tips.HealthTip(success:true,data:[tips.Data(id:++attempts,title:'Published tip')]))));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0,400));
    await tester.pumpAndSettle();
    expect(find.text('Published tip'), findsOneWidget); expect(attempts, 2);
  });
  testWidgets('leaving before load finishes is safe', (tester) async {
    final result=Completer<DisplayOffer>();
    await tester.pumpWidget(MaterialApp(home: Offer(loadOffers: () => result.future)));
    await tester.pumpWidget(const MaterialApp(home: Text('Left screen')));
    result.complete(DisplayOffer(success:true,data:[]));
    await tester.pumpAndSettle(); expect(tester.takeException(), isNull);
  });
}
