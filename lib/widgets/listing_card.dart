import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// One spec pill on a card (mileage, condition, engine…).
class CardChip {
  const CardChip(this.icon, this.text);
  final IconData icon;
  final String text;
}

/// Listing card in the website's style: big photo with view/like pills,
/// title + "BRAND · YEAR", a green location row, spec pills, then the price
/// and a green call-to-action.
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
    this.chips = const [],
    this.views,
    this.likes,
    this.action = 'Batafsil',
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
  final List<CardChip> chips;
  final int? views;
  final int? likes;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
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
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _PhotoPill(icon: Icons.visibility_outlined, text: '$views'),
                    ),
                  if (likes != null)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _PhotoPill(icon: Icons.favorite, text: '$likes'),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Brand.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kicker.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Brand.muted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(color: Brand.greenSoft, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.place, size: 17, color: Brand.green),
                        const SizedBox(width: 8),
                        Text(
                          location.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: Brand.ink),
                        ),
                        if (address != null && address!.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              address!,
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: Brand.muted),
                            ),
                          ),
                        ] else
                          const Spacer(),
                      ],
                    ),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (var i = 0; i < chips.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          Expanded(child: _SpecPill(chips[i])),
                        ],
                      ],
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: Brand.line),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DAN',
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(color: Brand.muted, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
                            Text(
                              price,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800, color: Brand.green, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: Brand.greenGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Brand.green.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          child: Text(action,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                    ],
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
  const _PhotoPill({this.icon, required this.text, this.light = false});
  final IconData? icon;
  final String text;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final fg = light ? Brand.ink : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: light ? Colors.white : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(light ? 8 : 20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 5)],
          Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

class _SpecPill extends StatelessWidget {
  const _SpecPill(this.chip);
  final CardChip chip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(color: Brand.greenSoft, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(chip.icon, size: 15, color: Brand.green),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              chip.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Brand.ink),
            ),
          ),
        ],
      ),
    );
  }
}
