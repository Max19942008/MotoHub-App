import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../models/listing.dart';
import '../screens/agent_detail_screen.dart';
import '../theme.dart';
import '../utils/labels.dart';
import 'common.dart';

/// Colored icon tile in the "options" box (Dvigatel, Yurgan masofa, …).
class Spec {
  const Spec(this.icon, this.label, this.value, this.colors);
  final IconData icon;
  final String label;
  final String value;
  final List<Color> colors;
}

/// The site's spec tile gradients, in page order.
const specRed = [Color(0xFFFF6B6B), Color(0xFFEE5A6F)];
const specBlue = [Color(0xFF3B82F6), Color(0xFF2563EB)];
const specAmber = [Color(0xFFEAB308), Color(0xFFCA8A04)];
const specGreen = [Color(0xFF4CAF50), Color(0xFF43A047)];
const specPurple = [Color(0xFFA855F7), Color(0xFF9333EA)];

/// One row of the "… tafsilotlari" box.
class DetailRow {
  const DetailRow(this.label, this.value);
  final String label;
  final String value;
}

/// The website's listing detail page (mobile), shared by bikes and parts.
class SiteDetailPage extends StatefulWidget {
  const SiteDetailPage({
    super.key,
    required this.id,
    required this.crumb,
    required this.title,
    required this.typeBadge,
    required this.location,
    required this.images,
    required this.price,
    required this.pricePeriod,
    required this.overlayPeriod,
    required this.views,
    required this.likes,
    required this.liked,
    required this.interested,
    required this.seller,
    required this.specs,
    required this.descTitle,
    required this.description,
    required this.detailsTitle,
    required this.details,
    required this.onLike,
    required this.onInterest,
    required this.onRefresh,
    this.commentGroup,
    required this.similarTitle,
    required this.similarSubtitle,
    required this.similar,
  });

  final String id;

  /// "Mototsikl" / "Ehtiyot qism" in the breadcrumb.
  final String crumb;
  final String title;
  final String typeBadge;
  final String location;
  final List<String> images;
  final String price;

  /// "total" / "per month" under the price card.
  final String pricePeriod;

  /// "/month" / "/exchange" / "" on the photo.
  final String overlayPeriod;
  final int views;
  final int likes;
  final bool liked;
  final bool interested;
  final Seller? seller;
  final List<Spec> specs;
  final String descTitle;
  final String? description;
  final String detailsTitle;
  final List<DetailRow> details;
  final Future<void> Function() onLike;
  final Future<void> Function() onInterest;
  final Future<void> Function() onRefresh;

  /// PROPERTY → reviews section shown (parts have none on the site).
  final String? commentGroup;
  final String similarTitle;
  final String similarSubtitle;
  final Future<List<Widget>> similar;

  @override
  State<SiteDetailPage> createState() => _SiteDetailPageState();
}

class _SiteDetailPageState extends State<SiteDetailPage> {
  int _image = 0;
  bool _sending = false;
  bool _interestSent = false;

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  bool _requireLogin() {
    if (AuthService.instance.isLoggedIn) return true;
    _toast("Avval tizimga kiring");
    return false;
  }

  Future<void> _like() async {
    if (!_requireLogin()) return;
    try {
      await widget.onLike();
      await widget.onRefresh();
      _toast('success');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _interest() async {
    if (widget.interested || _interestSent || _sending) return;
    if (!_requireLogin()) return;
    setState(() => _sending = true);
    try {
      await widget.onInterest();
      _interestSent = true;
      _toast('Sotuvchi qiziqishingizdan xabardor qilindi!');
      await widget.onRefresh();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _call() async {
    final phone = widget.seller?.phone;
    if (phone == null || phone.isEmpty) return;
    final uri =
        Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
    if (!await launchUrl(uri) && mounted) _toast('Telefon: $phone');
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? <String>[''] : widget.images;
    final interested = widget.interested || _interestSent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          toolbarHeight: 60,
          automaticallyImplyLeading: false,
          title: const BrandLogo(height: 36)),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // Breadcrumb + back
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                const Text('Bosh sahifa',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const Text('/',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                Text(widget.crumb,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
                const Text('/',
                    style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                Text(widget.title,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Brand.ink,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Orqaga'),
              ),
            ),
            const SizedBox(height: 28),

            // Main photo with badges and price overlay
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 260,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    NetImage(images[_image], iconSize: 60),
                    Positioned(
                      left: 16,
                      top: 16,
                      right: 16,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _whitePill(Text(widget.typeBadge.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Brand.ink))),
                          const SizedBox(width: 8),
                          _whitePill(
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Brand.ink),
                            Text(widget.location,
                                style: const TextStyle(
                                    fontSize: 13, color: Brand.ink)),
                          ])),
                          const Spacer(),
                          _darkPill(
                              Icons.visibility_outlined, '${widget.views}'),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _like,
                            child: _darkPill(
                                widget.liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                '${widget.likes}',
                                iconColor: widget.liked
                                    ? const Color(0xFFE91E63)
                                    : Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('NARX',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            Text(widget.price,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800)),
                            if (widget.overlayPeriod.isNotEmpty)
                              Text(widget.overlayPeriod,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (images.length > 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setState(() => _image = i),
                    child: Container(
                      width: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: i == _image ? Brand.ink : Colors.transparent,
                            width: 2),
                        boxShadow: i == _image
                            ? [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: NetImage(images[i], iconSize: 18)),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Pricing card + actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF8F9FA), Colors.white]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NARX',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF717171),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(widget.price,
                      style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Brand.ink)),
                  Text(widget.pricePeriod,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF717171))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _actionButton(
              filled: true,
              icon: Icons.phone,
              label: 'Call Dealer',
              onTap: _call,
            ),
            const SizedBox(height: 12),
            _actionButton(
              icon: interested ? Icons.check_circle : Icons.handshake,
              label: interested
                  ? 'Sotuvchi xabardor qilindi'
                  : (_sending ? 'Yuborilmoqda…' : 'Qiziqaman'),
              onTap: _interest,
              done: interested,
            ),
            const SizedBox(height: 12),
            _actionButton(
              icon: widget.liked ? Icons.favorite : Icons.favorite_border,
              iconColor: widget.liked ? const Color(0xFFE91E63) : null,
              label: widget.liked ? 'Liked' : 'Like',
              onTap: _like,
            ),
            const SizedBox(height: 14),
            if (widget.seller != null) _dealerCard(widget.seller!),
            const SizedBox(height: 36),

            // Options box
            _rainbowBox(
              top: const LinearGradient(colors: [
                Color(0xFFFF6B6B),
                Color(0xFF3B82F6),
                Color(0xFFEAB308),
                Color(0xFF4CAF50),
                Color(0xFFA855F7)
              ]),
              child: Column(
                children: [for (final s in widget.specs) _specTile(s)],
              ),
            ),
            const SizedBox(height: 28),

            // Description + details
            _rainbowBox(
              top: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF43A047)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(widget.descTitle),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF8F9FA), Colors.white]),
                      borderRadius: BorderRadius.circular(12),
                      border: const Border(
                          left: BorderSide(color: Color(0xFF4CAF50), width: 4)),
                    ),
                    child: Text(
                        plainText(widget.description).isEmpty
                            ? 'No Description!'
                            : plainText(widget.description),
                        style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF4B5563),
                            height: 1.6)),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 28),
                    height: 2,
                    decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [
                      Color(0xFF4CAF50),
                      Color(0xFFE0E0E0),
                      Colors.transparent
                    ])),
                  ),
                  _sectionTitle(widget.detailsTitle),
                  for (final d in widget.details) _detailRow(d),
                ],
              ),
            ),

            if (widget.commentGroup != null) ...[
              const SizedBox(height: 28),
              SiteReviews(group: widget.commentGroup!, refId: widget.id),
            ],
            const SizedBox(height: 28),

            // Related
            _rainbowBox(
              top: const LinearGradient(colors: [
                Color(0xFFEAB308),
                Color(0xFF4CAF50),
                Color(0xFFA855F7)
              ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => const LinearGradient(colors: [
                      Color(0xFF1B3A26),
                      Color(0xFF4CAF50),
                      Color(0xFF3B82F6)
                    ]).createShader(r),
                    child: Text(widget.similarTitle,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.3)),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 12),
                    width: 80,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(widget.similarSubtitle,
                      style: const TextStyle(
                          fontSize: 15, color: Color(0xFF6B7280), height: 1.6)),
                  const SizedBox(height: 32),
                  FutureBuilder<List<Widget>>(
                    future: widget.similar,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()));
                      }
                      final cards = snap.data ?? const [];
                      return Column(
                        children: [
                          for (final c in cards)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: c),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whitePill(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  Widget _darkPill(IconData icon, String text,
          {Color iconColor = Colors.white}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool filled = false,
    bool done = false,
    Color? iconColor,
  }) {
    const green = Color(0xFF4CAF50);
    final style = TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        color: filled || done ? Colors.white : green);
    final child = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon,
          size: 21,
          color: iconColor ?? (filled || done ? Colors.white : green)),
      const SizedBox(width: 10),
      Flexible(
          child: Text(label, style: style, overflow: TextOverflow.ellipsis)),
    ]);
    return SizedBox(
      height: filled ? 54 : 50,
      child: Material(
        color: filled || done ? green : Colors.white,
        elevation: filled ? 4 : 0,
        shadowColor: green.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: filled
              ? BorderSide.none
              : const BorderSide(color: green, width: 2),
        ),
        child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: child),
      ),
    );
  }

  Widget _dealerCard(Seller s) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            ClipOval(
                child: SizedBox.square(
                    dimension: 80, child: NetImage(s.image, iconSize: 30))),
            const SizedBox(height: 14),
            Text(s.nick.isEmpty ? 'Dealer' : s.nick,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Brand.ink)),
            const SizedBox(height: 4),
            Text(widget.location,
                style: const TextStyle(fontSize: 14, color: Color(0xFF717171))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _call,
                icon: const Icon(Icons.phone, size: 19),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4CAF50),
                  side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AgentDetailScreen(agentId: s.id))),
                child: const Text('View Dealer'),
              ),
            ),
          ],
        ),
      );

  Widget _rainbowBox({required Gradient top, required Widget child}) =>
      Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8F9FF)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 8))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, decoration: BoxDecoration(gradient: top)),
            Padding(
                padding: const EdgeInsets.fromLTRB(26, 32, 26, 32),
                child: child),
          ],
        ),
      );

  Widget _specTile(Spec s) => Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: s.colors),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: s.colors.first.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Icon(s.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.label.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(s.value,
                      style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B3A26))),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                      colors: [Color(0xFF1B3A26), Color(0xFF4CAF50)])
                  .createShader(r),
              child: Text(t,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 50,
              height: 3,
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFF4CAF50), Colors.transparent])),
            ),
          ],
        ),
      );

  Widget _detailRow(DetailRow d) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                        letterSpacing: 1.2)),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 50,
                  height: 3,
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF4CAF50), Colors.transparent])),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFF1B3A26), Color(0xFF2E7D32)])
                    .createShader(r),
                child: Text(d.value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      );
}

/// "Izohlar" list + "Fikringizni qoldiring" box.
class SiteReviews extends StatefulWidget {
  const SiteReviews({super.key, required this.group, required this.refId});
  final String group;
  final String refId;

  @override
  State<SiteReviews> createState() => _ReviewsState();
}

class _ReviewsState extends State<SiteReviews> {
  final _text = TextEditingController();
  late Future<PageResult<Comment>> _comments =
      Repository.instance.comments(widget.refId, 1);
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _text.text.trim();
    if (content.isEmpty || _sending) return;
    if (!AuthService.instance.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Avval tizimga kiring')));
      return;
    }
    setState(() => _sending = true);
    try {
      await Repository.instance.addComment(widget.group, widget.refId, content);
      _text.clear();
      setState(() => _comments = Repository.instance.comments(widget.refId, 1));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder<PageResult<Comment>>(
          future: _comments,
          builder: (context, snap) {
            final list = snap.data?.items ?? const <Comment>[];
            if (list.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 28),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFC107)),
                    const SizedBox(width: 8),
                    Text('${snap.data!.total} Izohlar',
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Brand.ink)),
                  ]),
                  const SizedBox(height: 16),
                  for (final c in list)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                          border: Border(
                              top: BorderSide(color: Color(0xFFF0F0F0)))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            ClipOval(
                                child: SizedBox.square(
                                    dimension: 40,
                                    child:
                                        NetImage(c.authorImage, iconSize: 18))),
                            const SizedBox(width: 12),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.author,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Brand.ink)),
                                  if (c.createdAt != null)
                                    Text(_date(c.createdAt!),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9CA3AF))),
                                ]),
                          ]),
                          const SizedBox(height: 10),
                          Text(c.content,
                              style: const TextStyle(
                                  color: Color(0xFF4B5563), height: 1.5)),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [Colors.white, Color(0xFFF0F9FF)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0F2FE), width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 4,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                  Color(0xFF3B82F6)
                ])),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(46, 40, 46, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)])
                          .createShader(r),
                      child: const Text('Fikringizni qoldiring',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3)),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 30),
                      width: 60,
                      height: 4,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [Color(0xFF3B82F6), Colors.transparent])),
                    ),
                    const Text('👉  Tajriba',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Brand.ink)),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _text,
                      minLines: 5,
                      maxLines: 8,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        fillColor: const Color(0xFFFAFAFA),
                        contentPadding: const EdgeInsets.all(16),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0), width: 2)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                                color: Color(0xFF3B82F6), width: 2)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 62,
                      child: Material(
                        color: _text.text.trim().isEmpty
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: _text.text.trim().isEmpty ? null : _submit,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    _sending
                                        ? 'YUBORILMOQDA…'
                                        : 'SHARH YUBORISH',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                        color: _text.text.trim().isEmpty
                                            ? const Color(0xFFBDBDBD)
                                            : Colors.white)),
                                const SizedBox(width: 18),
                                Icon(Icons.north_east,
                                    color: _text.text.trim().isEmpty
                                        ? Colors.white
                                        : Colors.white,
                                    size: 26),
                              ]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _date(DateTime d) {
    const months = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktabr',
      'Noyabr',
      'Dekabr'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}, ${d.year}';
  }
}

/// "O'xshash …" card (the site's big card): photo with a white price tag,
/// title, location, three blue pills, then Rent / Barter tags and counters.
class SimilarCard extends StatelessWidget {
  const SimilarCard({
    super.key,
    required this.image,
    required this.price,
    required this.title,
    required this.location,
    required this.pills,
    required this.views,
    required this.likes,
    this.rent = false,
    this.barter = false,
    required this.onTap,
  });

  final String? image;
  final String price;
  final String title;
  final String location;
  final List<(IconData, String)> pills;
  final int views;
  final int likes;
  final bool rent;
  final bool barter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget tag(String t, bool on) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(t,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      on ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD))),
        );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 264,
                  child: Stack(fit: StackFit.expand, children: [
                    NetImage(image, iconSize: 40),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF2F2F2)]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(price,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Brand.ink)),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B3A26))),
                      const SizedBox(height: 14),
                      Row(children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFF4CAF50), size: 20),
                        const SizedBox(width: 8),
                        Text(location.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 14, color: Color(0xFF717171))),
                      ]),
                      const SizedBox(height: 30),
                      Row(children: [
                        for (var i = 0; i < pills.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(children: [
                                Icon(pills[i].$1,
                                    size: 15, color: const Color(0xFF3B82F6)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(pills[i].$2,
                                      maxLines: 1,
                                      overflow: TextOverflow.clip,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Brand.ink)),
                                ),
                              ]),
                            ),
                          ),
                        ],
                      ]),
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Divider(height: 1, color: Color(0xFFEEEEEE))),
                      Row(children: [
                        tag('Rent', rent),
                        const SizedBox(width: 8),
                        tag('Barter', barter),
                        const Spacer(),
                        const Icon(Icons.visibility_outlined,
                            color: Color(0xFF717171), size: 20),
                        const SizedBox(width: 6),
                        Text('$views',
                            style: const TextStyle(color: Color(0xFF717171))),
                        const SizedBox(width: 16),
                        const Icon(Icons.favorite_border,
                            color: Color(0xFF717171), size: 20),
                        const SizedBox(width: 6),
                        Text('$likes',
                            style: const TextStyle(color: Color(0xFF717171))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String detailYear(int year) => '$year';
String detailPrice(num price, String currency) => formatPrice(price, currency);
