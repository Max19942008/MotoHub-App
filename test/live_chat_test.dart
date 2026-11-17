import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motohub_app/api/chat_service.dart';
import 'package:motohub_app/widgets/live_chat.dart';

/// A local stand-in for moto-hub's socket.gateway.ts: same events, same
/// shapes. On connect it broadcasts `info` and sends the last messages;
/// a `{event: 'message', data}` frame is broadcast back to everyone.
class FakeGateway {
  late HttpServer _server;
  final clients = <WebSocket>[];
  final received = <Map<String, dynamic>>[];
  final history = <Map<String, dynamic>>[
    {
      'event': 'message',
      'text': 'salom hammaga',
      'memberData': {'_id': 'u1', 'memberNick': 'bobur', 'memberType': 'USER'},
      'createdAt': '2026-11-17T01:00:00.000Z',
    },
  ];
  final connected = StreamController<String?>.broadcast(); // query token

  String get url => 'ws://127.0.0.1:${_server.port}';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      final token = req.uri.queryParameters['token'];
      final ws = await WebSocketTransformer.upgrade(req);
      clients.add(ws);
      connected.add(token);
      _broadcast({
        'event': 'info',
        'totalClients': clients.length,
        'memberData': null,
        'action': 'joined',
      });
      ws.add(jsonEncode({'event': 'getMessages', 'list': history}));
      ws.listen((raw) {
        final frame = jsonDecode(raw as String) as Map<String, dynamic>;
        received.add(frame);
        final msg = {
          'event': 'message',
          'text': frame['data'],
          'memberData': null,
          'createdAt': DateTime.now().toIso8601String(),
        };
        history.add(msg);
        _broadcast(msg);
      }, onDone: () => clients.remove(ws));
    });
  }

  void _broadcast(Map<String, dynamic> m) {
    for (final c in clients) {
      c.add(jsonEncode(m));
    }
  }

  /// Drops every connection, like a server restart.
  Future<void> kick() async {
    for (final c in [...clients]) {
      await c.close();
    }
    clients.clear();
  }

  Future<void> stop() async {
    await kick();
    await _server.close(force: true);
  }
}

Future<void> until(bool Function() ok, {String? what}) async {
  for (var i = 0; i < 200; i++) {
    if (ok()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('timed out waiting for ${what ?? 'condition'}');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeGateway gw;
  final chat = ChatService.instance;

  setUp(() async {
    gw = FakeGateway();
    await gw.start();
    ChatService.debugUrl = gw.url;
  });

  tearDown(() async {
    chat.debugReset();
    await gw.stop();
  });

  test('speaks the site protocol: history, online count, send, echo', () async {
    chat.start();
    final token = await gw.connected.stream.first;
    expect(token, isNull, reason: 'a guest connects without ?token');
    await until(() => chat.connected && chat.messages.isNotEmpty,
        what: 'history');
    expect(chat.onlineUsers, 1);
    expect(chat.messages.single.text, 'salom hammaga');
    expect(chat.messages.single.member?.nick, 'bobur');

    expect(chat.send('  assalomu alaykum  '), isTrue);
    await until(() => chat.messages.length == 2, what: 'echo');
    // Exactly what the website sends.
    expect(gw.received.single, {'event': 'message', 'data': 'assalomu alaykum'});
    expect(chat.messages.last.text, 'assalomu alaykum');
    expect(chat.messages.last.member, isNull, reason: 'guest');

    // Over-long text is cut to the server's 500-char limit, like the site.
    chat.send('x' * 600);
    await until(() => gw.received.length == 2, what: 'long message');
    expect((gw.received.last['data'] as String).length, 500);
  });

  test('reconnects after the server drops the line', () async {
    chat.start();
    await until(() => chat.connected, what: 'first connect');
    await gw.kick();
    await until(() => !chat.connected, what: 'drop noticed');
    expect(chat.send('lost'), isFalse,
        reason: 'no silent loss while reconnecting');
    // First retry comes after 1s.
    await until(() => chat.connected && gw.clients.length == 1,
        what: 'reconnect');
    expect(chat.send('back'), isTrue);
    await until(() => gw.received.isNotEmpty, what: 'message after reconnect');
    expect(gw.received.single['data'], 'back');
  });

  testWidgets('chat button opens the Online Chat panel and sends', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: SizedBox.expand(child: LiveChat()))));
      await until(() => chat.connected && chat.messages.isNotEmpty);
    });
    await tester.pump();

    // Closed: only the round button; the panel is off to the right.
    final button = find.byIcon(Icons.mark_chat_unread);
    expect(button, findsOneWidget);
    expect(tester.getTopLeft(find.text('Online Chat')).dx,
        greaterThan(tester.view.physicalSize.width / tester.view.devicePixelRatio));

    await tester.tap(button);
    // 0.7s slide (pumpAndSettle would wait forever on the badge ripple).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byIcon(Icons.close_fullscreen), findsOneWidget);
    expect(tester.getTopLeft(find.text('Online Chat')).dx, lessThan(400));
    expect(find.text('Welcome to Live chat!'), findsOneWidget);
    expect(find.text('salom hammaga'), findsOneWidget);
    expect(find.text('bobur'), findsOneWidget);
    expect(find.text('1'), findsOneWidget, reason: 'online counter');

    // Empty input: the site's "Message is empty!" alert, nothing sent.
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    expect(find.text('Message is empty!'), findsOneWidget);
    expect(gw.received, isEmpty);

    await tester.enterText(find.byType(TextField), 'ilovadan salom');
    await tester.tap(find.byIcon(Icons.send));
    // The tap ran in the test's fake clock; let both clocks move until the
    // write reaches the server and its echo comes back.
    for (var i = 0; i < 100 && chat.messages.length < 2; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
    }
    await tester.pump();
    expect(gw.received.single['data'], 'ilovadan salom');
    expect(find.text('ilovadan salom'), findsOneWidget);
    expect(find.text('Guest'), findsOneWidget, reason: 'echo from a guest');
    expect((tester.widget(find.byType(TextField)) as TextField).controller!.text,
        isEmpty);

    // Close again; the badge ripple keeps ticking, so unmount explicitly.
    await tester.tap(find.byIcon(Icons.close_fullscreen));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
  });
}
