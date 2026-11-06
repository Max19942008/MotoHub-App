import 'package:flutter/material.dart';

import '../api/assistant.dart';
import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../utils/labels.dart';
import '../widgets/common.dart';
import 'motorbike_detail_screen.dart';
import 'part_detail_screen.dart';

const _suggestions = [
  'Toshkentda 10 000\$ gacha mototsikl bormi?',
  'Yamaha uchun zanjir kerak',
  'Yangi boshlovchiga qaysi mototsikl mos?',
];

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> with AutomaticKeepAliveClientMixin {
  final _turns = <ChatTurn>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _sending) return;
    final history = List<ChatTurn>.of(_turns);
    _input.clear();
    setState(() {
      _turns.add(ChatTurn.user(message));
      _sending = true;
    });
    _scrollToEnd();

    ChatTurn reply;
    try {
      reply = await AssistantApi.instance.ask(message, history);
    } on ApiException catch (e) {
      reply = ChatTurn.error(e.message);
    } catch (_) {
      reply = ChatTurn.error('Xatolik yuz berdi, qayta urinib ko\'ring.');
    }
    if (!mounted) return;
    setState(() {
      _turns.add(reply);
      _sending = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _openSource(AiSource s) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (s.type == 'PROPERTY') {
        final bike = await Repository.instance.motorbike(s.id);
        navigator.push(MaterialPageRoute(builder: (_) => MotorbikeDetailScreen(initial: bike)));
      } else if (s.type == 'PART') {
        final part = await Repository.instance.part(s.id);
        navigator.push(MaterialPageRoute(builder: (_) => PartDetailScreen(initial: part)));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text('Maqolalarni saytda o\'qishingiz mumkin.')));
      }
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: _turns.isEmpty
              ? _EmptyState(onPick: _send)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  itemCount: _turns.length + (_sending ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _turns.length) return const _TypingBubble();
                    return _TurnView(turn: _turns[i], onSource: _openSource);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'Mototsikl yoki qism haqida so\'rang…',
                      counterText: '',
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  onPressed: _sending ? null : () => _send(_input.text),
                  icon: const Icon(Icons.send),
                  tooltip: 'Yuborish',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.smart_toy_outlined, size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('MotoHub AI yordamchi', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'O\'zbek, rus yoki ingliz tilida yozing — men MotoHub e\'lonlaridan mos mototsikl va qismlarni topib beraman.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onPressed: () => onPick(s),
              child: Text(s),
            ),
          ),
      ],
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({required this.turn, required this.onSource});
  final ChatTurn turn;
  final ValueChanged<AiSource> onSource;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = turn.isUser
        ? scheme.primary
        : turn.isError
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest;
    final fg = turn.isUser
        ? scheme.onPrimary
        : turn.isError
            ? scheme.onErrorContainer
            : scheme.onSurface;

    return Align(
      alignment: turn.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: turn.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(turn.isUser ? 16 : 4),
                    bottomRight: Radius.circular(turn.isUser ? 4 : 16),
                  ),
                ),
                child: SelectableText(turn.text, style: TextStyle(color: fg, height: 1.4)),
              ),
              for (var n = 0; n < turn.sources.length; n++)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _SourceCard(index: n + 1, source: turn.sources[n], onTap: () => onSource(turn.sources[n])),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.index, required this.source, required this.onTap});
  final int index;
  final AiSource source;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(width: 72, height: 64, child: NetImage(source.image, iconSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('[$index] ${source.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (source.subtitle != null)
                      Text(
                        source.subtitle!.split(' · ').map(label).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    if (source.price != null)
                      Text(formatPrice(source.price!, source.currency ?? 'USD'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          )),
                  ],
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary)),
            const SizedBox(width: 10),
            const Text('Qidiryapman…'),
          ],
        ),
      ),
    );
  }
}
