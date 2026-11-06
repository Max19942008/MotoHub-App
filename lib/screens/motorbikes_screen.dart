import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/listing_card.dart';
import '../widgets/paged_grid.dart';
import '../widgets/search_bar_row.dart';
import 'motorbike_detail_screen.dart';

class MotorbikesScreen extends StatefulWidget {
  const MotorbikesScreen({super.key});

  @override
  State<MotorbikesScreen> createState() => _MotorbikesScreenState();
}

class _MotorbikesScreenState extends State<MotorbikesScreen> with AutomaticKeepAliveClientMixin {
  MotorbikeFilter _filter = MotorbikeFilter();
  int _version = 0; // bumps on every filter change so the grid restarts from page 1

  @override
  bool get wantKeepAlive => true;

  void _setFilter(MotorbikeFilter f) => setState(() {
        _filter = f;
        _version++;
      });

  Future<void> _openFilters() async {
    final result = await showFilterSheet(
      context,
      sort: _filter.sort,
      withPrice: true,
      minPrice: _filter.minPrice,
      maxPrice: _filter.maxPrice,
      sections: [
        FilterSection('Brend', motorbikeBrands, _filter.brands),
        FilterSection('Turi', motorbikeTypes, _filter.types),
        FilterSection('Holati', motorbikeConditions, _filter.conditions),
        FilterSection('Hudud', locations, _filter.locations),
      ],
    );
    if (result == null) return;
    _setFilter(_filter.copyWith(
      brands: result.sections[0],
      types: result.sections[1],
      conditions: result.sections[2],
      locations: result.sections[3],
      sort: result.sort,
      minPrice: () => result.minPrice,
      maxPrice: () => result.maxPrice,
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        SearchBarRow(
          hint: 'Mototsikl qidirish',
          initialText: _filter.text,
          activeFilters: _filter.activeCount,
          onSearch: (text) {
            if (text.trim() != _filter.text.trim()) _setFilter(_filter.copyWith(text: text));
          },
          onFilter: _openFilters,
        ),
        Expanded(
          child: PagedGrid<Motorbike>(
            key: ValueKey(_version),
            fetch: (page) => Repository.instance.motorbikes(_filter, page),
            emptyMessage: 'Bunday mototsikl topilmadi.\nFiltrlarni o\'zgartirib ko\'ring.',
            itemBuilder: (context, bike) => ListingCard(
              heroTag: 'bike-${bike.id}',
              image: bike.images.isEmpty ? null : bike.images.first,
              title: bike.title,
              price: formatPrice(bike.price, bike.currency),
              subtitle: '${label(bike.brand)} · ${bike.year} · ${bike.engineCc}cc',
              location: label(bike.location),
              tags: [
                label(bike.condition),
                if (bike.barter) 'Barter',
                if (bike.rent) 'Ijara',
              ],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MotorbikeDetailScreen(initial: bike)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
