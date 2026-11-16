import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:motohub_app/i18n/i18n.dart';
import 'package:motohub_app/main.dart';
import 'package:motohub_app/screens/home_screen.dart';
import 'package:motohub_app/widgets/site_sections.dart';

/// Fake backend shaped like the live one: 8 listings per carousel, no accessories.
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
      // Like the live database: there are no accessories yet.
      final accessories = req.body.contains('ACCESSORY');
      final data = q.contains('getParts')
          ? {'getParts': {'list': accessories ? <Object>[] : List.generate(8, part)}}
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

    // ignore: avoid_print
    print('at start: spinners ${find.byType(CircularProgressIndicator, skipOffstage: false).evaluate().length}');
    {
      final rows = <String>[];
      for (final e in find.byType(SiteSection, skipOffstage: false).evaluate()) {
        rows.add('${(e.widget as SiteSection).title.substring(0, 12)}=${e.size!.height.round()}');
      }
      // ignore: avoid_print
      print('built at start: ${rows.join(', ')}');
    }
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
    // index@scrollOffset:height for every child the list has built
    String layout() {
      final sliver = tester.renderObject<RenderSliverList>(
          find.descendant(of: find.byType(HomeScreen), matching: find.byType(SliverList)).first);
      final parts = <String>[];
      for (var c = sliver.firstChild; c != null; c = sliver.childAfter(c)) {
        parts.add('${sliver.indexOf(c)}@${sliver.childScrollOffset(c)!.round()}:${c.size.height.round()}');
      }
      return 'pixels ${pos.pixels.round()} max ${pos.maxScrollExtent.round()} [${parts.join(' ')}]';
    }
    var lastLayout = '';
    for (var k = 0; k < 40 && pos.pixels > 0; k++) {
      final start = pos.pixels;
      await tester.dragFrom(const Offset(200, 200), const Offset(0, 400));
      var prev = pos.pixels;
      lastLayout = layout();
      for (var f = 0; f < 30; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (focusFooter && f == 20) {
          // Android keyboards resize a little (suggestion strip), which re-sends the insets.
          tester.view.viewInsets = FakeViewPadding(bottom: 800.0 + (k.isEven ? 1 : 0));
        }
        final now = pos.pixels;
        if (now > prev + 0.5) {
          back.add('drag $k frame $f: ${prev.round()} -> ${now.round()}');
          if (back.length <= 3) {
            // Which list children exist now, and how tall is each?
            final rows = <String>[];
            for (final e in find.byType(SiteSection).evaluate()) {
              final w = e.widget as SiteSection;
              rows.add('${w.title.substring(0, 12)}=${e.size!.height.round()}');
            }
            for (final e in find.byType(HomeHero).evaluate()) {
              rows.add('hero=${e.size!.height.round()}');
            }
            // ignore: avoid_print
            print('  pullback ${back.length}: ${prev.round()} -> ${now.round()} built: ${rows.join(', ')}');
            // ignore: avoid_print
            print('    before: $lastLayout');
            // ignore: avoid_print
            print('    after:  ${layout()}');
            // ignore: avoid_print
            print('    spinners ${find.byType(CircularProgressIndicator, skipOffstage: false).evaluate().length}, empty-texts ${find.textContaining("bo'sh", skipOffstage: false).evaluate().length}, carousels ${find.byType(SiteCarousel, skipOffstage: false).evaluate().length}, sections ${find.byType(SiteSection, skipOffstage: false).evaluate().map((e) => "${(e.widget as SiteSection).title.substring(0, 8)}=${e.size!.height.round()}").join(" ")}');
          }
        }
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
    // Every drag but the last (which stops at the top) follows the finger:
    // 380-400px for a 400px drag, no jump from sections rebuilt above.
    expect(trail.take(trail.length - 1).where((m) => m < 370 || m > 410), isEmpty,
        reason: 'each 400px drag should move the page ~380-400px up, got $trail');
  });
  }
}
