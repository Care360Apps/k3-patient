import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctro_patient/brand/care360_horizontal_cards.dart';

void main() {
  testWidgets('horizontal cards render inside a vertically scrolling dashboard',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Specialists'),
              SizedBox(
                height: 200,
                child: Care360HorizontalCards(
                  itemCount: 3,
                  itemBuilder: (context, index) =>
                      SizedBox(width: 150, child: Text('Specialist $index')),
                ),
              ),
              const Text('Providers'),
              SizedBox(
                height: 180,
                child: Care360HorizontalCards(
                  itemCount: 2,
                  itemBuilder: (context, index) =>
                      SizedBox(width: 150, child: Text('Provider $index')),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Specialist 0'), findsOneWidget);
    expect(find.text('Provider 0'), findsOneWidget);
  });

  testWidgets('empty list remains valid with constrained viewport',
      (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SizedBox(height: 180, child: Care360HorizontalCards(
        itemCount: 0, itemBuilder: (_, __) => const Text('Not expected'),
      )),
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Not expected'), findsNothing);
  });
}
