import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import '../widgets/common.dart';
import '../widgets/detail_layout.dart';
import 'motorbike_detail_screen.dart';

/// The website's agent page: profile card, then "Bikes (n)" / "Reviews (n)" tabs.
class AgentDetailScreen extends StatefulWidget {
  const AgentDetailScreen({super.key, required this.agentId});
  final String agentId;

  @override
  State<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends State<AgentDetailScreen> {
  final _repo = Repository.instance;
  Agent? _agent;
  PageResult<Motorbike>? _bikes;
  int _reviews = 0;
  int _tab = 0;
  int _page = 1;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _repo.agent(widget.agentId),
        _repo.agentMotorbikes(widget.agentId, _page),
        _repo.comments(widget.agentId, 1),
      ]);
      if (!mounted) return;
      setState(() {
        _agent = results[0] as Agent;
        _following = _agent!.followed;
        _bikes = results[1] as PageResult<Motorbike>;
        _reviews = (results[2] as PageResult<Comment>).total;
      });
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _toPage(int p) async {
    setState(() => _page = p);
    final bikes = await _repo.agentMotorbikes(widget.agentId, p);
    if (mounted) setState(() => _bikes = bikes);
  }

  Future<void> _toggleFollow() async {
    try {
      _following
          ? await _repo.unfollow(widget.agentId)
          : await _repo.follow(widget.agentId);
      setState(() => _following = !_following);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _agent;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(toolbarHeight: 60, title: const BrandLogo(height: 36)),
      body: a == null
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                children: [
                  _profile(a),
                  const SizedBox(height: 28),
                  _tabs(),
                  const SizedBox(height: 24),
                  if (_tab == 0)
                    ..._bikesTab()
                  else
                    SiteReviews(group: 'MEMBER', refId: widget.agentId),
                ],
              ),
            ),
    );
  }

  Widget _profile(Agent a) {
    final me = AuthService.instance.member;
    final canFollow = me != null && me.id != a.id;
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: Column(children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Brand.ink)),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280))),
            ]),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xFF667EEA),
                Color(0xFF3B82F6),
                Color(0xFFEAB308),
                Color(0xFF4CAF50),
                Color(0xFF4CAF50)
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF3B82F6)]),
                      ),
                      child: ClipOval(child: NetImage(a.image, iconSize: 40)),
                    ),
                    Positioned(
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF4CAF50), Color(0xFF3B82F6)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text('AGENT',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(colors: [
                    Color(0xFF1B3A26),
                    Color(0xFF4CAF50),
                    Color(0xFF3B82F6)
                  ]).createShader(r),
                  child: Text(
                      (a.fullName?.isNotEmpty ?? false) ? a.fullName! : a.nick,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                const SizedBox(height: 6),
                Text((a.address ?? '').toUpperCase(),
                    style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5)),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: a.phone == null
                            ? null
                            : () =>
                                launchUrl(Uri(scheme: 'tel', path: a.phone)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 22, vertical: 11),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.phone, color: Colors.white, size: 19),
                            SizedBox(width: 8),
                            Text('Call',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                          ]),
                        ),
                      ),
                    ),
                    if (canFollow)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Brand.indigo,
                          side:
                              const BorderSide(color: Brand.indigo, width: 1.5),
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: _toggleFollow,
                        child: Text(_following ? 'Following' : 'Follow'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(children: [
                  stat('${a.properties}', 'MOTOTSIKLLAR'),
                  const SizedBox(width: 8),
                  stat('${a.likes}', 'YOQTIRISHLAR'),
                  const SizedBox(width: 8),
                  stat('${a.views}', "KO'RISHLAR"),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    Widget tab(int i, IconData icon, String label) {
      final active = _tab == i;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = i),
          child: Container(
            padding: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color:
                          active ? const Color(0xFFE53935) : Colors.transparent,
                      width: 2.5)),
            ),
            child: Column(children: [
              Icon(icon,
                  size: 18,
                  color: active ? Brand.green : const Color(0xFF6B7280)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      color: active ? Brand.green : const Color(0xFF6B7280))),
            ]),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
      child: Row(children: [
        tab(0, Icons.two_wheeler, 'Bikes (${_bikes?.total ?? 0})'),
        tab(1, Icons.star, 'Reviews ($_reviews)'),
        const Spacer(),
      ]),
    );
  }

  List<Widget> _bikesTab() {
    final bikes = _bikes;
    final total = bikes?.total ?? 0;
    final pages = (total / 9).ceil();
    return [
      Row(children: [
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(colors: [
            Color(0xFF1B3A26),
            Color(0xFF4CAF50),
            Color(0xFF3B82F6)
          ]).createShader(r),
          child: const Text('Mototsikllar',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
        const Spacer(),
        Text('$total available',
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF6B7280))),
      ]),
      const SizedBox(height: 20),
      if (bikes == null || bikes.items.isEmpty)
        const Padding(
          padding: EdgeInsets.all(30),
          child: Center(
              child: Text('Mototsikllar topilmadi!',
                  style: TextStyle(color: Brand.muted))),
        )
      else
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 24)
            ],
          ),
          child: Column(children: [
            for (final b in bikes.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SimilarCard(
                  image: b.images.isEmpty ? null : b.images.first,
                  price: formatPrice(b.price, b.currency),
                  title: b.title,
                  location: b.location,
                  pills: [
                    (Icons.engineering, '${b.engineCc} CC'),
                    (Icons.speed, '${b.mileage} km'),
                    (Icons.sell, b.brand),
                  ],
                  views: b.views,
                  likes: b.likes,
                  rent: b.rent,
                  barter: b.barter,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => MotorbikeDetailScreen(initial: b))),
                ),
              ),
          ]),
        ),
      if (pages > 1)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var p = 1; p <= pages; p++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _toPage(p),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p == _page ? Brand.green : Colors.white,
                        border: Border.all(
                            color: p == _page
                                ? Brand.green
                                : const Color(0xFFE5E7EB)),
                      ),
                      child: Text('$p',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: p == _page ? Colors.white : Brand.ink)),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ];
  }
}
