import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/detail_layout.dart';

/// Part / accessory page, same layout as the bike page (the site has no reviews here).
class PartDetailScreen extends StatefulWidget {
  const PartDetailScreen({super.key, required this.initial});
  final Part initial;

  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  late Part _part = widget.initial;
  late final Future<List<Widget>> _similar = _loadSimilar();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await Repository.instance.part(widget.initial.id);
      if (mounted) setState(() => _part = fresh);
    } catch (_) {/* keep showing the list data */}
  }

  Future<List<Widget>> _loadSimilar() async {
    try {
      final list = await Repository.instance.similarParts(widget.initial.category);
      return [
        for (final p in list.where((p) => p.id != widget.initial.id))
          SimilarCard(
            image: p.images.isEmpty ? null : p.images.first,
            price: formatPrice(p.price, p.currency),
            title: p.title,
            location: p.location,
            pills: [
              (Icons.category, label(p.type)),
              (Icons.build, p.condition),
              (Icons.sell, p.brand),
            ],
            views: p.views,
            likes: p.likes,
            barter: p.barter,
            onTap: () =>
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PartDetailScreen(initial: p))),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _part;
    final category = p.category == 'ACCESSORY' ? 'Aksessuar' : 'Ehtiyot qism';
    return SiteDetailPage(
      id: p.id,
      crumb: 'Ehtiyot qismlar va aksessuarlar',
      title: p.title,
      typeBadge: category,
      location: label(p.location),
      images: p.images,
      price: formatPrice(p.price, p.currency),
      pricePeriod: p.barter ? 'for exchange' : 'total',
      overlayPeriod: p.barter ? '/exchange' : '',
      views: p.views,
      likes: p.likes,
      liked: p.liked,
      interested: p.interested,
      seller: p.seller,
      specs: [
        Spec(Icons.category, 'Turkum', category, specRed),
        Spec(Icons.build, 'Tur', label(p.type), specBlue),
        Spec(Icons.sell, 'Brend', p.brand, specAmber),
        Spec(Icons.verified, 'Holati', label(p.condition), specGreen),
        Spec(Icons.inventory_2, 'Omborda', '${p.stock} dona', specPurple),
      ],
      descTitle: 'Tavsif',
      description: p.description,
      detailsTitle: 'Tafsilotlar',
      details: [
        DetailRow('Narx', formatPrice(p.price, p.currency)),
        DetailRow('Manzil', label(p.location)),
        DetailRow('Turkum', category),
        DetailRow('Tur', label(p.type)),
        DetailRow('Brend', p.brand),
        DetailRow('Holati', label(p.condition)),
        DetailRow('Omborda', '${p.stock} dona'),
      ],
      onLike: () => Repository.instance.likePart(p.id),
      onInterest: () => Repository.instance.notifyPartInterest(p.id),
      onRefresh: _refresh,
      similarTitle: "O'xshash qismlar",
      similarSubtitle: "Ko'proq qism va aksessuarlarni kashf eting",
      similar: _similar,
    );
  }
}
