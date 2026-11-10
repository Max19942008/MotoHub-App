import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../config.dart';
import '../models/listing.dart';
import '../screens/agent_detail_screen.dart';
import '../theme.dart';
import 'common.dart';

/// Videos the website plays (served from the site itself).
const heroVideos = [
  '$siteUrl/video/3936776-hd_1920_1080_25fps.mp4',
  '$siteUrl/video/5052417-hd_1920_1080_30fps.mp4',
  '$siteUrl/video/5052676-hd_1920_1080_30fps.mp4',
];
const adVideo =
    '$siteUrl/video/mixkit-motorcyclist-crossing-a-desert-surrounded-by-mountains-39926-hd-ready.mp4';

/// Muted, auto-playing background video; cycles through [urls].
class BackgroundVideo extends StatefulWidget {
  const BackgroundVideo(
      {super.key, required this.urls, this.dim = 0.45, this.grayscale = false});
  final List<String> urls;
  final double dim;
  final bool grayscale;

  @override
  State<BackgroundVideo> createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<BackgroundVideo> {
  VideoPlayerController? _c;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final old = _c;
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.urls[_index]));
    _c = c;
    old?.dispose();
    try {
      await c.initialize();
      await c.setVolume(0);
      await c.setLooping(widget.urls.length == 1);
      c.addListener(_onTick);
      await c.play();
    } catch (_) {/* offline: the dark backdrop stays */}
    if (mounted) setState(() {});
  }

  void _onTick() {
    final c = _c;
    if (c == null || widget.urls.length < 2) return;
    final v = c.value;
    if (v.isInitialized &&
        !v.isPlaying &&
        v.position >= v.duration &&
        v.duration > Duration.zero) {
      c.removeListener(_onTick);
      _index = (_index + 1) % widget.urls.length;
      _open();
    }
  }

  @override
  void dispose() {
    _c?.removeListener(_onTick);
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    Widget video = const SizedBox.expand();
    if (c != null && c.value.isInitialized) {
      video = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c)),
      );
      if (widget.grayscale) {
        video = ColorFiltered(
          colorFilter: const ColorFilter.matrix([
            0.45, 0.45, 0.1, 0, 0, //
            0.45, 0.45, 0.1, 0, 0,
            0.45, 0.45, 0.1, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: video,
        );
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Color(0xFF0F1114)),
        video,
        ColoredBox(color: Colors.black.withValues(alpha: widget.dim)),
      ],
    );
  }
}

/// Home hero: video with "All Bikes. One Place."
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final h = (MediaQuery.sizeOf(context).height * 0.56).clamp(320.0, 480.0);
    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const BackgroundVideo(urls: heroVideos, dim: 0.42, grayscale: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('All Bikes. One Place.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.15)),
                SizedBox(height: 10),
                Text(
                    'Looping hero videos keep the spotlight on fresh listings while you search.',
                    style: TextStyle(
                        color: Color(0xD9FFFFFF), fontSize: 15, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The desert ride video between the home carousels.
class AdvertisementVideo extends StatelessWidget {
  const AdvertisementVideo({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
      height: 260, child: BackgroundVideo(urls: [adVideo], dim: 0.0));
}

/// A home section: gradient title with an underline, an emoji subtitle, content.
class SiteSection extends StatelessWidget {
  const SiteSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
    required this.child,
    this.background = Colors.white,
    this.underline,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> gradient;
  final Widget child;
  final Color background;
  final Color? underline;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 40, 10, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: ShaderMask(
                shaderCallback: (r) =>
                    LinearGradient(colors: gradient).createShader(r),
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.35,
                        letterSpacing: -0.6)),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 6, bottom: 12),
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                  color: underline ?? gradient.first,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text('$emoji  $subtitle',
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280))),
            const SizedBox(height: 26),
            child,
          ],
        ),
      ),
    );
  }
}

/// One-card-at-a-time slider with the site's "← • • • →" bar underneath.
class SiteCarousel extends StatefulWidget {
  const SiteCarousel({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.height,
    required this.color,
    this.chevrons = false,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double height;
  final Color color;

  /// The agents slider uses ‹ › instead of arrows.
  final bool chevrons;

  @override
  State<SiteCarousel> createState() => _SiteCarouselState();
}

class _SiteCarouselState extends State<SiteCarousel> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _to(int i) => _pages.animateToPage(i.clamp(0, widget.itemCount - 1),
      duration: const Duration(milliseconds: 350), curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    Widget arrow(bool left) => GestureDetector(
          onTap: () => _to(_index + (left ? -1 : 1)),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: widget.color.withValues(alpha: 0.18), blurRadius: 10)
              ],
            ),
            child: Icon(
              widget.chevrons
                  ? (left
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded)
                  : (left
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded),
              color: widget.color,
              size: widget.chevrons ? 30 : 24,
            ),
          ),
        );

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pages,
            itemCount: widget.itemCount,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: widget.itemBuilder(context, i),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              arrow(true),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < widget.itemCount; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 9),
                        width: i == _index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? widget.color
                              : widget.color.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
              arrow(false),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Elite riders" card: round photo with a ★ rank badge, name, AGENT pill, phone.
class AgentCard extends StatelessWidget {
  const AgentCard({super.key, required this.agent});
  final Agent agent;

  @override
  Widget build(BuildContext context) {
    final phone = agent.phone ?? '';
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => AgentDetailScreen(agentId: agent.id))),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 176,
                height: 176,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFE0E0FB)),
                child: ClipOval(child: NetImage(agent.image, iconSize: 48)),
              ),
              Positioned(
                right: -4,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Brand.indigo, Brand.indigoDark]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Brand.indigo.withValues(alpha: 0.35),
                          blurRadius: 10)
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 15),
                    const SizedBox(width: 3),
                    Text(agent.rank.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(agent.nick,
              style: const TextStyle(
                  fontSize: 21, fontWeight: FontWeight.w800, color: Brand.ink)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1FD),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDADAF8)),
            ),
            child: const Text('AGENT',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.8)),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => launchUrl(Uri(scheme: 'tel', path: phone)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7FE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDADAF8)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.call, size: 17, color: Brand.indigo),
                  const SizedBox(width: 8),
                  Text(phone,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Brand.ink)),
                ]),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

/// The website footer (dark).
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF9CA3AF);
    Widget column(String title, List<Widget> links) => Padding(
          padding: const EdgeInsets.only(top: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              ...links.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 14), child: l)),
            ],
          ),
        );
    Text link(String t) =>
        Text(t, style: const TextStyle(color: muted, fontSize: 14));

    Widget contact(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 26),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Icon(icon, color: const Color(0xFFFF7A18), size: 22)),
              const SizedBox(width: 22),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        );

    Widget social(IconData icon) => Container(
          width: 46,
          height: 46,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: muted, size: 20),
        );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Brand.ink, Color(0xFF0F1114)]),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              color: Colors.black,
              padding: const EdgeInsets.all(4),
              child: const BrandLogo(height: 40)),
          const SizedBox(height: 22),
          const Text(
            'Mukammal mototsiklni topishda ishonchli hamkoringiz. Mototsikl xizmatlari va hamjamiyatida mukammallikni his eting.',
            style: TextStyle(color: muted, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 34),
          contact(Icons.phone, 'BUTUNLAY BEPUL MIJOZLARGA XIZMAT',
              '+82 10 4867 2909'),
          contact(Icons.email, 'JONLI YORDAM KERAKMI?', 'support@motohub.com'),
          const SizedBox(height: 8),
          const Text('Bizni Ijtimoiy Tarmoqlarda Kuzating',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 18),
          Row(children: [
            social(Icons.facebook),
            social(Icons.send),
            social(Icons.camera_alt_outlined),
            social(Icons.flutter_dash)
          ]),
          const SizedBox(height: 44),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Yangiliklardan xabardor bo'ling",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text(
                    "Eng so'nggi mototsikl yangiliklari va takliflari uchun obuna bo'ling",
                    style: TextStyle(color: muted, fontSize: 14, height: 1.5)),
                const SizedBox(height: 14),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email manzilingizni kiriting',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.15))),
                  ),
                ),
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: Brand.greenGradient,
                      borderRadius: BorderRadius.circular(12)),
                  child: const SizedBox(
                    height: 46,
                    child: Center(
                      child: Text("Obuna bo'lish",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          column('Ommabop Qidiruv', [
            link('Sport mototsikllar'),
            link('Kruizer mototsikllar'),
            link('Yangi kelganlar'),
            link('Eng yaxshi takliflar'),
          ]),
          column('Tezkor Havolalar', [
            link('Foydalanish shartlari'),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(privacyUrl),
                  mode: LaunchMode.externalApplication),
              child: link('Maxfiylik siyosati'),
            ),
            link('Narx rejalari'),
            link('Bizning xizmatlar'),
            link("Qo'llab-quvvatlashga murojaat"),
            link("Ko'p so'raladigan savollar"),
          ]),
          column('Turkumlar', [
            link('Sport mototsikllar'),
            link('Kruizerlar'),
            link('Turing'),
            link('Sarguzasht')
          ]),
          const SizedBox(height: 30),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 22),
          const Center(
            child: Text('© MOTOPRESTO - Barcha huquqlar himoyalangan.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
