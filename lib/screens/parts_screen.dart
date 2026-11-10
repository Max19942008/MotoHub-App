import 'package:flutter/material.dart' hide Text;

import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import '../widgets/listing_card.dart';
import '../widgets/paged_grid.dart';
import '../widgets/site_filters.dart';
import 'part_detail_screen.dart';
import '../i18n/text.dart';

/// The website's parts page: "Hammasi / Ehtiyot qismlar / Aksessuarlar" pills,
/// header card with sort + filter buttons, then cards.
/// [category] is SPARE_PART, ACCESSORY or ALL.
class PartsScreen extends StatefulWidget {
  const PartsScreen(
      {super.key, this.category = 'SPARE_PART', this.onCategoryChanged});

  final String category;
  final ValueChanged<String>? onCategoryChanged;

  @override
  State<PartsScreen> createState() => _PartsScreenState();
}

class _PartsScreenState extends State<PartsScreen>
    with AutomaticKeepAliveClientMixin {
  late PartFilter _filter = PartFilter(category: widget.category);
  int _version = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(PartsScreen old) {
    super.didUpdateWidget(old);
    // The drawer picked another category.
    if (widget.category != old.category &&
        widget.category != _filter.category) {
      _filter = PartFilter(category: widget.category);
      _version++;
    }
  }

  void _setFilter(PartFilter f) => setState(() {
        _filter = f;
        _version++;
      });

  void _switch(String category) {
    if (category == _filter.category) return;
    // Types differ per category, so start the filter fresh (the site does the same).
    _setFilter(PartFilter(category: category));
    widget.onCategoryChanged?.call(category);
  }

  Set<String> _toggle(Set<String> s, String v) =>
      s.contains(v) ? ({...s}..remove(v)) : {...s, v};

  String get _title => switch (_filter.category) {
        'SPARE_PART' => 'Ehtiyot qismlar',
        'ACCESSORY' => 'Aksessuarlar',
        _ => 'Ehtiyot qismlar va aksessuarlar',
      };

  List<String> get _types => switch (_filter.category) {
        'SPARE_PART' => sparePartTypes,
        'ACCESSORY' => accessoryTypes,
        _ => [
            ...sparePartTypes,
            ...accessoryTypes.where((t) => !sparePartTypes.contains(t))
          ],
      };

  Widget _tabs() => Padding(
        padding: const EdgeInsets.fromLTRB(10, 22, 10, 0),
        child: Wrap(
          spacing: 12,
          runSpacing: 2,
          children: [
            _TabPill(
                label: 'Hammasi',
                active: _filter.category == 'ALL',
                onTap: () => _switch('ALL')),
            _TabPill(
                label: 'Ehtiyot qismlar',
                active: _filter.category == 'SPARE_PART',
                onTap: () => _switch('SPARE_PART')),
            _TabPill(
                label: 'Aksessuarlar',
                active: _filter.category == 'ACCESSORY',
                onTap: () => _switch('ACCESSORY')),
          ],
        ),
      );

  Widget _filters() {
    final f = _filter;
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
              label: 'Tur',
              options: _types,
              selected: f.types,
              onToggle: (v) =>
                  _setFilter(f.copyWith(types: _toggle(f.types, v))),
            ),
            MultiFilterButton(
              label: 'Brend',
              options: partBrands,
              selected: f.brands,
              onToggle: (v) =>
                  _setFilter(f.copyWith(brands: _toggle(f.brands, v))),
            ),
            MultiFilterButton(
              label: 'Holati',
              options: partConditions,
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
              text: f.minPrice == null && f.maxPrice == null
                  ? 'Narx'
                  : '${usd(f.minPrice ?? 0)} - ${usd(f.maxPrice ?? 2000000)}',
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
            ResetFilterButton(
                onPressed: () => _setFilter(PartFilter(category: f.category))),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PagedGrid<Part>(
      key: ValueKey(_version),
      top: _tabs(),
      title: _title,
      header: _filters(),
      fetch: (page) => Repository.instance.parts(_filter, page),
      emptyMessage: "Hech narsa topilmadi.\nFiltrlarni o'zgartirib ko'ring.",
      itemBuilder: (context, part) => ListingCard(
        heroTag: 'part-${part.id}',
        image: part.images.isEmpty ? null : part.images.first,
        title: part.title,
        kicker: '${part.brand} · ${label(part.type)}',
        badge: part.category == 'ACCESSORY' ? 'Aksessuar' : 'Ehtiyot qism',
        rating: siteRating(part.rank),
        price: formatPrice(part.price, part.currency),
        priceLabel: 'NARX',
        location: label(part.location),
        address: part.category == 'ACCESSORY' ? 'Aksessuar' : 'Ehtiyot qism',
        views: part.views,
        likes: part.likes,
        chips: [
          CardChip(Icons.category, label(part.type)),
          CardChip(Icons.build, part.condition),
          CardChip(Icons.inventory_2, '${part.stock} dona'),
        ],
        action: 'Sotib Olish',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PartDetailScreen(initial: part)),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: active ? Brand.green : Colors.white,
        shape: StadiumBorder(
            side: BorderSide(
                color: active ? Brand.green : const Color(0xFFE5E7EB))),
        elevation: active ? 6 : 0,
        shadowColor: Brand.green.withValues(alpha: 0.5),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: active ? Colors.white : Brand.ink),
            ),
          ),
        ),
      ),
    );
  }
}
