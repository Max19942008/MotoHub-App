import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/detail_layout.dart';

/// Shows the card data at once, then swaps in the full record from the API
/// (which also counts the view).
class MotorbikeDetailScreen extends StatefulWidget {
  const MotorbikeDetailScreen({super.key, required this.initial});
  final Motorbike initial;

  @override
  State<MotorbikeDetailScreen> createState() => _MotorbikeDetailScreenState();
}

class _MotorbikeDetailScreenState extends State<MotorbikeDetailScreen> {
  late Motorbike _bike = widget.initial;

  @override
  void initState() {
    super.initState();
    Repository.instance.motorbike(widget.initial.id).then((fresh) {
      if (mounted) setState(() => _bike = fresh);
    }).catchError((_) {/* keep showing the list data */});
  }

  @override
  Widget build(BuildContext context) {
    final b = _bike;
    return DetailLayout(
      heroTag: 'bike-${b.id}',
      images: b.images,
      price: formatPrice(b.price, b.currency),
      title: b.title,
      location: [label(b.location), if (b.address.isNotEmpty) b.address].join(', '),
      tags: [label(b.condition), if (b.barter) 'Barter mumkin', if (b.rent) 'Ijaraga beriladi'],
      description: b.description,
      seller: b.seller,
      views: b.views,
      likes: b.likes,
      createdAt: b.createdAt,
      specs: [
        Spec(Icons.local_offer_outlined, 'Brend', label(b.brand)),
        Spec(Icons.category_outlined, 'Turi', label(b.type)),
        Spec(Icons.calendar_today_outlined, 'Yili', '${b.year}'),
        Spec(Icons.speed, 'Dvigatel', '${b.engineCc} cc'),
        Spec(Icons.route_outlined, 'Yurgani', '${groupDigits(b.mileage)} km'),
        Spec(Icons.verified_outlined, 'Holati', label(b.condition)),
      ],
    );
  }
}
