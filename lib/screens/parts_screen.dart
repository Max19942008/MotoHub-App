import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/listing_card.dart';
import '../widgets/paged_grid.dart';
import '../widgets/search_bar_row.dart';
import 'part_detail_screen.dart';

/// Spare parts and accessories, switched with a segmented control.
class PartsScreen extends StatefulWidget {
  const PartsScreen({super.key});

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> with AutomaticKeepAliveClientMixin {
  PartFilter _filter = PartFilter(category: 'SPARE_PART');
  int _version = 0;

  @override
  bool get wantKeepAlive => true;

  bool get _isAccessory => _filter.category == 'ACCESSORY';

  void _setFilter(PartFilter f) => setState(() {
        _filter = f;
        _version++;
      });

  Future<void> _openFilters() async {
    final result = await showFilterSheet(
      context,
      sort: _filter.sort,
      sections: [
        FilterSection('Turi', _isAccessory ? accessoryTypes : sparePartTypes, _filter.types),
        FilterSection('Brend / mos keladi', partBrands, _filter.brands),
        FilterSection('Holati', partConditions, _filter.conditions),
        FilterSection('Hudud', locations, _filter.locations),
      ],
    );
    if (result == null) return;
    _setFilter(_filter.copyWith(
      types: result.sections[0],
      brands: result.sections[1],
      conditions: result.sections[2],
      locations: result.sections[3],
      sort: result.sort,
    ));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'SPARE_PART', label: Text('Ehtiyot qismlar'), icon: Icon(Icons.build_outlined)),
                ButtonSegment(value: 'ACCESSORY', label: Text('Aksessuarlar'), icon: Icon(Icons.sports_motorsports_outlined)),
              ],
              selected: {_filter.category},
              onSelectionChanged: (s) {
                // Types differ per category, so start the filter fresh.
                if (s.first != _filter.category) _setFilter(PartFilter(category: s.first, text: _filter.text));
              },
            ),
          ),
        ),
        SearchBarRow(
          key: ValueKey(_filter.category),
          hint: _isAccessory ? 'Aksessuar qidirish' : 'Ehtiyot qism qidirish',
          initialText: _filter.text,
          activeFilters: _filter.activeCount,
          onSearch: (text) {
            if (text.trim() != _filter.text.trim()) _setFilter(_filter.copyWith(text: text));
          },
          onFilter: _openFilters,
        ),
        Expanded(
          child: PagedGrid<Part>(
            key: ValueKey(_version),
            fetch: (page) => Repository.instance.parts(_filter, page),
            emptyMessage: 'Hech narsa topilmadi.\nFiltrlarni o\'zgartirib ko\'ring.',
            itemBuilder: (context, part) => ListingCard(
              heroTag: 'part-${part.id}',
              image: part.images.isEmpty ? null : part.images.first,
              title: part.title,
              price: formatPrice(part.price, part.currency),
              subtitle: '${label(part.type)} · ${label(part.brand)}',
              location: label(part.location),
              tags: [label(part.condition), if (part.barter) 'Barter'],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartDetailScreen(initial: part)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
