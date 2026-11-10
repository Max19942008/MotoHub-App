import '../config.dart';
import '../models/listing.dart';
import 'graphql_client.dart';

const _sellerFields = '''
  memberData { _id memberNick memberPhone memberImage memberType }
''';

const _motorbikeFields = '''
  _id propertyType propertyLocation propertyBrand propertyCondition propertyAddress
  propertyTitle propertyPrice propertyCurrency propertyYear propertyEngineCc
  propertyMileAge propertyViews propertyLikes propertyRank propertyImages propertyDesc
  propertyBarter propertyRent createdAt
  $_sellerFields
''';

const _meFields = 'meLiked { myFavorite } meInterested { myInterest }';

const _agentFields = '''
  _id memberNick memberFullName memberPhone memberImage memberRank memberType memberAddress
  memberProperties memberViews memberLikes meLiked { myFavorite }
''';

const _partFields = '''
  _id partCategory partType partLocation partBrand partCondition partTitle
  partPrice partCurrency partStockCount partCompatibleBrands partViews partLikes partRank
  partImages partDesc partBarter createdAt
  $_sellerFields
''';

/// Sort options, same as the website's sort menu.
enum SortOption {
  recent("So'nggi", 'createdAt', 'DESC'),
  oldest('Eng eski', 'createdAt', 'ASC'),
  likes('Yoqtirishlar', 'Likes', 'DESC'),
  views("Ko'rishlar", 'Views', 'DESC');

  const SortOption(this.label, this.field, this.direction);
  final String label;
  final String field;
  final String direction;

  String fieldFor(String prefix) =>
      field == 'createdAt' ? field : '$prefix$field';
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
    this.minYear,
    this.maxYear,
    this.sort,
  });

  final String text;
  final Set<String> brands;
  final Set<String> types;
  final Set<String> conditions;
  final Set<String> locations;
  final int? minPrice;
  final int? maxPrice;
  final int? minYear;
  final int? maxYear;

  /// null = not chosen yet (the site's button then reads "Yangi").
  final SortOption? sort;

  SortOption get effectiveSort => sort ?? SortOption.recent;

  int get activeCount =>
      brands.length +
      types.length +
      conditions.length +
      locations.length +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (minYear != null || maxYear != null ? 1 : 0);

  MotorbikeFilter copyWith({
    String? text,
    Set<String>? brands,
    Set<String>? types,
    Set<String>? conditions,
    Set<String>? locations,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    int? Function()? minYear,
    int? Function()? maxYear,
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
        minYear: minYear != null ? minYear() : this.minYear,
        maxYear: maxYear != null ? maxYear() : this.maxYear,
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toSearch() => {
        if (text.trim().isNotEmpty) 'text': text.trim(),
        if (brands.isNotEmpty) 'brandList': brands.toList(),
        if (types.isNotEmpty) 'typeList': types.toList(),
        if (conditions.isNotEmpty) 'conditionList': conditions.toList(),
        if (locations.isNotEmpty) 'locationList': locations.toList(),
        if (minPrice != null || maxPrice != null)
          'pricesRange': {'start': minPrice ?? 0, 'end': maxPrice ?? 2000000},
        if (minYear != null || maxYear != null)
          'yearRange': {
            'start': minYear ?? 1970,
            'end': maxYear ?? DateTime.now().year
          },
      };
}

/// Filters for the parts list. [category] is SPARE_PART, ACCESSORY or ALL.
class PartFilter {
  PartFilter({
    required this.category,
    this.text = '',
    this.types = const {},
    this.brands = const {},
    this.conditions = const {},
    this.locations = const {},
    this.minPrice,
    this.maxPrice,
    this.sort,
  });

  final String category;
  final String text;
  final Set<String> types;
  final Set<String> brands;
  final Set<String> conditions;
  final Set<String> locations;
  final int? minPrice;
  final int? maxPrice;
  final SortOption? sort;

  SortOption get effectiveSort => sort ?? SortOption.recent;

  int get activeCount =>
      types.length +
      brands.length +
      conditions.length +
      locations.length +
      (minPrice != null || maxPrice != null ? 1 : 0);

  PartFilter copyWith({
    String? text,
    Set<String>? types,
    Set<String>? brands,
    Set<String>? conditions,
    Set<String>? locations,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    SortOption? sort,
  }) =>
      PartFilter(
        category: category,
        text: text ?? this.text,
        types: types ?? this.types,
        brands: brands ?? this.brands,
        conditions: conditions ?? this.conditions,
        locations: locations ?? this.locations,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        sort: sort ?? this.sort,
      );

  Map<String, dynamic> toSearch() => {
        if (category != 'ALL') 'categoryList': [category],
        if (text.trim().isNotEmpty) 'text': text.trim(),
        if (types.isNotEmpty) 'typeList': types.toList(),
        if (brands.isNotEmpty) 'brandList': brands.toList(),
        if (conditions.isNotEmpty) 'conditionList': conditions.toList(),
        if (locations.isNotEmpty) 'locationList': locations.toList(),
        if (minPrice != null || maxPrice != null)
          'pricesRange': {'start': minPrice ?? 0, 'end': maxPrice ?? 2000000},
      };
}

class Repository {
  Repository._();
  static final Repository instance = Repository._();

  final _gql = GraphQLClient.instance;

  Future<PageResult<Motorbike>> motorbikes(
      MotorbikeFilter filter, int page) async {
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
        'sort': filter.effectiveSort.fieldFor('property'),
        'direction': filter.effectiveSort.direction,
        'search': filter.toSearch(),
      },
    });
    final result = data['getProperties'] as Map<String, dynamic>;
    return PageResult(
      (result['list'] as List)
          .map((e) => Motorbike.fromJson(e as Map<String, dynamic>))
          .toList(),
      _total(result),
    );
  }

  /// Home carousels: a fixed top-N by [sort] (propertyLikes | propertyViews | propertyRank).
  Future<List<Motorbike>> topMotorbikes(String sort, int limit) async {
    final data = await _gql.query('''
      query (\$input: PropertiesInquiry!) { getProperties(input: \$input) { list { $_motorbikeFields } } }
    ''', variables: {
      'input': {
        'page': 1,
        'limit': limit,
        'sort': sort,
        'direction': 'DESC',
        'search': <String, dynamic>{}
      },
    });
    return ((data['getProperties'] as Map<String, dynamic>)['list'] as List)
        .map((e) => Motorbike.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Home "Top spare parts / accessories" carousels.
  Future<List<Part>> topParts(String category, int limit) async {
    final data = await _gql.query('''
      query (\$input: PartsInquiry!) { getParts(input: \$input) { list { $_partFields } } }
    ''', variables: {
      'input': {
        'page': 1,
        'limit': limit,
        'sort': 'partRank',
        'direction': 'DESC',
        'search': {
          'categoryList': [category]
        },
      },
    });
    return ((data['getParts'] as Map<String, dynamic>)['list'] as List)
        .map((e) => Part.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Home "Elite riders" carousel.
  Future<List<Agent>> topAgents(int limit) async {
    final data = await _gql.query('''
      query (\$input: AgentsInquiry!) {
        getAgents(input: \$input) { list { $_agentFields } }
      }
    ''', variables: {
      'input': {
        'page': 1,
        'limit': limit,
        'sort': 'memberRank',
        'direction': 'DESC',
        'search': <String, dynamic>{}
      },
    });
    return ((data['getAgents'] as Map<String, dynamic>)['list'] as List)
        .map((e) => Agent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Motorbike> motorbike(String id) async {
    final data = await _gql.query('''
      query (\$id: String!) { getProperty(propertyId: \$id) { $_motorbikeFields $_meFields } }
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
        'sort': filter.effectiveSort.fieldFor('part'),
        'direction': filter.effectiveSort.direction,
        'search': filter.toSearch(),
      },
    });
    final result = data['getParts'] as Map<String, dynamic>;
    return PageResult(
      (result['list'] as List)
          .map((e) => Part.fromJson(e as Map<String, dynamic>))
          .toList(),
      _total(result),
    );
  }

  Future<Part> part(String id) async {
    final data = await _gql.query('''
      query (\$id: String!) { getPart(partId: \$id) { $_partFields $_meFields } }
    ''', variables: {'id': id});
    return Part.fromJson(data['getPart'] as Map<String, dynamic>);
  }

  // ---- detail page actions (need a logged-in member) ----

  Future<void> likeMotorbike(String id) => _gql.query(
      r'mutation ($id: String!) { likeTargetProperty(propertyId: $id) { _id } }',
      variables: {'id': id});

  Future<void> likePart(String id) => _gql.query(
      r'mutation ($id: String!) { likeTargetPart(partId: $id) { _id } }',
      variables: {'id': id});

  /// Tells the dealer "I'm interested" (one-way, like the site).
  Future<void> notifyInterest(String id) =>
      _gql.query(r'mutation ($id: String!) { notifyInterest(propertyId: $id) }',
          variables: {'id': id});

  Future<void> notifyPartInterest(String id) =>
      _gql.query(r'mutation ($id: String!) { notifyPartInterest(partId: $id) }',
          variables: {'id': id});

  Future<PageResult<Comment>> comments(String refId, int page) async {
    final data = await _gql.query(r'''
      query ($input: CommentsInquiry!) {
        getComments(input: $input) {
          list { _id commentContent createdAt memberData { memberNick memberImage } }
          metaCounter { total }
        }
      }
    ''', variables: {
      'input': {
        'page': page,
        'limit': 5,
        'sort': 'createdAt',
        'direction': 'DESC',
        'search': {'commentRefId': refId},
      },
    });
    final result = data['getComments'] as Map<String, dynamic>;
    return PageResult(
      (result['list'] as List)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList(),
      _total(result),
    );
  }

  /// [group] is PROPERTY or PART.
  Future<void> addComment(String group, String refId, String content) =>
      _gql.query(
        r'mutation ($input: CommentInput!) { createComment(input: $input) { _id } }',
        variables: {
          'input': {
            'commentGroup': group,
            'commentRefId': refId,
            'commentContent': content
          },
        },
      );

  /// "Related bikes": newest in the same region (site query).
  Future<List<Motorbike>> similarMotorbikes(String location) async {
    final data = await _gql.query('''
      query (\$input: PropertiesInquiry!) { getProperties(input: \$input) { list { $_motorbikeFields } } }
    ''', variables: {
      'input': {
        'page': 1,
        'limit': 9,
        'sort': 'createdAt',
        'direction': 'DESC',
        'search': {
          'locationList': [location]
        },
      },
    });
    return ((data['getProperties'] as Map<String, dynamic>)['list'] as List)
        .map((e) => Motorbike.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// "Related parts": newest in the same category (site query).
  Future<List<Part>> similarParts(String category) async {
    final data = await _gql.query('''
      query (\$input: PartsInquiry!) { getParts(input: \$input) { list { $_partFields } } }
    ''', variables: {
      'input': {
        'page': 1,
        'limit': 9,
        'sort': 'createdAt',
        'direction': 'DESC',
        'search': {
          'categoryList': [category]
        },
      },
    });
    return ((data['getParts'] as Map<String, dynamic>)['list'] as List)
        .map((e) => Part.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---- agents ----

  /// Agents page. [sort]: createdAt | memberLikes | memberViews.
  Future<PageResult<Agent>> agents(int page,
      {String sort = 'createdAt',
      String direction = 'DESC',
      String text = ''}) async {
    final data = await _gql.query('''
      query (\$input: AgentsInquiry!) {
        getAgents(input: \$input) { list { $_agentFields } metaCounter { total } }
      }
    ''', variables: {
      'input': {
        'page': page,
        'limit': 10,
        'sort': sort,
        'direction': direction,
        'search': {if (text.trim().isNotEmpty) 'text': text.trim()},
      },
    });
    final result = data['getAgents'] as Map<String, dynamic>;
    return PageResult(
      (result['list'] as List)
          .map((e) => Agent.fromJson(e as Map<String, dynamic>))
          .toList(),
      _total(result),
    );
  }

  Future<Agent> agent(String id) async {
    final data = await _gql.query('''
      query (\$id: String!) { getMember(memberId: \$id) { $_agentFields meFollowed { myFollowing } } }
    ''', variables: {'id': id});
    return Agent.fromJson(data['getMember'] as Map<String, dynamic>);
  }

  /// "Bikes (13)" tab of an agent page.
  Future<PageResult<Motorbike>> agentMotorbikes(
      String memberId, int page) async {
    final data = await _gql.query('''
      query (\$input: PropertiesInquiry!) {
        getProperties(input: \$input) { list { $_motorbikeFields } metaCounter { total } }
      }
    ''', variables: {
      'input': {
        'page': page,
        'limit': 9,
        'sort': 'createdAt',
        'direction': 'DESC',
        'search': {'memberId': memberId},
      },
    });
    final result = data['getProperties'] as Map<String, dynamic>;
    return PageResult(
      (result['list'] as List)
          .map((e) => Motorbike.fromJson(e as Map<String, dynamic>))
          .toList(),
      _total(result),
    );
  }

  Future<void> likeMember(String id) => _gql.query(
      r'mutation ($id: String!) { likeTargetMember(memberId: $id) { _id } }',
      variables: {'id': id});

  Future<void> follow(String id) =>
      _gql.query(r'mutation ($id: String!) { subscribe(input: $id) { _id } }',
          variables: {'id': id});

  Future<void> unfollow(String id) =>
      _gql.query(r'mutation ($id: String!) { unsubscribe(input: $id) { _id } }',
          variables: {'id': id});

  int _total(Map<String, dynamic> result) {
    final counter = result['metaCounter'];
    if (counter is List && counter.isNotEmpty) {
      return (counter.first['total'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}
