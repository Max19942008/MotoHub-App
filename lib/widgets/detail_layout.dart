import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import 'common.dart';

class Spec {
  const Spec(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

/// Shared detail page in the website's layout: title, photo with price tag and
/// thumbnails, price card, call button, seller card, colored spec grid, description.
class DetailLayout extends StatelessWidget {
  const DetailLayout({
    super.key,
    required this.heroTag,
    required this.images,
    required this.price,
    required this.title,
    required this.location,
    required this.specs,
    this.tags = const [],
    this.description,
    this.seller,
    this.views,
    this.likes,
    this.createdAt,
  });

  final String heroTag;
  final List<String> images;
  final String price;
  final String title;
  final String location;
  final List<Spec> specs;
  final List<String> tags;
  final String? description;
  final Seller? seller;
  final int? views;
  final int? likes;
  final DateTime? createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final desc = plainText(description);
    final phone = seller?.phone?.isNotEmpty == true ? seller!.phone! : null;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 60, title: const BrandLogo(height: 34)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.place, size: 17, color: Brand.green),
              const SizedBox(width: 4),
              Expanded(child: Text(location, style: theme.textTheme.bodyMedium?.copyWith(color: Brand.muted))),
            ],
          ),
          if (tags.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final t in tags.skip(1)) Tag(t)]),
          ],
          const SizedBox(height: 14),
          _Gallery(heroTag: heroTag, images: images, tags: tags, views: views, likes: likes, price: price),
          const SizedBox(height: 16),
          _Box(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NARX',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: Brand.muted, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                Text(price,
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink)),
                if (createdAt != null)
                  Text(timeAgo(createdAt), style: theme.textTheme.bodySmall?.copyWith(color: Brand.muted)),
              ],
            ),
          ),
          if (phone != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              icon: const Icon(Icons.call),
              label: const Text("Sotuvchiga qo'ng'iroq qilish"),
              onPressed: () => _call(context, phone),
            ),
          ],
          if (seller != null) ...[
            const SizedBox(height: 16),
            _SellerCard(seller!),
          ],
          const SizedBox(height: 16),
          _Box(
            padding: const EdgeInsets.all(14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 128,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: specs.length,
              itemBuilder: (context, i) => _SpecTile(specs[i], _specColors[i % _specColors.length]),
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Box(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tavsif',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink)),
                  Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 14),
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(gradient: Brand.greenGradient, borderRadius: BorderRadius.circular(2)),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Brand.page,
                      border: Border(left: BorderSide(color: Brand.green, width: 4)),
                    ),
                    child: SelectableText(desc, style: theme.textTheme.bodyLarge?.copyWith(height: 1.55)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Icon tile colors from the website's spec cards.
const _specColors = [
  Color(0xFFF0566A),
  Color(0xFF2F6FED),
  Color(0xFFE0A100),
  Color(0xFF3DAA4F),
  Color(0xFF9B3DE8),
  Color(0xFF0EA5A4),
];

Future<void> _call(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
  if (!await launchUrl(uri) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Telefon: $phone')));
  }
}

/// White rounded box with the site's light border.
class _Box extends StatelessWidget {
  const _Box({required this.child, required this.padding});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Brand.line),
        ),
        child: child,
      );
}

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.heroTag,
    required this.images,
    required this.tags,
    required this.price,
    this.views,
    this.likes,
  });
  final String heroTag;
  final List<String> images;
  final List<String> tags;
  final String price;
  final int? views;
  final int? likes;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Widget _pill(Widget child, {bool light = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: light ? Colors.white : Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: light ? Brand.ink : Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5),
          child: IconTheme.merge(data: IconThemeData(size: 15, color: light ? Brand.ink : Colors.white), child: child),
        ),
      );

  Widget _counter(IconData icon, int value) => _pill(Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon),
        const SizedBox(width: 5),
        Text('$value'),
      ]));

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? <String>[''] : widget.images;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _pages,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final image = NetImage(images[i], iconSize: 72);
                    return i == 0 ? Hero(tag: widget.heroTag, child: image) : image;
                  },
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (widget.tags.isNotEmpty) _pill(Text(widget.tags.first.toUpperCase()), light: true),
                      const Spacer(),
                      if (widget.views != null) _counter(Icons.visibility_outlined, widget.views!),
                      const SizedBox(width: 6),
                      if (widget.likes != null) _counter(Icons.favorite_border, widget.likes!),
                    ],
                  ),
                ),
                Positioned(
                  left: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NARX',
                            style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                        Text(widget.price,
                            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () =>
                    _pages.animateToPage(i, duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Container(
                  width: 86,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: i == _index ? Brand.ink : Colors.transparent, width: 2),
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: NetImage(images[i], iconSize: 20)),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile(this.spec, this.color);
  final Spec spec;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.page,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(spec.icon, color: Colors.white, size: 22),
          ),
          const Spacer(),
          Text(spec.label.toUpperCase(),
              style:
                  const TextStyle(fontSize: 11, color: Brand.muted, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(
            spec.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Brand.ink),
          ),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard(this.seller);
  final Seller seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = seller.phone?.isNotEmpty == true ? seller.phone! : null;
    return _Box(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ClipOval(child: SizedBox.square(dimension: 76, child: NetImage(seller.image, iconSize: 32))),
          const SizedBox(height: 10),
          Text(seller.nick, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(seller.type == 'AGENT' ? 'Diler' : 'Sotuvchi',
              style: theme.textTheme.bodyMedium?.copyWith(color: Brand.muted)),
          if (phone != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              icon: const Icon(Icons.call, size: 18),
              label: Text(phone),
              onPressed: () => _call(context, phone),
            ),
          ],
        ],
      ),
    );
  }
}
