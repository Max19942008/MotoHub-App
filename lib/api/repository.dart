import '../config.dart';
import '../models/listing.dart';
import 'graphql_client.dart';

const _sellerFields = '''
  memberData { _id memberNick memberPhone memberImage memberType }
''';

const _motorbikeFields = '''
  _id propertyType propertyLocation propertyBrand propertyCondition propertyAddress
  propertyTitle propertyPrice propertyCurrency propertyYear propertyEngineCc
  propertyMileAge propertyViews propertyLikes propertyImages propertyDesc
  propertyBarter propertyRent createdAt
  $_sellerFields
''';

const _partFields = '''
  _id partCategory partType partLocation partBrand partCondition partTitle
  partPrice partCurrency partStockCount partCompatibleBrands partViews partLikes
  partImages partDesc partBarter createdAt
  $_sellerFields
''';

/// Sort options shared by both lists; the backend field differs per entity.
enum SortOption {
  newest('Eng yangi', 'createdAt', 'DESC'),
  cheapest('Arzonroq', 'Price', 'ASC'),
  priciest('Qimmatroq', 'Price', 'DESC'),
  popular('Ommabop', 'Views', 'DESC');

  const SortOption(this.label, this.field, this.direction);
  final String label;
  final String field;
  final String direction;

  String fieldFor(String prefix) => field == 'createdAt' ? field : '$prefix$field';
}

/// Filters for the motorbike list. Empty = no filter.
class MotorbikeFilter {
  MotorbikeFilter({
    this.text = '',
    this.brands = const {},
    this.types = const {},
    this.conditions = const {},
    this.locations = const {},
    this.minPrice,
    this.maxPrice,
    this.sort = SortOption.newest,
  });

  final String text;
  final Set<String> brands;
  final Set<String> types;
  final Set<String> conditions;
  final Set<String> locations;
  final int? minPrice;
  final int? maxPrice;
  final SortOption sort;

  int get activeCount =>
      brands.length + types.length + conditions.length + locations.length + (minPrice != null || maxPrice != null ? 1 : 0);

  MotorbikeFilter copyWith({
    String? text,
    Set<String>? brands,
    Set<String>? types,
    Set<String>? conditions,
    Set<String>? locations,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    SortOption? sort,
  }) =>
      MotorbikeFilter(
        text: text ?? this.text,
        brands: brands ?? this.brands,
        types: types ?? this.types,
        conditions: conditions ?? this.conditions,
        locations: locations ?? this.locations,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toSearch() => {
        if (text.trim().isNotEmpty) 'text': text.trim(),
        if (brands.isNotEmpty) 'brandList': brands.toList(),
        if (types.isNotEmpty) 'typeList': types.toList(),
        if (conditions.isNotEmpty) 'conditionList': conditions.toList(),
        if (locations.isNotEmpty) 'locationList': locations.toList(),
        if (minPrice != null || maxPrice != null)
          'pricesRange': {'start': minPrice ?? 0, 'end': maxPrice ?? 100000000},
      };
}

/// Filters for the parts list. [category] is SPARE_PART or ACCESSORY.
class PartFilter {
  PartFilter({
    required this.category,
    this.text = '',
    this.types = const {},
    this.brands = const {},
    this.conditions = const {},
    this.locations = const {},
    this.sort = SortOption.newest,
  });

  final String category;
  final String text;
  final Set<String> types;
  final Set<String> brands;
  final Set<String> conditions;
  final Set<String> locations;
  final SortOption sort;

  int get activeCount => types.length + brands.length + conditions.length + locations.length;

  PartFilter copyWith({
    String? text,
    Set<String>? types,
    Set<String>? brands,
    Set<String>? conditions,
    Set<String>? locations,
    SortOption? sort,
  }) =>
      PartFilter(
        category: category,
        text: text ?? this.text,
        types: types ?? this.types,
        brands: brands ?? this.brands,
        conditions: conditions ?? this.conditions,
        locations: locations ?? this.locations,
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toSearch() => {
        'categoryList': [category],
        if (text.trim().isNotEmpty) 'text': text.trim(),
        if (types.isNotEmpty) 'typeList': types.toList(),
        if (brands.isNotEmpty) 'brandList': brands.toList(),
        if (conditions.isNotEmpty) 'conditionList': conditions.toList(),
        if (locations.isNotEmpty) 'locationList': locations.toList(),
      };
}

class Repository {
  Repository._();
  static final Repository instance = Repository._();

  final _gql = GraphQLClient.instance;

  Future<PageResult<Motorbike>> motorbikes(MotorbikeFilter filter, int page) async {
    final data = await _gql.query('''
      query (\$input: PropertiesInquiry!) {
        getProperties(input: \$input) {
          list { $_motorbikeFields }
          metaCounter { total }
        }
      }
    ''', variables: {
      'input': {
        'page': page,
        'limit': pageSize,
        'sort': filter.sort.fieldFor('property'),
        'direction': filter.sort.direction,
        'search': filter.toSearch(),
      },
    });
    final result = data['getProperties'] as Map<String, dynamic>;
    return PageResult(
      (result['list'] as List).map((e) => Motorbike.fromJson(e as Map<String, dynamic>)).toList(),
      _total(result),
    );
  }

  Future<Motorbike> motorbike(String id) async {
    final data = await _gql.query('''
      query (\$id: String!) { getProperty(propertyId: \$id) { $_motorbikeFields } }
    ''', variables: {'id': id});
    return Motorbike.fromJson(data['getProperty'] as Map<String, dynamic>);
  }

  Future<PageResult<Part>> parts(PartFilter filter, int page) async {
    final data = await _gql.query('''
      query (\$input: PartsInquiry!) {
        getParts(input: \$input) {
          list { $_partFields }
          metaCounter { total }
        }
      }
    ''', variables: {
      'input': {
        'page': page,
        'limit': pageSize,
        'sort': filter.sort.fieldFor('part'),
        'direction': filter.sort.direction,
        'search': filter.toSearch(),
      },
    });
    final result = data['getParts'] as Map<String, dynamic>;
    return PageResult(
      (result['list'] as List).map((e) => Part.fromJson(e as Map<String, dynamic>)).toList(),
      _total(result),
    );
  }

  Future<Part> part(String id) async {
    final data = await _gql.query('''
      query (\$id: String!) { getPart(partId: \$id) { $_partFields } }
    ''', variables: {'id': id});
    return Part.fromJson(data['getPart'] as Map<String, dynamic>);
  }

  int _total(Map<String, dynamic> result) {
    final counter = result['metaCounter'];
    if (counter is List && counter.isNotEmpty) return (counter.first['total'] as num?)?.toInt() ?? 0;
    return 0;
  }
}
