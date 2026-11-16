import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:motohub_app/i18n/i18n.dart';
import 'package:motohub_app/main.dart';
import 'package:motohub_app/screens/home_screen.dart';

/// Fake backend: every home carousel gets 8 listings.
http.Client _fakeApi() => MockClient((req) async {
      final q = (jsonDecode(req.body) as Map)['query'] as String;
      Map<String, dynamic> bike(int i) => {
            '_id': 'b$i', 'propertyTitle': 'Bike $i', 'propertyBrand': 'HONDA', 'propertyYear': 2020,
            'propertyPrice': 5000, 'propertyImages': <String>[], 'propertyLocation': 'TASHKENT',
          };
      Map<String, dynamic> part(int i) => {
            '_id': 'p$i', 'partTitle': 'Part $i', 'partBrand': 'YAMAHA', 'partPrice': 50, 'partImages': <String>[],
          };
      Map<String, dynamic> agent(int i) => {'_id': 'a$i', 'memberNick': 'agent$i', 'memberType': 'AGENT'};
      if (!q.contains('getParts') && !q.contains('getAgents') && !q.contains('getProperties')) {
        return http.Response(jsonEncode({'errors': [{'message': 'not faked'}]}), 200);
      }
      final data = q.contains('getParts')
          ? {'getParts': {'list': List.generate(8, part)}}
          : q.contains('getAgents')
              ? {'getAgents': {'list': List.generate(10, agent)}}
              : {'getProperties': {'list': List.generate(8, bike)}};
      return http.Response(jsonEncode({'data': data}), 200, headers: {'content-type': 'application/json'});
    });

void main() {
  for (final (shell, focusFooter) in [(false, false), (true, false), (true, true)]) {
  testWidgets('${shell ? 'full app shell' : 'bare HomeScreen'}${focusFooter ? ', footer email field focused' : ''}: scrolling up from the footer never pulls the page back down', (tester) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      final s = d.toString();
      // Test fonts are wider than Poppins (row overflow) and there is no network for images/video.
      if (!s.contains('overflowed') && !s.contains('HTTP request failed') && !s.contains('MissingPluginException')) {
        original?.call(d);
      }
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await http.runWithClient(() async {
      await tester.pumpWidget(shell ? I18nScope(child: const MotoprestoApp()) : const MaterialApp(home: Scaffold(body: HomeScreen())));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }, _fakeApi);

    final scrollable = tester.state<ScrollableState>(find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)).first);
    final pos = scrollable.position;
    // Drag down to the footer like a thumb.
    for (var i = 0; i < 80 && pos.pixels < pos.maxScrollExtent - 1; i++) {
      await tester.dragFrom(const Offset(200, 700), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('at bottom: ${pos.pixels.round()} / ${pos.maxScrollExtent.round()}');

    if (focusFooter) {
      // The thumb lands on the footer's email box: keyboard opens, the field keeps focus.
      final field = find.descendant(of: find.byType(HomeScreen), matching: find.byType(TextField)).last;
      // ignore: avoid_print
      print('field at ${tester.getRect(field)}');
      await tester.showKeyboard(field);
      // ignore: avoid_print
      print('focus: ${FocusManager.instance.primaryFocus}');
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 800); // keyboard up
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print('focused footer field, pixels ${pos.pixels.round()}');
    }
    final back = <String>[];
    final trail = <int>[];
    for (var k = 0; k < 40 && pos.pixels > 0; k++) {
      final start = pos.pixels;
      await tester.dragFrom(const Offset(200, 200), const Offset(0, 400));
      var prev = pos.pixels;
      for (var f = 0; f < 30; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (focusFooter && f == 20) {
          // Android keyboards resize a little (suggestion strip), which re-sends the insets.
          tester.view.viewInsets = FakeViewPadding(bottom: 800.0 + (k.isEven ? 1 : 0));
        }
        final now = pos.pixels;
        if (now > prev + 0.5) back.add('drag $k frame $f: ${prev.round()} -> ${now.round()}');
        prev = now;
      }
      await tester.pumpAndSettle();
      trail.add((start - pos.pixels).round());
    }
    // ignore: avoid_print
    print('moved up per 400px drag: $trail');
    // ignore: avoid_print
    print('frames pulled back down (${back.length}): ${back.take(20).join(' | ')}');
    expect(back, isEmpty);
    expect(trail.take(trail.length - 1).where((m) => m < 300), isEmpty, reason: 'each 400px drag should move the page ~380px up');
  });
  }
}
