import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/auth_service.dart';
import '../api/chat_service.dart';
import '../config.dart';
import '../screens/my_page_screen.dart' show DefaultAvatar;

/// The website's live chat (ignition libs/components/Chat.tsx + scss/chat.scss,
/// phone sizes from scss/mobile/layout.scss): a round white button bottom
/// right, on the same line as the AI Assistant pill, and a light blue
/// "Online Chat" panel that slides in from the right above it.
///
/// Fills its parent; put it on top of the page in a Stack.
class LiveChat extends StatefulWidget {
  const LiveChat({super.key});

  @override
  State<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends State<LiveChat> {
  final _chat = ChatService.instance;
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  bool _open = false;
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _chat.start();
    _chat.addListener(_onChat);
    _shown = _chat.messages.length;
  }

  @override
  void dispose() {
    _chat.removeListener(_onChat);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Like react-scrollable-feed: follow new messages while the reader is at
  /// the bottom, leave them alone while they read older ones.
  void _onChat() {
    final grew = _chat.messages.length != _shown;
    _shown = _chat.messages.length;
    final atBottom = !_scroll.hasClients ||
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 40;
    setState(() {});
    if (grew && atBottom) _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _focus.requestFocus(); // the site focuses the input on open
      _toBottom();
    } else {
      _focus.unfocus();
    }
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) {
      _alert('Message is empty!');
      return;
    }
    if (!_chat.send(text)) {
      _alert('Chat is reconnecting, please try again in a moment.');
      return;
    }
    _input.clear();
    _toBottom();
  }

  void _alert(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return LayoutBuilder(builder: (context, box) {
      // Site: bottom 76px, height min(500px, 100dvh - 150px), 8px from the
      // edges. Here the page area already starts below the navbar.
      final bottom = 76 + bottomPad;
      final height = math.max(0.0, math.min(500.0, box.maxHeight - bottom - 14));
      return Stack(
        children: [
          Positioned(
            left: 8,
            right: 8,
            bottom: bottom,
            height: height,
            child: IgnorePointer(
              ignoring: !_open,
              child: AnimatedSlide(
                // right: calc(-100vw - 16px) -> 8px, 0.7s ease-in-out
                offset: _open ? Offset.zero : const Offset(1.1, 0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOut,
                child: _frame(),
              ),
            ),
          ),
          // On the site the fixed button stays behind the phone keyboard.
          // Here the page shrinks above the keyboard instead, so hide the
          // closed button while another field is being typed in rather than
          // let it float over that form. (The Scaffold strips the keyboard
          // inset from the page, so read it from the window; the page's
          // size change rebuilds this LayoutBuilder when it opens/closes.)
          if (_open || View.of(context).viewInsets.bottom == 0)
            Positioned(
              right: 16,
              bottom: 16 + bottomPad,
              child: _ChatButton(open: _open, onTap: _toggle),
            ),
        ],
      );
    });
  }

  static const _divider = Color(0xD4CDCDCD); // rgba(205,205,205,.83)

  Widget _frame() {
    final me = AuthService.instance.member?.id;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9F3FF),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(color: Color(0x4D323232), blurRadius: 15),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // .chat-top: 103px, title + online counter
            Container(
              height: 103,
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _divider))),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _chat.connected ? 'Online Chat' : 'Connecting…',
                    // The site asks for Nunito, which it never loads, so
                    // phones draw it in their serif font.
                    style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 30,
                        height: 1.8,
                        color: Colors.black),
                  ),
                  Transform.translate(
                    offset: const Offset(8, -18),
                    child: _OnlineBadge(count: _chat.onlineUsers),
                  ),
                ],
              ),
            ),
            // .chat-content: 17px padding, messages
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(17),
                itemCount: _chat.messages.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text('Welcome to Live chat!',
                          style: TextStyle(fontSize: 16, color: Colors.black)),
                    );
                  }
                  final m = _chat.messages[i - 1];
                  final mine = me != null && m.member?.id == me;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: mine ? _MyMessage(m.text) : _TheirMessage(m),
                  );
                },
              ),
            ),
            // .chat-bott: 103px, input + send
            Container(
              height: 103,
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _divider))),
              padding: const EdgeInsets.symmetric(horizontal: 17),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      focusNode: _focus,
                      maxLength: ChatService.maxTextLength,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        _send();
                        _focus.requestFocus(); // keep typing, like the site
                      },
                      onTapOutside: (_) => _focus.unfocus(),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Type message',
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: const Color(0xFFF7F7F7),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                                color: Color(0xFF257677), width: 2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Semantics(
                    button: true,
                    label: 'Send message',
                    child: Material(
                      color: const Color(0xFF33C1C1),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _send,
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// .chat-button: 48px white circle, soft shadow; chat icon / collapse icon.
class _ChatButton extends StatelessWidget {
  const _ChatButton({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: open ? 'Close chat' : 'Open chat',
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x33323232), blurRadius: 10)],
        ),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Icon(
              open ? Icons.close_fullscreen : Icons.mark_chat_unread,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// MUI Badge as the site's RippleBadge: light blue pill with the online
/// count and a teal ring that keeps pulsing outwards.
class _OnlineBadge extends StatefulWidget {
  const _OnlineBadge({required this.count});
  final int count;

  @override
  State<_OnlineBadge> createState() => _OnlineBadgeState();
}

class _OnlineBadgeState extends State<_OnlineBadge>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MUI hides a badge whose content is 0.
    if (widget.count <= 0) return const SizedBox(width: 20, height: 20);
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_pulse.value);
              return Transform.scale(
                scale: 0.8 + 1.6 * t, // scale(.8) -> scale(2.4)
                child: Opacity(
                  opacity: 1 - t,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF32C2C1), width: 2),
                    ),
                  ),
                ),
              );
            },
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0x8FB4DCFF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text('${widget.count}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xD62C40BD))),
          ),
        ],
      ),
    );
  }
}

/// .msg-right: my messages, mint bubble on the right.
class _MyMessage extends StatelessWidget {
  const _MyMessage(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: const BoxDecoration(
          color: Color(0xFFD0ECE8),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 16, color: Colors.black)),
      ),
    );
  }
}

/// Avatar, nick (Guest when logged out) and a grey .msg-left bubble.
class _TheirMessage extends StatelessWidget {
  const _TheirMessage(this.message);
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl(message.member?.image);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: url.isEmpty
                ? const DefaultAvatar()
                : Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const DefaultAvatar()),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(message.member?.nick ?? 'Guest',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  color: Color(0xFF9FA7AC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(message.text,
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
