import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../config.dart';
import 'auth_service.dart';

/// The sender as the server shares it (moto-hub socket.gateway.ts ChatMember).
class ChatMember {
  const ChatMember({required this.id, required this.nick, this.image});
  final String id;
  final String nick;
  final String? image;

  static ChatMember? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['_id'];
    final nick = json['memberNick'];
    if (id is! String || nick is! String) return null;
    final image = json['memberImage'];
    return ChatMember(id: id, nick: nick, image: image is String ? image : null);
  }
}

class ChatMessage {
  const ChatMessage({required this.text, this.member, this.createdAt});
  final String text;
  final ChatMember? member;
  final String? createdAt;

  static ChatMessage? fromJson(Object? json) {
    if (json is! Map || json['text'] is! String) return null;
    return ChatMessage(
      text: json['text'] as String,
      member: ChatMember.fromJson(json['memberData']),
      createdAt: json['createdAt'] is String ? json['createdAt'] as String : null,
    );
  }
}

/// The website's live chat socket (ignition libs/chatSocket.ts), one per app.
///
/// Same server and protocol as the site, so app and site users share one room:
/// the token goes in the query string, the server answers with `info`
/// (online count), `getMessages` (last 20) and `message` events, and we send
/// `{event: 'message', data: text}`. Reconnects with backoff when the line
/// drops, reconnects with the new token when the user logs in or out, and
/// closes while the app is in the background.
class ChatService extends ChangeNotifier {
  ChatService._();
  static final ChatService instance = ChatService._();

  static const maxTextLength = 500;

  /// ws(s):// form of the API address, like the site's REACT_APP_API_WS.
  static String get wsUrl =>
      debugUrl ?? apiUrl.replaceFirst(RegExp('^http'), 'ws');

  /// Points the socket at a local fake server in tests.
  @visibleForTesting
  static String? debugUrl;

  final List<ChatMessage> messages = [];
  int onlineUsers = 0;
  bool connected = false;

  WebSocket? _socket;
  int _generation = 0; // bumps on every (re)open; stale sockets are ignored
  String? _memberId; // whose token the socket was opened with
  int _retries = 0;
  Timer? _retryTimer;
  Timer? _connectTimer;
  bool _started = false;
  bool _paused = false;
  AppLifecycleListener? _lifecycle;

  /// Opens the socket once; safe to call again.
  void start() {
    if (_started) return;
    _started = true;
    _memberId = AuthService.instance.member?.id;
    AuthService.instance.addListener(_onAuthChanged);
    _lifecycle = AppLifecycleListener(
      onPause: () {
        _paused = true;
        _close();
      },
      onResume: () {
        _paused = false;
        _open();
      },
    );
    _open();
  }

  void _onAuthChanged() {
    final id = AuthService.instance.member?.id;
    if (id == _memberId) return;
    _memberId = id;
    if (!_paused) _open(); // the server reads who we are only at connect time
  }

  Future<void> _open() async {
    _retryTimer?.cancel();
    _connectTimer?.cancel();
    final generation = ++_generation;
    _socket?.close();
    _socket = null;
    _setConnected(false);

    String? token;
    try {
      token = await AuthService.instance.validAccessToken();
    } catch (_) {
      token = null; // chat as a guest rather than not at all
    }
    if (generation != _generation) return;

    final url = token == null || token.isEmpty
        ? wsUrl
        : '$wsUrl?token=${Uri.encodeQueryComponent(token)}';
    // Give up on a connect that hangs (own timer, so _close can cancel it).
    _connectTimer?.cancel();
    _connectTimer = Timer(const Duration(seconds: 15), () {
      if (generation != _generation) return;
      _generation++; // the late socket, if any, is dropped on arrival
      _onLost(_generation);
    });
    try {
      final ws = await WebSocket.connect(url);
      if (generation == _generation) _connectTimer?.cancel();
      if (generation != _generation) {
        ws.close();
        return;
      }
      _socket = ws;
      ws.pingInterval = const Duration(seconds: 30);
      _retries = 0;
      _setConnected(true);
      ws.listen(
        _onData,
        onDone: () => _onLost(generation),
        onError: (Object _) => _onLost(generation),
        cancelOnError: true,
      );
    } catch (_) {
      if (generation == _generation) _connectTimer?.cancel();
      _onLost(generation);
    }
  }

  void _onLost(int generation) {
    if (generation != _generation) return; // replaced on purpose
    _socket = null;
    _setConnected(false);
    if (_paused) return;
    final delay = Duration(milliseconds: min(30000, 1000 * (1 << min(_retries++, 5))));
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, _open);
  }

  void _close() {
    _retryTimer?.cancel();
    _connectTimer?.cancel();
    _generation++;
    _socket?.close();
    _socket = null;
    _setConnected(false);
  }

  void _onData(dynamic raw) {
    Object? data;
    try {
      data = jsonDecode(raw as String);
    } catch (_) {
      return;
    }
    if (data is! Map) return;
    switch (data['event']) {
      case 'info':
        final n = data['totalClients'];
        onlineUsers = n is int ? n : 0;
      case 'getMessages':
        final list = data['list'];
        messages
          ..clear()
          ..addAll(list is List
              ? list.map(ChatMessage.fromJson).whereType<ChatMessage>()
              : const <ChatMessage>[]);
      case 'message':
        final m = ChatMessage.fromJson(data);
        if (m == null) return;
        messages.add(m);
      default:
        return;
    }
    notifyListeners();
  }

  void _setConnected(bool value) {
    if (connected == value) return;
    connected = value;
    notifyListeners();
  }

  /// Sends [text]; false when the socket is not open (the UI says so).
  bool send(String text) {
    final ws = _socket;
    if (ws == null || ws.readyState != WebSocket.open) return false;
    final trimmed = text.trim();
    ws.add(jsonEncode({
      'event': 'message',
      'data': trimmed.length > maxTextLength
          ? trimmed.substring(0, maxTextLength)
          : trimmed,
    }));
    return true;
  }

  @visibleForTesting
  void debugReset() {
    _close();
    AuthService.instance.removeListener(_onAuthChanged);
    _lifecycle?.dispose();
    _lifecycle = null;
    _started = false;
    _paused = false;
    messages.clear();
    onlineUsers = 0;
  }
}
