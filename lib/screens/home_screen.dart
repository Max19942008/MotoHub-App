import 'package:flutter/material.dart' hide Text;

import '../api/repository.dart';
import '../models/listing.dart';
import '../theme.dart';
import '../utils/labels.dart';
import '../widgets/listing_card.dart';
import '../widgets/site_sections.dart';
import 'motorbike_detail_screen.dart';
import 'part_detail_screen.dart';
import '../i18n/text.dart';

/// The website's mobile home page, section for section.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  final _repo = Repository.instance;
  late Future<List<Motorbike>> _trend, _popular, _top;
  late Future<List<Part>> _topParts, _topAccessories;
  late Future<List<Agent>> _agents;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _trend = _repo.topMotorbikes('propertyLikes', 8);
    _popular = _repo.topMotorbikes('propertyViews', 7);
    _top = _repo.topMotorbikes('propertyRank', 8);
    _topParts = _repo.topParts('SPARE_PART', 8);
    _topAccessories = _repo.topParts('ACCESSORY', 8);
    _agents = _repo.topAgents(10);
  }

  Future<void> _refresh() async {
    setState(_load);
    await Future.wait([_trend, _popular, _top]);
  }

  static const _greenTitle = [Brand.green, Brand.greenDark, Color(0xFFFF6B6B)];
  static const _indigoTitle = [Brand.indigo, Color(0xFF8B5CF6)];
  static const _grey = Color(0xFFF5F5F5);

  /// Card height in a carousel: photo (16:10) + body.
  double _cardHeight(BuildContext context) =>
      (MediaQuery.sizeOf(context).width - 24) * 10 / 16 + 360;

  Widget _bikeCard(Motorbike b, CardAccent accent, String action) =>
      ListingCard(
        heroTag: 'home-${accent.main.toARGB32()}-${b.id}',
        image: b.images.isEmpty ? null : b.images.first,
        title: b.title,
        kicker: '${b.brand} · ${b.year}',
        rating: siteRating(b.rank, home: true),
        price: formatPrice(b.price, b.currency),
        location: b.location,
        address: b.address,
        views: b.views,
        likes: b.likes,
        accent: accent,
        action: action,
        chips: [
          CardChip(Icons.speed, '${b.mileage} milya'),
          CardChip(Icons.two_wheeler, b.condition),
          CardChip(Icons.engineering, '${b.engineCc} cc'),
        ],
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => MotorbikeDetailScreen(initial: b))),
      );

  Widget _partCard(Part p) => ListingCard(
        heroTag: 'home-part-${p.id}',
        image: p.images.isEmpty ? null : p.images.first,
        title: p.title,
        kicker: '${p.brand} · ${p.type}',
        rating: siteRating(p.rank, home: true),
        price: formatPrice(p.price, p.currency),
        location: p.location,
        views: p.views,
        likes: p.likes,
        accent: CardAccent.indigo,
        action: 'Sotib Olish',
        chips: [
          CardChip(Icons.category_outlined, p.type),
          CardChip(Icons.two_wheeler, p.condition),
          CardChip(Icons.inventory_2_outlined, '${p.stock} dona'),
        ],
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => PartDetailScreen(initial: p))),
      );

  Widget _carousel<T>(Future<List<T>> future, Color color, double height,
      Widget Function(T) card,
      {bool chevrons = false}) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
              height: height,
              child: const Center(child: CircularProgressIndicator()));
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
                child: Text("Hozircha bo'sh",
                    style: TextStyle(color: Brand.muted))),
          );
        }
        return SiteCarousel(
          itemCount: items.length,
          height: height,
          color: color,
          chevrons: chevrons,
          itemBuilder: (context, i) => card(items[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final h = _cardHeight(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const HomeHero(),
          SiteSection(
            title: "Eng ko'p qidirilgan mototsikllar",
            subtitle: 'Trend yoqtirishlarga asoslangan',
            emoji: '🔥',
            gradient: _greenTitle,
            underline: Brand.green,
            child: _carousel(_trend, Brand.green, h,
                (Motorbike b) => _bikeCard(b, CardAccent.green, 'Sotib Olish')),
          ),
          SiteSection(
            title: 'Ommabop mototsikllar',
            subtitle: "Shu haftada eng ko'p ko'rilgan mototsikllar",
            emoji: '🔥  🔥',
            gradient: _indigoTitle,
            background: _grey,
            child: _carousel(
                _popular,
                Brand.indigo,
                h,
                (Motorbike b) =>
                    _bikeCard(b, CardAccent.indigo, 'Band Qilish')),
          ),
          const AdvertisementVideo(),
          SiteSection(
            title: "Eng zo'r mototsikllar",
            subtitle: 'Shu oyning eng yuqori baholangan mototsikllari',
            emoji: '🏆  🏆',
            gradient: _indigoTitle,
            child: _carousel(
                _top,
                Brand.indigo,
                h,
                (Motorbike b) =>
                    _bikeCard(b, CardAccent.indigo, 'Band Qilish')),
          ),
          SiteSection(
            title: "Eng zo'r ehtiyot qismlar",
            subtitle: 'Shu oyning eng ommabop ehtiyot qismlari',
            emoji: '🏆  🏆',
            gradient: _indigoTitle,
            background: _grey,
            child: _carousel(_topParts, Brand.indigo, h, _partCard),
          ),
          SiteSection(
            title: "Eng zo'r aksessuarlar",
            subtitle: 'Shu oyning eng ommabop aksessuarlari',
            emoji: '🏆  🏆',
            gradient: _indigoTitle,
            child: _carousel(_topAccessories, Brand.indigo, h, _partCard),
          ),
          SiteSection(
            title: 'Elita haydovchilar',
            subtitle: 'Hamjamiyatimiz chempionlari bilan tanishing',
            emoji: '⭐  ⭐',
            gradient: _indigoTitle,
            background: _grey,
            child: _carousel(
                _agents, Brand.indigo, 420, (Agent a) => AgentCard(agent: a),
                chevrons: true),
          ),
          const SiteFooter(),
        ],
      ),
    );
  }
}
