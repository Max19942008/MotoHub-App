import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/auth_service.dart';
import '../api/graphql_client.dart';
import '../api/repository.dart';
import '../config.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import '../widgets/common.dart';
import '../widgets/listing_card.dart';
import '../widgets/site_sections.dart';
import 'add_listing_screen.dart';
import 'agent_detail_screen.dart';
import 'article_detail_screen.dart';
import 'community_screen.dart';
import 'motorbike_detail_screen.dart';
import 'part_detail_screen.dart';

const _violet = Color(0xFF667EEA);
const _purple = Color(0xFF764BA2);
const _muted = Color(0xFF717171);

enum MySection {
  addBike("E'lon qo'shish", Icons.add_box_outlined),
  myBikes('Mening mototsikllarim', Icons.two_wheeler),
  addPart("Qism qo'shish", Icons.add_circle_outline),
  myParts('Mening qismlarim', Icons.build_outlined),
  favorites('Sevimlilarim', Icons.favorite_border),
  visited("Yaqinda ko'rilganlar", Icons.manage_search),
  followers('Obunachilarim', Icons.group_add_outlined),
  followings('Obunalarim', Icons.person_add_alt_1_outlined),
  articles('Maqolalar', Icons.explore_outlined),
  write('Maqola yozish', Icons.post_add),
  profile('Mening profilim', Icons.account_circle_outlined);

  const MySection(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// The website's "My page" on a phone: menu card on top, the chosen section below.
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key, required this.member});
  final Member member;

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  MySection _section = MySection.profile;
  final _contentKey = GlobalKey();

  Future<void> _pick(MySection s) async {
    if (s == MySection.write) {
      await openWriteArticle(context);
      return;
    }
    if (s == MySection.addBike || s == MySection.addPart) {
      final part = s == MySection.addPart;
      final saved = await Navigator.push<bool>(context,
          MaterialPageRoute(builder: (_) => AddListingScreen(isPart: part)));
      if (saved == true) _pick(part ? MySection.myParts : MySection.myBikes);
      return;
    }
    setState(() => _section = s);
    // Bring the section into view, like the site's page jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _contentKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 350));
      }
    });
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chiqish'),
        content: const Text('Hisobingizdan chiqmoqchimisiz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor qilish')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Chiqish')),
        ],
      ),
    );
    if (ok == true) await AuthService.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    return ColoredBox(
      color: const Color(0xFFF6F6F6),
      child: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC4C4C4)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x12181A20),
                      blurRadius: 4,
                      offset: Offset(0, 1))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MenuCard(
                      member: m,
                      section: _section,
                      onPick: _pick,
                      onLogout: _logout),
                  const SizedBox(height: 20),
                  KeyedSubtree(
                    key: _contentKey,
                    child: switch (_section) {
                      MySection.profile => _ProfileSection(member: m),
                      MySection.favorites => const _BikesSection(
                          visited: false, key: ValueKey('fav')),
                      MySection.visited => const _BikesSection(
                          visited: true, key: ValueKey('visited')),
                      MySection.followers => _FollowSection(
                          memberId: m.id,
                          followers: true,
                          key: const ValueKey('followers')),
                      MySection.followings => _FollowSection(
                          memberId: m.id,
                          followers: false,
                          key: const ValueKey('followings')),
                      MySection.articles => _ArticlesSection(memberId: m.id),
                      MySection.myBikes => const _ListingsSection(
                          part: false, key: ValueKey('myBikes')),
                      MySection.myParts => const _ListingsSection(
                          part: true, key: ValueKey('myParts')),
                      MySection.write ||
                      MySection.addBike ||
                      MySection.addPart =>
                        const SizedBox.shrink(),
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          const SiteFooter(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- menu

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.member,
    required this.section,
    required this.onPick,
    required this.onLogout,
  });
  final Member member;
  final MySection section;
  final ValueChanged<MySection> onPick;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    Widget title(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Text(t,
              style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  color: _muted)),
        );
    Widget item(MySection s) => _MenuItem(
        label: s.label,
        icon: s.icon,
        active: s == section,
        onTap: () => onPick(s));
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xC9C4C4C4)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x12181A20), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(children: [
              ClipOval(
                child: SizedBox.square(
                    dimension: 60,
                    child: member.image == null
                        ? const DefaultAvatar()
                        : NetImage(member.image, iconSize: 26)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.nick,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Brand.ink)),
                    const SizedBox(height: 6),
                    if (member.phone?.isNotEmpty == true)
                      Row(children: [
                        const Icon(Icons.phone_outlined,
                            size: 14, color: Brand.ink),
                        const SizedBox(width: 6),
                        Text(member.phone!,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _muted)),
                      ]),
                    const SizedBox(height: 4),
                    Text(member.type ?? 'USER',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red)),
                  ],
                ),
              ),
            ]),
          ),
          title('MANAGE LISTINGS'),
          // Dealers manage their own bikes and parts here, as on the site.
          if (member.isAgent) ...[
            item(MySection.addBike),
            item(MySection.myBikes),
            item(MySection.addPart),
            item(MySection.myParts),
          ],
          item(MySection.favorites),
          item(MySection.visited),
          item(MySection.followers),
          item(MySection.followings),
          title('COMMUNITY'),
          item(MySection.articles),
          item(MySection.write),
          title('MANAGE ACCOUNT'),
          item(MySection.profile),
          _MenuItem(
              label: 'Logout',
              icon: Icons.logout,
              active: false,
              onTap: onLogout),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : Brand.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: active ? Colors.black : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Grey circle with a white silhouette, the site's defaultUser picture.
class DefaultAvatar extends StatelessWidget {
  const DefaultAvatar({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFEDEDED),
        child: FittedBox(
          child: Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
      );
}

// ---------------------------------------------------------------- headers

/// "✨ My Profile" style heading with the violet underline and a subtitle.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle, {this.label, this.trailing});
  final String title;
  final String subtitle;
  final String? label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Text(label!,
                style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9CA3AF))),
          ShaderMask(
            shaderCallback: (r) =>
                const LinearGradient(colors: [_violet, _purple])
                    .createShader(r),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 24,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6, bottom: 10),
            width: 60,
            height: 3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_violet, _purple]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 14, height: 1.5, color: Color(0xFF6B7280))),
          if (trailing != null) ...[const SizedBox(height: 12), trailing!],
        ],
      ),
    );
  }
}

/// Dashed "nothing here" box with the site's ⓘ icon.
class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF8F9FF), Color(0xFFEEF0FF)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7CBF5), width: 1.5),
      ),
      child: Column(children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
          ),
          child: const Icon(Icons.priority_high,
              color: Color(0xFFD1D5DB), size: 30),
        ),
        const SizedBox(height: 14),
        Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: _violet)),
      ]),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager(
      {required this.page,
      required this.total,
      required this.perPage,
      required this.onPage});
  final int page;
  final int total;
  final int perPage;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final pages = (total / perPage).ceil();
    if (pages < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        children: [
          for (var p = 1; p <= pages; p++)
            Padding(
              padding: const EdgeInsets.all(3),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onPage(p),
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p == page ? _violet : Colors.white,
                    border: Border.all(
                        color: p == page ? _violet : const Color(0xFFE5E7EB)),
                  ),
                  child: Text('$p',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: p == page ? Colors.white : Brand.ink)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Loads one page of a list and re-loads on page change.
mixin _Paged<W extends StatefulWidget, T> on State<W> {
  int page = 1;
  PageResult<T>? result;
  String? error;

  Future<PageResult<T>> fetch(int page);

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final r = await fetch(page);
      if (mounted) {
        setState(() {
          result = r;
          error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.message);
    }
  }

  void goTo(int p) {
    setState(() => page = p);
    load();
  }

  Widget body(Widget Function(PageResult<T> r) builder) {
    if (error != null) {
      return MessageView(icon: Icons.cloud_off, message: error!, onRetry: load);
    }
    final r = result;
    if (r == null) return const SizedBox(height: 200, child: LoadingView());
    return builder(r);
  }
}

// ---------------------------------------------------------------- bikes

class _BikesSection extends StatefulWidget {
  const _BikesSection({super.key, required this.visited});
  final bool visited;

  @override
  State<_BikesSection> createState() => _BikesSectionState();
}

class _BikesSectionState extends State<_BikesSection>
    with _Paged<_BikesSection, Motorbike> {
  @override
  Future<PageResult<Motorbike>> fetch(int page) =>
      Repository.instance.myBikes(page, visited: widget.visited);

  @override
  Widget build(BuildContext context) {
    final total = result?.total ?? 0;
    final from = total == 0 ? 0 : (page - 1) * 6 + 1;
    final to = (page * 6).clamp(0, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          widget.visited ? "Yaqinda Ko'rilganlar" : 'Sevimlilarim',
          widget.visited
              ? "Ko'rish tarixingizni ko'ring • O'rgangan mototsikllaringizga qayting"
              : 'Sevimli mototsikllaringizni boshqaring • Saqlang va istalgan vaqtda qayting',
          label: widget.visited ? 'TARIX' : 'FAVORITES',
          trailing: Row(children: [
            Text('$total bikes',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Brand.ink)),
            const Spacer(),
            Text('Showing $from-$to of $total',
                style: const TextStyle(fontSize: 12.5, color: _muted)),
          ]),
        ),
        body((r) {
          if (r.items.isEmpty) {
            return _Empty(widget.visited
                ? "Yaqinda ko'rilganlar topilmadi!"
                : 'Sevimlilar topilmadi!');
          }
          return Column(children: [
            for (final bike in r.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ListingCard(
                  heroTag: 'my-${widget.visited}-${bike.id}',
                  image: bike.images.isEmpty ? null : bike.images.first,
                  title: bike.title,
                  kicker: '${bike.brand} · ${bike.year}',
                  badge: bike.type,
                  rating: siteRating(bike.rank),
                  price: formatPrice(bike.price, bike.currency),
                  location: label(bike.location),
                  address: bike.address,
                  views: bike.views,
                  likes: bike.likes,
                  chips: [
                    CardChip(Icons.speed, '${bike.mileage} milya'),
                    CardChip(Icons.two_wheeler, label(bike.condition)),
                    CardChip(Icons.engineering, '${bike.engineCc} cc'),
                  ],
                  action: 'Sotib Olish',
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                MotorbikeDetailScreen(initial: bike)));
                    load(); // an unlike there removes it from favourites
                  },
                ),
              ),
            _Pager(page: page, total: r.total, perPage: 6, onPage: goTo),
          ]);
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------- follows

class _FollowSection extends StatefulWidget {
  const _FollowSection(
      {super.key, required this.memberId, required this.followers});
  final String memberId;
  final bool followers;

  @override
  State<_FollowSection> createState() => _FollowSectionState();
}

class _FollowSectionState extends State<_FollowSection>
    with _Paged<_FollowSection, FollowMember> {
  @override
  Future<PageResult<FollowMember>> fetch(int page) => Repository.instance
      .follows(widget.memberId, page, followers: widget.followers);

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = Repository.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          widget.followers ? 'Followers' : 'Followings',
          widget.followers
              ? 'Sizni kuzatayotgan foydalanuvchilar'
              : 'Siz kuzatayotgan foydalanuvchilar',
        ),
        body((r) {
          if (r.items.isEmpty) {
            return _Empty(widget.followers
                ? "HALI OBUNACHILAR YO'Q!"
                : "HALI OBUNALAR YO'Q!");
          }
          return Column(children: [
            for (final f in r.items)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AgentDetailScreen(agentId: f.id))),
                      child: Row(children: [
                        ClipOval(
                          child: SizedBox.square(
                              dimension: 56,
                              child: f.image == null
                                  ? const DefaultAvatar()
                                  : NetImage(f.image, iconSize: 22)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(f.nick,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Brand.ink)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      _Count('Followers', f.followers),
                      _Count('Followings', f.followings),
                      Expanded(
                        child: InkWell(
                          onTap: () => _run(() => repo.likeMember(f.id)),
                          child: Row(children: [
                            Icon(
                                f.liked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 18,
                                color: f.liked ? Colors.red : _muted),
                            const SizedBox(width: 4),
                            Text('(${f.likes})',
                                style: const TextStyle(color: _muted)),
                          ]),
                        ),
                      ),
                    ]),
                    if (f.id != widget.memberId) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 40,
                        child: f.followed
                            ? OutlinedButton(
                                onPressed: () =>
                                    _run(() => repo.unfollow(f.id)),
                                child: const Text('Unfollow'))
                            : FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: _violet),
                                onPressed: () => _run(() => repo.follow(f.id)),
                                child: const Text('Follow')),
                      ),
                    ],
                  ],
                ),
              ),
            _Pager(page: page, total: r.total, perPage: 5, onPage: goTo),
          ]);
        }),
      ],
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.label, this.value);
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Text.rich(TextSpan(children: [
          TextSpan(
              text: '$label ',
              style: const TextStyle(fontSize: 13, color: _muted)),
          TextSpan(
              text: '($value)',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: Brand.ink)),
        ])),
      );
}

// ---------------------------------------------------------------- articles

class _ArticlesSection extends StatefulWidget {
  const _ArticlesSection({required this.memberId});
  final String memberId;

  @override
  State<_ArticlesSection> createState() => _ArticlesSectionState();
}

class _ArticlesSectionState extends State<_ArticlesSection>
    with _Paged<_ArticlesSection, Article> {
  @override
  Future<PageResult<Article>> fetch(int page) =>
      Repository.instance.memberArticles(widget.memberId, page);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Maqola', 'Sizni yana ko\'rganimizdan xursandmiz!'),
        body((r) {
          if (r.items.isEmpty) return const _Empty('Maqolalar topilmadi!');
          return Column(children: [
            for (final a in r.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ArticleCard(
                  article: a,
                  onTap: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ArticleDetailScreen(initial: a)));
                    load();
                  },
                  onLike: () async {
                    try {
                      await Repository.instance.likeArticle(a.id);
                      await load();
                    } on ApiException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    }
                  },
                ),
              ),
            _Pager(page: page, total: r.total, perPage: 6, onPage: goTo),
          ]);
        }),
      ],
    );
  }
}

// ---------------------------------------------------------------- profile

class _ProfileSection extends StatefulWidget {
  const _ProfileSection({required this.member});
  final Member member;

  @override
  State<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<_ProfileSection> {
  late final _nick = TextEditingController(text: widget.member.nick);
  late final _phone = TextEditingController(text: widget.member.phone ?? '');
  late final _address =
      TextEditingController(text: widget.member.address ?? '');
  late String? _image = widget.member.image;
  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nick, _phone, _address]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nick.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _changed =>
      _nick.text.trim() != widget.member.nick ||
      _phone.text.trim() != (widget.member.phone ?? '') ||
      _address.text.trim() != (widget.member.address ?? '') ||
      _image != widget.member.image;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final path = await Repository.instance.uploadImage(file.path, 'member');
      if (mounted) setState(() => _image = path);
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final nick = _nick.text.trim();
    final phone = _phone.text.trim();
    if (nick.length < 3 || nick.length > 20) {
      return _snack("Taxallus 3–20 belgidan iborat bo'lishi kerak");
    }
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(
        nick: nick == widget.member.nick ? null : nick,
        phone: phone == (widget.member.phone ?? '') ? null : phone,
        address: _address.text.trim() == (widget.member.address ?? '')
            ? null
            : _address.text.trim(),
        image: _image == widget.member.image ? null : _image,
      );
      _snack('Profil yangilandi');
    } on ApiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error),
        title: const Text("Hisobni o'chirish"),
        content: const Text(
          "Hisobingiz butunlay o'chiriladi: barcha qurilmalardagi sessiyalar yopiladi, "
          "e'lonlaringiz va maqolalaringiz saytdan olib tashlanadi. Buni qaytarib bo'lmaydi.",
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Bekor qilish')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AuthService.instance.deleteAccount();
      _snack("Hisobingiz o'chirildi");
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Widget _field(String label, IconData icon, Color iconColor,
          TextEditingController c, String hint,
          {TextInputType? keyboard}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    letterSpacing: 0.5,
                    fontWeight: FontWeight.w700,
                    color: _violet)),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: c,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFA0A0A0)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: _violet.withValues(alpha: 0.2), width: 2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _violet, width: 2)),
            ),
          ),
          const SizedBox(height: 18),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final canSave = _changed && !_saving && !_uploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.auto_awesome, color: _violet, size: 28),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (r) =>
                      const LinearGradient(colors: [_violet, _purple])
                          .createShader(r),
                  child: const Text('My Profile',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ]),
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 10),
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_violet, _purple]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('🌟 We are glad to see you again!',
                  style: TextStyle(fontSize: 15, color: _violet)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: [Colors.white, Color(0xFFF8F9FF)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _violet.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                  color: _violet.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (r) =>
                    const LinearGradient(colors: [_violet, _purple])
                        .createShader(r),
                child: const Text('Rasm',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(height: 18),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: _violet.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _uploading
                    ? const LoadingView()
                    : _image == null
                        ? const DefaultAvatar()
                        : NetImage(_image),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: SiteGradientButton(
                  label: 'Profil rasmini yuklash',
                  colors: const [_violet, _purple],
                  height: 44,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  onTap: _uploading ? null : _pickPhoto,
                ),
              ),
              const SizedBox(height: 12),
              const Text('A photo must be in JPG, JPEG or PNG format!',
                  style: TextStyle(fontSize: 12.5, color: _violet)),
              const SizedBox(height: 22),
              _field('USERNAME', Icons.person, const Color(0xFF5B3E96), _nick,
                  'Taxallusingiz'),
              _field('PHONE', Icons.phone, const Color(0xFFE11D48), _phone,
                  'Telefon raqamingiz',
                  keyboard: TextInputType.phone),
              _field('ADDRESS', Icons.location_on, const Color(0xFFEC4899),
                  _address, 'Manzilingiz'),
              Align(
                alignment: Alignment.centerRight,
                child: SiteGradientButton(
                  label: _saving ? '...' : 'Profilni yangilash  ↗',
                  colors: canSave
                      ? const [_violet, _purple]
                      : const [Color(0xFFC4C4C4), Color(0xFFBDBDBD)],
                  height: 44,
                  fontSize: 14.5,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  onTap: canSave ? _save : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextButton.icon(
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: _deleteAccount,
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text("Hisobni o'chirish"),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: _muted),
          onPressed: () => launchUrl(Uri.parse(privacyUrl),
              mode: LaunchMode.externalApplication),
          child: const Text('Maxfiylik siyosati'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- my listings

/// "My Bikes" / "My Parts": Active / Blocked / Archived tabs, edit, archive,
/// re-list and delete, like the site's garage page.
class _ListingsSection extends StatefulWidget {
  const _ListingsSection({super.key, required this.part});
  final bool part;

  @override
  State<_ListingsSection> createState() => _ListingsSectionState();
}

class _ListingsSectionState extends State<_ListingsSection> {
  static const _tabs = [
    ('ACTIVE', 'Faol'),
    ('HOLD', 'Bloklangan'),
    ('SOLD', 'Arxivlangan'),
  ];
  String _status = 'ACTIVE';
  int _page = 1;
  PageResult<Object>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = Repository.instance;
      final PageResult<Object> r = widget.part
          ? await repo.myParts(_status, _page)
          : await repo.myListings(_status, _page);
      if (mounted) {
        setState(() {
          _result = r;
          _error = null;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _setStatus(String id, String status) async {
    if (status == 'DELETE') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("E'lonni o'chirish"),
          content: const Text("Bu e'lon butunlay o'chiriladi."),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Bekor qilish')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("O'chirish")),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await Repository.instance.setListingStatus(id, status, part: widget.part);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _edit(Object item) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => item is Part
            ? AddListingScreen(isPart: true, part: item)
            : AddListingScreen(isPart: false, bike: item as Motorbike),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _addNew() async {
    final saved = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => AddListingScreen(isPart: widget.part)));
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final total = _result?.total ?? 0;
    final noun = widget.part ? 'parts' : 'bikes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(
          widget.part ? 'Mening qismlarim' : 'Mening mototsikllarim',
          widget.part
              ? "Qism va aksessuarlaringizni boshqaring, ma'lumotlarni yangilang."
              : "E'lonlaringizni boshqaring, ma'lumotlarni yangilang va eskilarini arxivlang.",
          label: 'GARAJ',
          trailing: Row(children: [
            Text('$total $noun',
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Brand.ink)),
            const Spacer(),
            SiteGradientButton(
              label: widget.part ? "+ Qism qo'shish" : "+ E'lon qo'shish",
              colors: const [_violet, _purple],
              height: 38,
              fontSize: 13.5,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onTap: _addNew,
            ),
          ]),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD))),
          ),
          child: Row(children: [
            for (final t in _tabs)
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _status = t.$1;
                      _page = 1;
                      _result = null;
                    });
                    _load();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: _status == t.$1
                                ? Brand.ink
                                : Colors.transparent,
                            width: 2),
                      ),
                    ),
                    child: Text(t.$2,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _status == t.$1 ? Brand.ink : _muted)),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 16),
        if (_error != null)
          MessageView(icon: Icons.cloud_off, message: _error!, onRetry: _load)
        else if (_result == null)
          const SizedBox(height: 200, child: LoadingView())
        else if (_result!.items.isEmpty)
          _Empty(widget.part ? 'Qismlar topilmadi!' : 'Mototsikllar topilmadi!')
        else ...[
          for (final item in _result!.items) _listingCard(item),
          _Pager(
              page: _page,
              total: total,
              perPage: 5,
              onPage: (p) {
                setState(() => _page = p);
                _load();
              }),
        ],
      ],
    );
  }

  Widget _listingCard(Object item) {
    final bike = item is Motorbike ? item : null;
    final part = item is Part ? item : null;
    final id = bike?.id ?? part!.id;
    final card = bike != null
        ? ListingCard(
            heroTag: 'mine-${bike.id}',
            image: bike.images.isEmpty ? null : bike.images.first,
            title: bike.title,
            kicker: '${bike.brand} · ${bike.year}',
            badge: bike.type,
            rating: siteRating(bike.rank),
            price: formatPrice(bike.price, bike.currency),
            location: label(bike.location),
            address: bike.address,
            views: bike.views,
            likes: bike.likes,
            chips: [
              CardChip(Icons.speed, '${bike.mileage} milya'),
              CardChip(Icons.two_wheeler, label(bike.condition)),
              CardChip(Icons.engineering, '${bike.engineCc} cc'),
            ],
            action: 'Ko\'rish',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MotorbikeDetailScreen(initial: bike))),
          )
        : ListingCard(
            heroTag: 'mine-${part!.id}',
            image: part.images.isEmpty ? null : part.images.first,
            title: part.title,
            kicker: '${label(part.brand)} · ${label(part.type)}',
            badge: part.category,
            rating: siteRating(part.rank),
            price: formatPrice(part.price, part.currency),
            location: label(part.location),
            views: part.views,
            likes: part.likes,
            chips: [
              CardChip(Icons.category, label(part.type)),
              CardChip(Icons.build, label(part.condition)),
              CardChip(Icons.inventory_2, '${part.stock} dona'),
            ],
            action: 'Ko\'rish',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PartDetailScreen(initial: part))),
          );
    Widget action(
            String text, IconData icon, Color color, VoidCallback onTap) =>
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 17),
            label: Text(text, overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(children: [
        card,
        const SizedBox(height: 10),
        Row(children: [
          if (_status != 'HOLD') ...[
            action(
                'Tahrirlash', Icons.edit_outlined, _violet, () => _edit(item)),
            const SizedBox(width: 8),
          ],
          if (_status == 'ACTIVE') ...[
            action('Arxivlash', Icons.archive_outlined, Brand.ink,
                () => _setStatus(id, 'SOLD')),
            const SizedBox(width: 8),
          ],
          if (_status == 'SOLD') ...[
            action('Qayta joylash', Icons.unarchive_outlined, Brand.green,
                () => _setStatus(id, 'ACTIVE')),
            const SizedBox(width: 8),
          ],
          action("O'chirish", Icons.delete_outline, Colors.red,
              () => _setStatus(id, 'DELETE')),
        ]),
      ]),
    );
  }
}
