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
      final list =
          await Repository.instance.similarMotorbikes(widget.initial.location);
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
                context,
                MaterialPageRoute(
                    builder: (_) => MotorbikeDetailScreen(initial: b))),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _bike;
    // Same wording as the site; nothing when the bike is only for sale.
    final options =
        b.barter ? 'Ayirboshlash' : (b.rent ? 'Ijara mavjud' : '');
    // City and street on one line; skip the city if the address already
    // starts with it.
    final city = label(b.location);
    final street = b.address.trim();
    final place = street.isEmpty
        ? city
        : street.toLowerCase().startsWith(city.toLowerCase())
            ? street
            : '$city, $street';
    return SiteDetailPage(
      id: b.id,
      crumb: 'Mototsikl',
      title: b.title,
      typeBadge: label(b.type),
      location: label(b.location),
      images: b.images,
      price: formatPrice(b.price, b.currency),
      pricePeriod: b.rent ? 'per month' : (b.barter ? 'for exchange' : 'total'),
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
      // Only what the cards above don't already show: price, engine, year
      // and type are on the price card and the spec cards.
      details: [
        DetailRow('Manzil', place),
        DetailRow('Holati', label(b.condition)),
        if (options.isNotEmpty) DetailRow("Qo'shimchalar", options),
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
