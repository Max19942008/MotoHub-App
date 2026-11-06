import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/detail_layout.dart';

class PartDetailScreen extends StatefulWidget {
  const PartDetailScreen({super.key, required this.initial});
  final Part initial;

  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  late Part _part = widget.initial;

  @override
  void initState() {
    super.initState();
    Repository.instance.part(widget.initial.id).then((fresh) {
      if (mounted) setState(() => _part = fresh);
    }).catchError((_) {/* keep showing the list data */});
  }

  @override
  Widget build(BuildContext context) {
    final p = _part;
    return DetailLayout(
      heroTag: 'part-${p.id}',
      images: p.images,
      price: formatPrice(p.price, p.currency),
      title: p.title,
      location: label(p.location),
      tags: [label(p.condition), label(p.category), if (p.barter) 'Barter mumkin'],
      description: p.description,
      seller: p.seller,
      views: p.views,
      likes: p.likes,
      createdAt: p.createdAt,
      specs: [
        Spec(Icons.category_outlined, 'Turi', label(p.type)),
        Spec(Icons.local_offer_outlined, 'Brend', label(p.brand)),
        Spec(Icons.verified_outlined, 'Holati', label(p.condition)),
        Spec(Icons.inventory_2_outlined, 'Omborda', '${p.stock} dona'),
        if (p.compatibleBrands.isNotEmpty)
          Spec(Icons.two_wheeler, 'Mos keladi', p.compatibleBrands.map(label).join(', ')),
      ],
    );
  }
}
