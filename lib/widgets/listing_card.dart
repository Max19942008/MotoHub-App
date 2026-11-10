import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// One spec pill on a card (mileage, condition, engine…).
class CardChip {
  const CardChip(this.icon, this.text);
  final IconData icon;
  final String text;
}

/// Accent of a card: the website draws "trend" cards green and
/// "popular / top" cards indigo.
class CardAccent {
  const CardAccent(this.main, this.dark, this.soft, this.border);
  final Color main;
  final Color dark;
  final Color soft;
  final Color border;

  static const green = CardAccent(Brand.green, Brand.greenDark, Color(0xFFEFF8F1), Color(0xFFCDEBD5));
  static const indigo = CardAccent(Brand.indigo, Brand.indigoDark, Color(0xFFF1F1FD), Color(0xFFDADAF8));
}

/// The website's listing card: photo with view/like pills, title + "BRAND · YEAR"
/// with a ★ rating pill, location row, three spec pills, then a centered
/// "DAN / price" and the call-to-action button.
class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.heroTag,
    required this.image,
    required this.title,
    required this.kicker,
    required this.price,
    required this.location,
    this.address,
    this.badge,
    this.rating,
    this.chips = const [],
    this.views,
    this.likes,
    this.action = 'Sotib Olish',
    this.accent = CardAccent.green,
    required this.onTap,
  });

  final String heroTag;
  final String? image;
  final String title;

  /// Small uppercase line under the title, e.g. "YAMAHA · 2024".
  final String kicker;
  final String price;
  final String location;
  final String? address;

  /// Top-left label on the photo, e.g. "SPORT".
  final String? badge;
  final num? rating;
  final List<CardChip> chips;
  final int? views;
  final int? likes;
  final String action;
  final CardAccent accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDFDFD),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFFEDEDED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: heroTag, child: NetImage(image)),
                  if (badge != null && badge!.isNotEmpty)
                    Positioned(left: 12, top: 12, child: _PhotoPill(text: badge!.toUpperCase(), light: true)),
                  if (views != null)
                    Positioned(left: 12, bottom: 12, child: _PhotoPill(icon: Icons.visibility, text: '$views')),
                  if (likes != null)
                    Positioned(right: 12, bottom: 12, child: _PhotoPill(icon: Icons.favorite, text: '$likes', soft: true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Brand.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kicker.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5, color: Brand.muted, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                            ),
                          ],
                        ),
                      ),
                      if (rating != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: accent.soft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.border),
                            boxShadow: [BoxShadow(color: accent.main.withValues(alpha: 0.12), blurRadius: 10)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, size: 17, color: Color(0xFFFFC107)),
                              const SizedBox(width: 5),
                              Text(rating!.toStringAsFixed(rating! >= 10 ? 2 : 1),
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: accent.main)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(color: accent.soft, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Icon(Icons.place, size: 17, color: accent.main),
                        const SizedBox(width: 10),
                        Text(location.toUpperCase(),
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            address ?? '',
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Brand.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < chips.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(child: _SpecPill(chips[i], accent)),
                        ],
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.only(top: 18, bottom: 22),
                    child: Divider(height: 1, color: Color(0xFFEAEAEA)),
                  ),
                  const Text('DAN',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  Text(price, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: accent.main, height: 1.2)),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [accent.main, accent.dark]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: accent.main.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 7)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 11),
                      child: Text(action,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPill extends StatelessWidget {
  const _PhotoPill({this.icon, required this.text, this.light = false, this.soft = false});
  final IconData? icon;
  final String text;
  final bool light;

  /// The like counter on the site is a lighter, translucent pill.
  final bool soft;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Brand.ink : Colors.white;
    final bg = light
        ? Colors.white
        : soft
            ? Colors.white.withValues(alpha: 0.35)
            : const Color(0xFF181A20).withValues(alpha: 0.75);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: light ? 12 : 11, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(light ? 8 : 14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
          Text(text, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  const _SpecPill(this.chip, this.accent);
  final CardChip chip;
  final CardAccent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: accent.soft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(chip.icon, size: 14, color: accent.main),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              chip.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Brand.ink),
            ),
          ),
        ],
      ),
    );
  }
}
