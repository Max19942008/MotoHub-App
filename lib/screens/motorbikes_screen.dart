import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/listing_card.dart';
import '../widgets/paged_grid.dart';
import '../widgets/site_filters.dart';
import 'motorbike_detail_screen.dart';

/// The website's bike list: header card (title, count, sort, filter buttons) + cards.
class MotorbikesScreen extends StatefulWidget {
  const MotorbikesScreen({super.key});

  @override
  State<MotorbikesScreen> createState() => _MotorbikesScreenState();
}

class _MotorbikesScreenState extends State<MotorbikesScreen>
    with AutomaticKeepAliveClientMixin {
  MotorbikeFilter _filter = MotorbikeFilter();
  int _version =
      0; // bumps on every filter change so the list restarts from page 1

  @override
  bool get wantKeepAlive => true;

  void _setFilter(MotorbikeFilter f) => setState(() {
        _filter = f;
        _version++;
      });

  Set<String> _toggle(Set<String> s, String v) =>
      s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  Widget _filters() {
    final f = _filter;
    final thisYear = DateTime.now().year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        SortButton(
            sort: f.sort, onChanged: (s) => _setFilter(f.copyWith(sort: s))),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFEAEAEA))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MultiFilterButton(
              label: 'Brend',
              options: motorbikeBrands,
              selected: f.brands,
              onToggle: (v) =>
                  _setFilter(f.copyWith(brands: _toggle(f.brands, v))),
            ),
            MultiFilterButton(
              label: 'Tur',
              options: motorbikeTypes,
              selected: f.types,
              onToggle: (v) =>
                  _setFilter(f.copyWith(types: _toggle(f.types, v))),
            ),
            MultiFilterButton(
              label: 'Holati',
              options: motorbikeConditions,
              selected: f.conditions,
              onToggle: (v) =>
                  _setFilter(f.copyWith(conditions: _toggle(f.conditions, v))),
            ),
            MultiFilterButton(
              label: 'Manzil',
              options: locations,
              selected: f.locations,
              onToggle: (v) =>
                  _setFilter(f.copyWith(locations: _toggle(f.locations, v))),
            ),
            RangeFilterButton(
              text: '${f.minYear ?? 2000} - ${f.maxYear ?? thisYear}',
              fromTitle: 'Yildan',
              toTitle: 'Yilgacha',
              fromOptions: yearOptions(),
              toOptions: yearOptions(),
              format: (v) => '$v',
              from: f.minYear,
              to: f.maxYear,
              onChanged: (a, b) =>
                  _setFilter(f.copyWith(minYear: () => a, maxYear: () => b)),
            ),
            RangeFilterButton(
              text: '${usd(f.minPrice ?? 0)} - ${usd(f.maxPrice ?? 2000000)}',
              fromTitle: 'Minimal narx (\$)',
              toTitle: 'Maksimal narx (\$)',
              fromOptions: minPriceOptions,
              toOptions: maxPriceOptions,
              format: usd,
              from: f.minPrice,
              to: f.maxPrice,
              onChanged: (a, b) =>
                  _setFilter(f.copyWith(minPrice: () => a, maxPrice: () => b)),
            ),
            ResetFilterButton(onPressed: () => _setFilter(MotorbikeFilter())),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedGrid<Motorbike>(
      key: ValueKey(_version),
      title: 'Mototsikllar',
      header: _filters(),
      fetch: (page) => Repository.instance.motorbikes(_filter, page),
      emptyMessage:
          "Bunday mototsikl topilmadi.\nFiltrlarni o'zgartirib ko'ring.",
      itemBuilder: (context, bike) => ListingCard(
        heroTag: 'bike-${bike.id}',
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MotorbikeDetailScreen(initial: bike)),
        ),
      ),
    );
  }
}
