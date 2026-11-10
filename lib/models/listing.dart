/// Seller info shown on detail pages.
class Seller {
  Seller({required this.id, required this.nick, this.phone, this.image, this.type});

  final String id;
  final String nick;
  final String? phone;
  final String? image;
  final String? type;

  static Seller? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    return Seller(
      id: '${j['_id']}',
      nick: '${j['memberNick'] ?? ''}',
      phone: j['memberPhone'] as String?,
      image: j['memberImage'] as String?,
      type: j['memberType'] as String?,
    );
  }
}

/// A motorbike for sale ("property" in the backend).
class Motorbike {
  Motorbike({
    required this.id,
    required this.title,
    required this.type,
    required this.brand,
    required this.condition,
    required this.location,
    required this.address,
    required this.price,
    required this.currency,
    required this.year,
    required this.engineCc,
    required this.mileage,
    required this.views,
    required this.likes,
    this.rank = 0,
    required this.images,
    required this.barter,
    required this.rent,
    this.description,
    this.createdAt,
    this.seller,
  });

  final String id;
  final String title;
  final String type;
  final String brand;
  final String condition;
  final String location;
  final String address;
  final num price;
  final String currency;
  final int year;
  final int engineCc;
  final int mileage;
  final int views;
  final int likes;
  final num rank;
  final List<String> images;
  final bool barter;
  final bool rent;
  final String? description;
  final DateTime? createdAt;
  final Seller? seller;

  factory Motorbike.fromJson(Map<String, dynamic> j) => Motorbike(
        id: '${j['_id']}',
        title: '${j['propertyTitle'] ?? ''}'.trim(),
        type: '${j['propertyType'] ?? ''}',
        brand: '${j['propertyBrand'] ?? ''}',
        condition: '${j['propertyCondition'] ?? ''}',
        location: '${j['propertyLocation'] ?? ''}',
        address: '${j['propertyAddress'] ?? ''}',
        price: (j['propertyPrice'] as num?) ?? 0,
        currency: '${j['propertyCurrency'] ?? 'USD'}',
        year: (j['propertyYear'] as num?)?.toInt() ?? 0,
        engineCc: (j['propertyEngineCc'] as num?)?.toInt() ?? 0,
        mileage: (j['propertyMileAge'] as num?)?.toInt() ?? 0,
        views: (j['propertyViews'] as num?)?.toInt() ?? 0,
        likes: (j['propertyLikes'] as num?)?.toInt() ?? 0,
        rank: (j['propertyRank'] as num?) ?? 0,
        images: ((j['propertyImages'] as List?) ?? const []).map((e) => '$e').toList(),
        barter: j['propertyBarter'] == true,
        rent: j['propertyRent'] == true,
        description: j['propertyDesc'] as String?,
        createdAt: DateTime.tryParse('${j['createdAt']}'),
        seller: Seller.fromJson(j['memberData'] as Map<String, dynamic>?),
      );
}

/// A spare part or accessory.
class Part {
  Part({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.brand,
    required this.condition,
    required this.location,
    required this.price,
    required this.currency,
    required this.stock,
    required this.compatibleBrands,
    required this.views,
    required this.likes,
    this.rank = 0,
    required this.images,
    required this.barter,
    this.description,
    this.createdAt,
    this.seller,
  });

  final String id;
  final String title;
  final String category;
  final String type;
  final String brand;
  final String condition;
  final String location;
  final num price;
  final String currency;
  final int stock;
  final List<String> compatibleBrands;
  final int views;
  final int likes;
  final num rank;
  final List<String> images;
  final bool barter;
  final String? description;
  final DateTime? createdAt;
  final Seller? seller;

  factory Part.fromJson(Map<String, dynamic> j) => Part(
        id: '${j['_id']}',
        title: '${j['partTitle'] ?? ''}'.trim(),
        category: '${j['partCategory'] ?? ''}',
        type: '${j['partType'] ?? ''}',
        brand: '${j['partBrand'] ?? ''}',
        condition: '${j['partCondition'] ?? ''}',
        location: '${j['partLocation'] ?? ''}',
        price: (j['partPrice'] as num?) ?? 0,
        currency: '${j['partCurrency'] ?? 'USD'}',
        stock: (j['partStockCount'] as num?)?.toInt() ?? 1,
        compatibleBrands: ((j['partCompatibleBrands'] as List?) ?? const []).map((e) => '$e').toList(),
        views: (j['partViews'] as num?)?.toInt() ?? 0,
        likes: (j['partLikes'] as num?)?.toInt() ?? 0,
        rank: (j['partRank'] as num?) ?? 0,
        images: ((j['partImages'] as List?) ?? const []).map((e) => '$e').toList(),
        barter: j['partBarter'] == true,
        description: j['partDesc'] as String?,
        createdAt: DateTime.tryParse('${j['createdAt']}'),
        seller: Seller.fromJson(j['memberData'] as Map<String, dynamic>?),
      );
}

class PageResult<T> {
  PageResult(this.items, this.total);
  final List<T> items;
  final int total;
}

/// A dealer shown in the home "Elite riders" carousel.
class Agent {
  Agent({required this.id, required this.nick, this.phone, this.image, this.rank = 0, this.type});

  final String id;
  final String nick;
  final String? phone;
  final String? image;
  final num rank;
  final String? type;

  factory Agent.fromJson(Map<String, dynamic> j) => Agent(
        id: '${j['_id']}',
        nick: '${j['memberNick'] ?? ''}',
        phone: j['memberPhone'] as String?,
        image: j['memberImage'] as String?,
        rank: (j['memberRank'] as num?) ?? 0,
        type: j['memberType'] as String?,
      );
}
