import 'dart:async';

import 'package:flutter/material.dart' hide Text;
import 'package:url_launcher/url_launcher.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/paged_grid.dart';
import 'agent_detail_screen.dart';
import '../i18n/text.dart';
import '../i18n/i18n.dart';

/// The site's six agent card themes (top bar / ring / AGENT pill).
const agentThemes = <List<Color>>[
  [Color(0xFF667EEA), Color(0xFF764BA2)],
  [Color(0xFFF093FB), Color(0xFFF5576C)],
  [Color(0xFF4FACFE), Color(0xFF00F2FE)],
  [Color(0xFFFA709A), Color(0xFFFEE140)],
  [Color(0xFF30CFD0), Color(0xFF330867)],
  [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
];

enum _AgentSort {
  recent("So'nggi", 'createdAt', 'DESC'),
  oldest('Eng eski', 'createdAt', 'ASC'),
  liked("Eng ko'p yoqtirilgan", 'memberLikes', 'DESC'),
  viewed("Eng ko'p ko'rilgan", 'memberViews', 'DESC');

  const _AgentSort(this.label, this.field, this.direction);
  final String label;
  final String field;
  final String direction;
}

/// The website's agents page.
class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen>
    with AutomaticKeepAliveClientMixin {
  _AgentSort _sort = _AgentSort.recent;
  String _text = '';
  int _version = 0;
  Timer? _debounce;
  final _search = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _version++);

  Widget _header() {
    return Column(
      children: [
        const SizedBox(height: 28),
        const Text("O'zingizga mos agentni toping",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: Brand.ink)),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "Ishonchli agentlar bilan bog'laning va keyingi mototsiklingiz bo'yicha ekspert maslahatini oling",
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.6),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 16)
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _search,
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _text = v;
                    _reload();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Agentlarni ism, manzil bo'yicha qidiring...".tr,
                  hintStyle:
                      TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
                  prefixIcon: Icon(Icons.search, color: Brand.green),
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) => InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final box = context.findRenderObject() as RenderBox;
                    final pos = box.localToGlobal(
                        Offset(box.size.width - 200, box.size.height));
                    final picked = await showMenu<_AgentSort>(
                      context: context,
                      position: RelativeRect.fromLTRB(pos.dx, pos.dy, 16, 0),
                      color: Colors.white,
                      items: [
                        for (final s in _AgentSort.values)
                          PopupMenuItem(
                              value: s,
                              child: Text(s.label,
                                  style: TextStyle(
                                      fontWeight: s == _sort
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: s == _sort
                                          ? Brand.green
                                          : Brand.ink))),
                      ],
                    );
                    if (picked != null && picked != _sort) {
                      _sort = picked;
                      _reload();
                    }
                  },
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.filter_list,
                          size: 20, color: Brand.green),
                      const Expanded(
                          child: Text('Saralash',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 13.5, color: Color(0xFF374151)))),
                      Text(_sort.label,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Brand.ink)),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 20, color: Color(0xFF6B7280)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ColoredBox(
      color: const Color(0xFFF8F9FA),
      child: PagedGrid<Agent>(
        key: ValueKey('$_version-${_sort.name}-$_text'),
        top: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _header()),
        fetch: (page) => Repository.instance.agents(page,
            sort: _sort.field, direction: _sort.direction, text: _text),
        emptyMessage: 'Agentlar topilmadi',
        itemBuilder: (context, a) => AgentListCard(agent: a),
      ),
    );
  }
}

/// One agent card of the agents page.
class AgentListCard extends StatefulWidget {
  const AgentListCard({super.key, required this.agent});
  final Agent agent;

  @override
  State<AgentListCard> createState() => _AgentListCardState();
}

class _AgentListCardState extends State<AgentListCard> {
  late bool _liked = widget.agent.liked;
  late int _likes = widget.agent.likes;

  Future<void> _like() async {
    if (!AuthService.instance.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avval tizimga kiring')));
      return;
    }
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    try {
      await Repository.instance.likeMember(widget.agent.id);
    } on ApiException catch (e) {
      setState(() {
        _liked = !_liked;
        _likes += _liked ? 1 : -1;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.agent;
    final theme = agentThemes[a.variant];
    final rating = a.rank > 0 ? a.rank.toStringAsFixed(1) : '4.5';

    Widget stat(IconData icon, Color color, String value, String label) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.4)),
            ]),
          ),
        );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AgentDetailScreen(agentId: a.id))),
        child: Column(
          children: [
            Container(
                height: 5,
                decoration:
                    BoxDecoration(gradient: LinearGradient(colors: theme))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: theme),
                          boxShadow: [
                            BoxShadow(
                                color: theme.last.withValues(alpha: 0.35),
                                blurRadius: 16)
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: ClipOval(child: _avatar(a.image)),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: _like,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10)
                              ],
                            ),
                            child: Icon(
                                _liked ? Icons.favorite : Icons.favorite_border,
                                size: 20,
                                color: _liked
                                    ? const Color(0xFFF5576C)
                                    : const Color(0xFF667EEA)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)])
                        .createShader(r),
                    child: Text(a.nick,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: theme),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: theme.last.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: const Text('AGENT',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF8F9FF), Color(0xFFF3F4F6)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(children: [
                      _contact(
                          Icons.location_on,
                          const Color(0xFF667EEA),
                          const Color(0xFFE8EBFB),
                          (a.address == null || a.address!.isEmpty)
                              ? 'N/A'
                              : a.address!),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: a.phone == null
                            ? null
                            : () =>
                                launchUrl(Uri(scheme: 'tel', path: a.phone)),
                        child: _contact(Icons.phone, const Color(0xFFF5576C),
                            const Color(0xFFFDE8EB), a.phone ?? 'N/A'),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    stat(Icons.two_wheeler, const Color(0xFF4CAF50),
                        '${a.properties}', 'MOTOTSIKLLAR'),
                    const SizedBox(width: 10),
                    stat(Icons.visibility, const Color(0xFF3B82F6),
                        '${a.views}', "KO'RISHLAR"),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    stat(Icons.favorite, const Color(0xFFF5576C), '$_likes',
                        'YOQTIRISHLAR'),
                    const SizedBox(width: 10),
                    stat(
                        Icons.star, const Color(0xFFF59E0B), rating, 'REYTING'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? image) => (image == null || image.isEmpty)
      ? const ColoredBox(
          color: Color(0xFFE5E7EB),
          child: SizedBox.expand(
              child: Icon(Icons.person, size: 54, color: Colors.white)),
        )
      : NetImage(image, iconSize: 30);

  Widget _contact(IconData icon, Color color, Color bg, String text) =>
      Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ),
      ]);
}
