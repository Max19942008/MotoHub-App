import 'package:flutter/material.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import '../widgets/common.dart';
import 'community_screen.dart';

const _indigo = Color(0xFF6366F1);
const _cardShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 30, offset: Offset(0, 10)),
];

/// Website article page: boards, header card, content, comments.
/// Pops with a board id when the user taps another board.
class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key, required this.initial});
  final Article initial;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _repo = Repository.instance;
  final _text = TextEditingController();
  late Article _article = widget.initial;
  PageResult<Comment>? _comments;
  int _page = 1;
  bool _sending = false;
  bool _liking = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadComments();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final a = await _repo.article(widget.initial.id);
      if (mounted) setState(() => _article = a);
    } catch (_) {/* keep the list data */}
  }

  Future<void> _loadComments() async {
    try {
      final c = await _repo.comments(widget.initial.id, _page);
      if (mounted) setState(() => _comments = c);
    } catch (_) {}
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _like() async {
    if (!AuthService.instance.isLoggedIn) return _snack('Avval tizimga kiring');
    if (_liking) return;
    setState(() => _liking = true);
    try {
      await _repo.likeArticle(_article.id);
      await _refresh();
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _liking = false);
    }
  }

  Future<void> _send() async {
    final content = _text.text.trim();
    if (content.isEmpty || _sending) return;
    if (!AuthService.instance.isLoggedIn) return _snack('Avval tizimga kiring');
    setState(() => _sending = true);
    try {
      await _repo.addComment('ARTICLE', _article.id, content);
      _text.clear();
      _page = 1;
      await Future.wait([_loadComments(), _refresh()]);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _article;
    return Scaffold(
      appBar: AppBar(toolbarHeight: 60, title: const BrandLogo(height: 36)),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: communityBackground),
        child: RefreshIndicator(
          onRefresh: () => Future.wait([_refresh(), _loadComments()]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 20),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _indigo,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB), width: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text('Doskalar',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Brand.ink)),
              const SizedBox(height: 20),
              BoardList(
                selected: a.category,
                onPick: (c) => Navigator.pop(context, c),
              ),
              const SizedBox(height: 24),
              _header(a),
              const SizedBox(height: 24),
              _content(a),
              const SizedBox(height: 24),
              _commentsCard(),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration get _card => BoxDecoration(
        gradient:
            const LinearGradient(colors: [Colors.white, Color(0xFFF8F9FF)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: _cardShadow,
      );

  Widget _header(Article a) {
    Widget stat(IconData icon, int n) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: const Color(0xFF4B5563)),
            const SizedBox(width: 8),
            Text('$n',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Brand.ink)),
          ]),
        );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(colors: [_indigo, Color(0xFFA855F7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(a.category,
                  style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            const Spacer(),
            SiteGradientButton(
              label: 'Write Article',
              colors: const [_indigo, Color(0xFF4F46E5)],
              height: 36,
              fontSize: 13.5,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              onTap: () => openWriteArticle(context),
            ),
          ]),
          const SizedBox(height: 18),
          GradientTitle(a.title, size: 23),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 2, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _indigo, width: 2.5),
              ),
              child: ClipOval(child: NetImage(a.authorImage, iconSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.author,
                      style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Brand.ink)),
                  Text(articleDate(a.createdAt),
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF717171))),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            stat(Icons.visibility, a.views),
            stat(Icons.chat, a.comments),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _like,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: a.liked
                      ? const LinearGradient(
                          colors: [_indigo, Color(0xFFA855F7)])
                      : null,
                  color: a.liked ? null : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: a.liked
                      ? null
                      : Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(a.liked ? Icons.thumb_up_alt : Icons.thumb_up_off_alt,
                      size: 18, color: a.liked ? Colors.white : Brand.ink),
                  const SizedBox(width: 8),
                  Text('${a.likes}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: a.liked ? Colors.white : Brand.ink)),
                ]),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _content(Article a) {
    final images = RegExp(r'''<img[^>]+src=["']([^"']+)["']''')
        .allMatches(a.content)
        .map((m) => m.group(1)!)
        .toList();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientTitle('Maqola matni', size: 21),
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 20),
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [_indigo, Color(0xFFA855F7), Colors.transparent]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(plainText(a.content),
                    style: const TextStyle(
                        fontSize: 15, height: 1.7, color: Brand.ink)),
                for (final src in images)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: NetImage(src, fit: BoxFit.fitWidth),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentsCard() {
    final c = _comments;
    final total = c?.total ?? 0;
    final pages = (total / 5).ceil();
    final empty = _text.text.trim().isEmpty;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const GradientTitle('Izohlar', size: 22),
            Text(' ($total)',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF717171))),
          ]),
          const SizedBox(height: 18),
          TextField(
            controller: _text,
            maxLength: 100,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "Fikringizni baham ko'ring...",
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              counterText: '',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _indigo, width: 2)),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Text('${_text.text.length}/100',
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
            const Spacer(),
            SiteGradientButton(
              label: _sending ? '...' : 'Izoh qoldirish',
              colors: const [_indigo, Color(0xFF8B5CF6)],
              height: 36,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              onTap: empty || _sending ? null : _send,
            ),
          ]),
          if (c != null && c.items.isNotEmpty) ...[
            const SizedBox(height: 20),
            for (final m in c.items)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFFAFAFF)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _indigo, width: 2),
                      ),
                      child: ClipOval(
                          child: NetImage(m.authorImage, iconSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.author,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Brand.ink)),
                          Text(_commentDate(m.createdAt),
                              style: const TextStyle(
                                  fontSize: 11.5, color: Color(0xFF6B7280))),
                          const SizedBox(height: 8),
                          Text(m.content,
                              style: const TextStyle(
                                  fontSize: 14, color: Brand.ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (pages > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var p = 1; p <= pages; p++)
                  Padding(
                    padding: const EdgeInsets.all(3),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        _page = p;
                        _loadComments();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p == _page ? _indigo : Colors.transparent),
                        child: Text('$p',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: p == _page ? Colors.white : Brand.ink)),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// "Jan 15, 2026 • 13:27"
  static String _commentDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    final full = articleDate(l);
    final hm =
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    return '${full.substring(0, 3)}${full.substring(full.indexOf(' '))} • $hm';
  }
}
