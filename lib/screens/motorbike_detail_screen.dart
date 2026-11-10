import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/detail_layout.dart';

/// Bike page, laid out like the website's mobile bike detail.
class MotorbikeDetailScreen extends StatefulWidget {
  const MotorbikeDetailScreen({super.key, required this.initial});
  final Motorbike initial;

  @override
  State<MotorbikeDetailScreen> createState() => _MotorbikeDetailScreenState();
}

class _MotorbikeDetailScreenState extends State<MotorbikeDetailScreen> {
  late Motorbike _bike = widget.initial;
  late final Future<List<Widget>> _similar = _loadSimilar();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final fresh = await Repository.instance.motorbike(widget.initial.id);
      if (mounted) setState(() => _bike = fresh);
    } catch (_) {/* keep showing the list data */}
  }

  Future<List<Widget>> _loadSimilar() async {
    try {
      final list = await Repository.instance.similarMotorbikes(widget.initial.location);
      return [
        for (final b in list.where((b) => b.id != widget.initial.id))
          SimilarCard(
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
            onTap: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => MotorbikeDetailScreen(initial: b))),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _bike;
    final options = b.barter ? 'Ayirboshlash' : 'Ijara mavjud'; // same wording as the site
    return SiteDetailPage(
      id: b.id,
      crumb: 'Mototsikl',
      title: b.title,
      typeBadge: label(b.type),
      location: label(b.location),
      images: b.images,
      price: formatPrice(b.price, b.currency),
      pricePeriod: b.rent ? 'per month' : (b.barter ? 'for exchange' : 'total'),
      overlayPeriod: b.rent ? '/month' : (b.barter ? '/exchange' : ''),
      views: b.views,
      likes: b.likes,
      liked: b.liked,
      interested: b.interested,
      seller: b.seller,
      specs: [
        Spec(Icons.engineering, 'Dvigatel', '${b.engineCc} CC', specRed),
        Spec(Icons.speed, 'Yurgan masofa', '${b.mileage} km', specBlue),
        Spec(Icons.calendar_today, 'Yil', '${b.year}', specAmber),
        Spec(Icons.sell, 'Brend', b.brand, specGreen),
        Spec(Icons.two_wheeler, 'Mototsikl turi', label(b.type), specPurple),
      ],
      descTitle: 'Mototsikl tavsifi',
      description: b.description,
      detailsTitle: 'Mototsikl tafsilotlari',
      details: [
        DetailRow('Narx', formatPrice(b.price, b.currency)),
        DetailRow('Manzil', label(b.location)),
        DetailRow('Manzil', b.address),
        DetailRow('Dvigatel', '${b.engineCc} CC'),
        DetailRow('Yil', '${b.year}'),
        DetailRow('Mototsikl turi', label(b.type)),
        DetailRow('Holati', label(b.condition)),
        DetailRow("Qo'shimchalar", options),
      ],
      onLike: () => Repository.instance.likeMotorbike(b.id),
      onInterest: () => Repository.instance.notifyInterest(b.id),
      onRefresh: _refresh,
      commentGroup: 'PROPERTY',
      similarTitle: "O'xshash mototsikllar",
      similarSubtitle: 'Yaqin atrofdagi ajoyib mototsikllarni kashf eting',
      similar: _similar,
    );
  }
}
