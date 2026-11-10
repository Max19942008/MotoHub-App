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

class _AssistantScreenState extends State<AssistantScreen>
    with AutomaticKeepAliveClientMixin {
  final _turns = <ChatTurn>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  final _reported = <int>{};

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

  Future<void> _report(int index) async {
    final answer = _turns[index];
    final question = _turns
        .take(index)
        .lastWhere((t) => t.isUser, orElse: () => ChatTurn.user('-'))
        .text;
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReportSheet(question: question, answer: answer.text),
    );
    if (sent == true && mounted) {
      setState(() => _reported.add(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Rahmat! Shikoyatingiz qabul qilindi, uni ko\'rib chiqamiz.')),
      );
    }
  }

  Future<void> _openSource(AiSource s) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      if (s.type == 'PROPERTY') {
        final bike = await Repository.instance.motorbike(s.id);
        navigator.push(MaterialPageRoute(
            builder: (_) => MotorbikeDetailScreen(initial: bike)));
      } else if (s.type == 'PART') {
        final part = await Repository.instance.part(s.id);
        navigator.push(
            MaterialPageRoute(builder: (_) => PartDetailScreen(initial: part)));
      } else {
        messenger.showSnackBar(const SnackBar(
            content: Text('Maqolalarni saytda o\'qishingiz mumkin.')));
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
                    return _TurnView(
                      turn: _turns[i],
                      onSource: _openSource,
                      reported: _reported.contains(i),
                      onReport: () => _report(i),
                    );
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
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
        Icon(Icons.smart_toy_outlined,
            size: 56, color: theme.colorScheme.primary),
        const SizedBox(height: 12),
        Text('MOTOPRESTO AI yordamchi',
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'O\'zbek, rus yoki ingliz tilida yozing — men MOTOPRESTO e\'lonlaridan mos mototsikl va qismlarni topib beraman. '
          'Javoblar sun\'iy intellekt tomonidan yaratiladi va xato bo\'lishi mumkin.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        for (final s in _suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  const _TurnView(
      {required this.turn,
      required this.onSource,
      required this.reported,
      required this.onReport});
  final ChatTurn turn;
  final ValueChanged<AiSource> onSource;
  final bool reported;
  final VoidCallback onReport;

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
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment:
                turn.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(turn.isUser ? 16 : 4),
                    bottomRight: Radius.circular(turn.isUser ? 4 : 16),
                  ),
                ),
                child: SelectableText(turn.text,
                    style: TextStyle(color: fg, height: 1.4)),
              ),
              for (var n = 0; n < turn.sources.length; n++)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _SourceCard(
                      index: n + 1,
                      source: turn.sources[n],
                      onTap: () => onSource(turn.sources[n])),
                ),
              if (!turn.isUser && !turn.isError)
                _AnswerFooter(reported: reported, onReport: onReport),
            ],
          ),
        ),
      ),
    );
  }
}

/// "AI javobi" note + report button under every assistant answer.
class _AnswerFooter extends StatelessWidget {
  const _AnswerFooter({required this.reported, required this.onReport});
  final bool reported;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text('AI javobi, xato bo\'lishi mumkin', style: muted),
          reported
              ? Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('· Shikoyat yuborildi', style: muted),
                )
              : TextButton.icon(
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Shikoyat qilish'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: theme.colorScheme.error,
                    textStyle: theme.textTheme.bodySmall,
                  ),
                ),
        ],
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  AiReportReason? _reason;
  final _comment = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await AssistantApi.instance.report(
        reason: reason,
        question: widget.question,
        answer: widget.answer,
        comment: _comment.text,
      );
      if (mounted) Navigator.of(context).pop(true);
      return;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Yuborib bo\'lmadi, qayta urinib ko\'ring.';
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('AI javobi ustidan shikoyat', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Bu javobda nima noto\'g\'ri?',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          RadioGroup<AiReportReason>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(
              children: [
                for (final r in AiReportReason.values)
                  RadioListTile<AiReportReason>(
                    value: r,
                    title: Text(r.label),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            maxLength: 500,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
                labelText: 'Izoh (ixtiyoriy)', border: OutlineInputBorder()),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          FilledButton(
            onPressed: _reason == null || _sending ? null : _submit,
            child: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Yuborish'),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard(
      {required this.index, required this.source, required this.onTap});
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
            SizedBox(
                width: 72,
                height: 64,
                child: NetImage(source.image, iconSize: 24)),
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
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (source.subtitle != null)
                      Text(
                        source.subtitle!.split(' · ').map(label).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
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
        decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: scheme.primary)),
            const SizedBox(width: 10),
            const Text('Qidiryapman…'),
          ],
        ),
      ),
    );
  }
}
