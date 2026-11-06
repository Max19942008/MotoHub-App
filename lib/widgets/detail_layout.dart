import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/listing.dart';
import '../utils/labels.dart';
import 'common.dart';

class Spec {
  const Spec(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;
}

/// Shared detail page: photo gallery, price/title, spec grid, description, seller.
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
    final scheme = theme.colorScheme;
    final desc = plainText(description);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: MediaQuery.sizeOf(context).width * 0.8,
            flexibleSpace: FlexibleSpaceBar(
              background: _Gallery(heroTag: heroTag, images: images),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(spacing: 6, children: [
                        for (var i = 0; i < tags.length; i++) Tag(tags[i], highlight: i == 0),
                      ]),
                    ),
                  Text(
                    price,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 16, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location, style: TextStyle(color: scheme.onSurfaceVariant))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  DefaultTextStyle.merge(
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    child: Wrap(spacing: 16, children: [
                      if (createdAt != null) Text(timeAgo(createdAt)),
                      if (views != null) Text('👁 $views'),
                      if (likes != null) Text('♥ $likes'),
                    ]),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 64,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: specs.length,
              itemBuilder: (context, i) => _SpecTile(specs[i]),
            ),
          ),
          if (desc.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tavsif', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    SelectableText(desc, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ],
                ),
              ),
            ),
          if (seller != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: _SellerCard(seller!),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: seller?.phone?.isNotEmpty == true
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.call),
                  label: const Text('Sotuvchiga qo\'ng\'iroq qilish'),
                  onPressed: () => _call(context, seller!.phone!),
                ),
              ),
            )
          : null,
    );
  }
}

Future<void> _call(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));
  if (!await launchUrl(uri) && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Telefon: $phone')));
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.heroTag, required this.images});
  final String heroTag;
  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images.isEmpty ? <String>[''] : widget.images;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final image = NetImage(images[i], iconSize: 72);
            return i == 0 ? Hero(tag: widget.heroTag, child: image) : image;
          },
        ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == _index ? 1 : 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SpecTile extends StatelessWidget {
  const _SpecTile(this.spec);
  final Spec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(spec.icon, size: 22, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spec.label, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                Text(
                  spec.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
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
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: ClipOval(
          child: SizedBox.square(dimension: 44, child: NetImage(seller.image, iconSize: 22)),
        ),
        title: Text(seller.nick, style: theme.textTheme.titleMedium),
        subtitle: Text(seller.type == 'AGENT' ? 'Diler' : 'Sotuvchi'),
        trailing: seller.phone?.isNotEmpty == true
            ? IconButton.filledTonal(
                icon: const Icon(Icons.call),
                onPressed: () => _call(context, seller.phone!),
              )
            : null,
      ),
    );
  }
}
