import 'package:flutter/material.dart';

import '../api/repository.dart';
import '../theme.dart';
import '../models/listing.dart';
import '../utils/labels.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/listing_card.dart';
import '../widgets/paged_grid.dart';
import '../widgets/search_bar_row.dart';
import 'part_detail_screen.dart';

/// Spare parts or accessories ([category] SPARE_PART | ACCESSORY), with the
/// website's pill tabs to switch between them.
class PartsScreen extends StatefulWidget {
  const PartsScreen({super.key, this.category = 'SPARE_PART', this.onCategoryChanged});

  final String category;
  final ValueChanged<String>? onCategoryChanged;

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen> with AutomaticKeepAliveClientMixin {
  late PartFilter _filter = PartFilter(category: widget.category);
  int _version = 0;

  @override
  bool get wantKeepAlive => true;

  bool get _isAccessory => _filter.category == 'ACCESSORY';

  @override
  void didUpdateWidget(PartsScreen old) {
    super.didUpdateWidget(old);
    // The drawer picked the other category.
    if (widget.category != old.category && widget.category != _filter.category) {
      _filter = PartFilter(category: widget.category, text: _filter.text);
      _version++;
    }
  }

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

  void _switch(String category) {
    if (category == _filter.category) return;
    // Types differ per category, so start the filter fresh.
    _setFilter(PartFilter(category: category, text: _filter.text));
    widget.onCategoryChanged?.call(category);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedGrid<Part>(
      key: ValueKey(_version),
      title: _isAccessory ? 'Aksessuarlar' : 'Ehtiyot qismlar',
      header: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                _CategoryPill(label: 'Ehtiyot qismlar', active: !_isAccessory, onTap: () => _switch('SPARE_PART')),
                const SizedBox(width: 8),
                _CategoryPill(label: 'Aksessuarlar', active: _isAccessory, onTap: () => _switch('ACCESSORY')),
              ],
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
        ],
      ),
      fetch: (page) => Repository.instance.parts(_filter, page),
      emptyMessage: "Hech narsa topilmadi.\nFiltrlarni o'zgartirib ko'ring.",
      itemBuilder: (context, part) => ListingCard(
        heroTag: 'part-${part.id}',
        image: part.images.isEmpty ? null : part.images.first,
        title: part.title,
        kicker: '${label(part.brand)} · ${label(part.type)}',
        badge: _isAccessory ? 'Aksessuar' : 'Ehtiyot qism',
        price: formatPrice(part.price, part.currency),
        location: label(part.location),
        views: part.views,
        likes: part.likes,
        chips: [
          CardChip(Icons.two_wheeler, label(part.condition)),
          CardChip(Icons.inventory_2_outlined, '${part.stock} dona'),
          if (part.barter) const CardChip(Icons.swap_horiz, 'Barter'),
        ],
        action: 'Sotib olish',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartDetailScreen(initial: part)),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? Brand.green : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: active ? Brand.green : Brand.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: active ? Colors.white : Brand.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
