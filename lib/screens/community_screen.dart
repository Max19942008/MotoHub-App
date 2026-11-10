import 'package:flutter/material.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_sections.dart';
import 'article_detail_screen.dart';
import 'write_article_screen.dart';

/// The four boards of the site's community page.
const communityBoards = [
  ('FREE', 'Erkin doska', 'Istalgan mavzuda ochiq suhbat', 'Free Board'),
  ('RECOMMEND', 'Tavsiya', 'Eng yaxshi joylar va xizmatlar', 'Recommend'),
  ('NEWS', 'Yangiliklar', 'Avto soha yangiliklari', 'News'),
  ('HUMOR', 'Hazil', "Memlar va o'yin-kulgu", 'Humor'),
];

/// English board name the site shows in badges ("Free Board", "Recommend"...).
String boardLabel(String category) => communityBoards
    .firstWhere((b) => b.$1 == category, orElse: () => communityBoards.first)
    .$4;

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July', //
  'August', 'September', 'October', 'November', 'December',
];

/// "December 24, 2025", the site's Moment format.
String articleDate(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  return '${_months[l.month - 1]} ${l.day.toString().padLeft(2, '0')}, ${l.year}';
}

/// Gradient page background used by the site's community pages.
const communityBackground = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFF8F9FF), Color(0xFFFFF5F5), Color(0xFFF0F9FF)],
);

/// Opens the write form, or asks to log in first (the site redirects to login).
Future<bool> openWriteArticle(BuildContext context) async {
  if (!AuthService.instance.isLoggedIn) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Avval tizimga kiring')));
    return false;
  }
  final created = await Navigator.push<bool>(
      context, MaterialPageRoute(builder: (_) => const WriteArticleScreen()));
  return created == true;
}

/// Website community page: dark banner, board list, latest posts, pagination.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _repo = Repository.instance;
  String _category = 'FREE';
  int _page = 1;
  PageResult<Article>? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await _repo.articles(_category, _page);
      if (mounted) setState(() => _result = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _pickBoard(String c) {
    if (c == _category) return;
    _category = c;
    _page = 1;
    _load();
  }

  Future<void> _like(Article a) async {
    if (!AuthService.instance.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avval tizimga kiring')));
      return;
    }
    try {
      await _repo.likeArticle(a.id);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _open(Article a) async {
    final board = await Navigator.push<String>(context,
        MaterialPageRoute(builder: (_) => ArticleDetailScreen(initial: a)));
    if (board != null && board != _category) {
      _pickBoard(board);
    } else {
      _load(); // views / likes / comments may have changed
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _result?.total ?? 0;
    final items = _result?.items ?? const <Article>[];
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: communityBackground),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _banner(total),
                  const SizedBox(height: 44),
                  const Text('Doskalar',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Brand.ink)),
                  const SizedBox(height: 20),
                  BoardList(selected: _category, onPick: _pickBoard),
                  if (total > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFF8F9FA), Colors.white]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.5),
                      ),
                      child: Text('Showing ${items.length} / $total',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF717171))),
                    ),
                  ],
                  const SizedBox(height: 32),
                  const GradientTitle("So'nggi postlar", size: 24),
                  const SizedBox(height: 6),
                  Text('Sorted by newest • ${boardLabel(_category)} board',
                      style: const TextStyle(
                          fontSize: 13.5, color: Color(0xFF717171))),
                  const SizedBox(height: 18),
                  if (_loading && _result == null)
                    const SizedBox(height: 260, child: LoadingView())
                  else if (_error != null && _result == null)
                    SizedBox(
                        height: 260,
                        child: MessageView(
                            icon: Icons.cloud_off,
                            message: _error!,
                            onRetry: _load))
                  else if (items.isEmpty)
                    const _NoArticles()
                  else
                    for (final a in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ArticleCard(
                            article: a,
                            onTap: () => _open(a),
                            onLike: () => _like(a)),
                      ),
                  if (total > 0) _pagination(total),
                  const SizedBox(height: 36),
                ],
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }

  Widget _banner(int total) {
    final boardName = boardLabel(_category);
    Widget stat(Widget top, String label) => Expanded(
          child: Container(
            height: 104,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                top,
                const SizedBox(height: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7))),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('HAMJAMIYAT',
              style: TextStyle(
                  fontSize: 11.5,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(colors: [
              Colors.white,
              Color(0xFFFF6B6B),
              Color(0xFF6366F1)
            ]).createShader(r),
            child: const Text('Suhbatni boshlang.',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.25)),
          ),
          const SizedBox(height: 12),
          Text(
              'Learn, share, and laugh with enthusiasts. Pick a lane and dive into the latest posts.',
              style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 22),
          SiteGradientButton(
            label: 'Write an article',
            colors: const [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
            radius: 14,
            height: 46,
            onTap: () async {
              if (await openWriteArticle(context)) {
                _page = 1;
                _load();
              }
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            stat(
              Column(children: [
                const Icon(Icons.article, color: Color(0xFFFF6B6B), size: 22),
                Text('$total',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ]),
              'MAQOLALAR',
            ),
            const SizedBox(width: 12),
            stat(
              Text(boardName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              'TURKUM',
            ),
          ]),
        ],
      ),
    );
  }

  Widget _pagination(int total) {
    final pages = (total / 6).ceil();
    Widget arrow(IconData icon, int target, bool enabled) => IconButton(
          onPressed: enabled
              ? () {
                  setState(() => _page = target);
                  _load();
                }
              : null,
          icon: Icon(icon, size: 20),
          color: Brand.muted,
        );
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(colors: [Colors.white, Color(0xFFF8F9FF)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            arrow(Icons.chevron_left, _page - 1, _page > 1),
            for (var p = 1; p <= pages; p++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    setState(() => _page = p);
                    _load();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p == _page
                          ? const Color(0xFFE53935)
                          : Colors.transparent,
                    ),
                    child: Text('$p',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: p == _page ? Colors.white : Brand.ink)),
                  ),
                ),
              ),
            arrow(Icons.chevron_right, _page + 1, _page < pages),
          ]),
          const SizedBox(height: 6),
          Text('Total $total article${total > 1 ? 's' : ''} available',
              style: const TextStyle(fontSize: 13, color: Color(0xFF717171))),
        ],
      ),
    );
  }
}

/// Vertical board tabs ("Erkin doska", "Tavsiya", ...), active one in a gradient.
class BoardList extends StatelessWidget {
  const BoardList({super.key, required this.selected, required this.onPick});
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final b in communityBoards)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _BoardTile(
              name: b.$2,
              desc: b.$3,
              active: b.$1 == selected,
              onTap: () => onPick(b.$1),
            ),
          ),
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile(
      {required this.name,
      required this.desc,
      required this.active,
      required this.onTap});
  final String name;
  final String desc;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: active
                ? const LinearGradient(colors: [
                    Color(0xFFA855F7),
                    Color(0xFFEC4899),
                    Color(0xFFF43F5E)
                  ])
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8F9FA)]),
            border: active
                ? null
                : Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: const Color(0xFFEC4899).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : Brand.ink)),
              const SizedBox(height: 4),
              Text(desc,
                  style: TextStyle(
                      fontSize: 13.5,
                      color: active
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF717171))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Site community card: photo with a date box, author, title, views / likes.
class ArticleCard extends StatelessWidget {
  const ArticleCard(
      {super.key,
      required this.article,
      required this.onTap,
      required this.onLike});
  final Article article;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final a = article;
    final d = a.createdAt?.toLocal();
    Widget chip(IconData icon, int n, {Color? color, VoidCallback? onTap}) =>
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: color ?? const Color(0xFF4B5563)),
              const SizedBox(width: 8),
              Text('$n',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Brand.ink)),
            ]),
          ),
        );
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient:
                const LinearGradient(colors: [Colors.white, Color(0xFFF8F9FF)]),
            border: Border.all(color: const Color(0xFFF0F0F0), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: Stack(fit: StackFit.expand, children: [
                  ArticleImage(a.image),
                  if (d != null)
                    Positioned(
                      right: 14,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          Text(_months[d.month - 1].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF4B5563))),
                          Text(d.day.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Brand.ink)),
                        ]),
                      ),
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.author,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6366F1))),
                    const SizedBox(height: 8),
                    Text(a.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Brand.ink)),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 12),
                    Row(children: [
                      chip(Icons.remove_red_eye, a.views),
                      const SizedBox(width: 12),
                      chip(a.liked ? Icons.favorite : Icons.favorite_border,
                          a.likes,
                          color: a.liked ? const Color(0xFFEF4444) : null,
                          onTap: onLike),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Article photo, or the site's default community picture.
class ArticleImage extends StatelessWidget {
  const ArticleImage(this.path, {super.key});
  final String? path;

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return Image.asset('assets/brand/community_default.png',
          fit: BoxFit.cover);
    }
    return NetImage(path);
  }
}

/// Two-tone gradient heading, like the site's "So'nggi postlar".
class GradientTitle extends StatelessWidget {
  const GradientTitle(this.text,
      {super.key,
      this.size = 24,
      this.colors = const [Color(0xFF181A20), Color(0xFF6366F1)]});
  final String text;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => LinearGradient(colors: colors).createShader(r),
      child: Text(text,
          style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3)),
    );
  }
}

/// Pill / rounded button filled with a gradient (site's primary buttons here).
class SiteGradientButton extends StatelessWidget {
  const SiteGradientButton({
    super.key,
    required this.label,
    required this.colors,
    required this.onTap,
    this.radius = 12,
    this.height = 44,
    this.fontSize = 15,
    this.padding = EdgeInsets.zero,
  });
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;
  final double radius;
  final double height;
  final double fontSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Ink(
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                    color: colors.first.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 5)),
              ],
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoArticles extends StatelessWidget {
  const _NoArticles();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 2),
      ),
      child: const Column(children: [
        Icon(Icons.error_outline, size: 44, color: Color(0xFFBDBDBD)),
        SizedBox(height: 10),
        Text('Maqola topilmadi!',
            style: TextStyle(fontSize: 15, color: Color(0xFF717171))),
      ]),
    );
  }
}
