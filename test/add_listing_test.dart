import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motohub_app/screens/add_listing_screen.dart';

/// The listing form lays out on a phone and checks required fields before
/// anything is sent to the server.
void main() {
  Future<void> pump(WidgetTester tester, {required bool isPart}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester
        .pumpWidget(MaterialApp(home: AddListingScreen(isPart: isPart)));
    await tester.pump();
  }

  testWidgets('bike form shows bike fields and blocks an empty save',
      (tester) async {
    await pump(tester, isPart: false);
    expect(find.text("Yangi mototsikl qo'shish"), findsOneWidget);
    expect(find.text('Ijara'), findsOneWidget);
    expect(find.text('Yurgan masofa'), findsOneWidget);

    final save = find.widgetWithText(FilledButton, 'Saqlash');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump(const Duration(milliseconds: 500)); // snackbar slides in
    expect(find.text("Sarlavha 3–100 belgidan iborat bo'lishi kerak"),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('part form shows part fields', (tester) async {
    await pump(tester, isPart: true);
    expect(find.text("Qism qo'shish"), findsOneWidget);
    expect(find.text('Turkum'), findsOneWidget);
    expect(find.text('Omborda (dona)'), findsOneWidget);
    expect(find.text('Yurgan masofa'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
