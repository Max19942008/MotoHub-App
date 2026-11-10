/// Seller info shown on detail pages.
class Seller {
  Seller(
      {required this.id,
      required this.nick,
      this.phone,
      this.image,
      this.type});

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
    this.liked = false,
    this.interested = false,
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

  /// Set only on the detail query, for the logged-in member.
  final bool liked;
  final bool interested;
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
        liked: _flag(j['meLiked'], 'myFavorite'),
        interested: _flag(j['meInterested'], 'myInterest'),
        images: ((j['propertyImages'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
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
    this.liked = false,
    this.interested = false,
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

  /// Set only on the detail query, for the logged-in member.
  final bool liked;
  final bool interested;
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
        compatibleBrands: ((j['partCompatibleBrands'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
        views: (j['partViews'] as num?)?.toInt() ?? 0,
        likes: (j['partLikes'] as num?)?.toInt() ?? 0,
        rank: (j['partRank'] as num?) ?? 0,
        liked: _flag(j['meLiked'], 'myFavorite'),
        interested: _flag(j['meInterested'], 'myInterest'),
        images:
            ((j['partImages'] as List?) ?? const []).map((e) => '$e').toList(),
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

/// A dealer (member of type AGENT).
class Agent {
  Agent({
    required this.id,
    required this.nick,
    this.phone,
    this.image,
    this.rank = 0,
    this.type,
    this.address,
    this.properties = 0,
    this.views = 0,
    this.likes = 0,
    this.liked = false,
    this.followed = false,
    this.fullName,
  });

  final String id;
  final String nick;
  final String? fullName;
  final String? phone;
  final String? image;
  final num rank;
  final String? type;
  final String? address;
  final int properties;
  final int views;
  final int likes;
  final bool liked;
  final bool followed;

  factory Agent.fromJson(Map<String, dynamic> j) => Agent(
        id: '${j['_id']}',
        nick: '${j['memberNick'] ?? ''}',
        phone: j['memberPhone'] as String?,
        image: j['memberImage'] as String?,
        rank: (j['memberRank'] as num?) ?? 0,
        type: j['memberType'] as String?,
        address: j['memberAddress'] as String?,
        properties: (j['memberProperties'] as num?)?.toInt() ?? 0,
        views: (j['memberViews'] as num?)?.toInt() ?? 0,
        likes: (j['memberLikes'] as num?)?.toInt() ?? 0,
        liked: _flag(j['meLiked'], 'myFavorite'),
        followed: _flag(j['meFollowed'], 'myFollowing'),
        fullName: j['memberFullName'] as String?,
      );

  /// The site gives every agent card one of six color themes from its id.
  int get variant => id.codeUnits.fold<int>(0, (a, c) => a + c) % 6;
}

/// meLiked: [{myFavorite: true}] -> true
bool _flag(dynamic list, String key) =>
    list is List && list.isNotEmpty && (list.first as Map)[key] == true;

/// A review under a listing.
class Comment {
  Comment(
      {required this.id,
      required this.content,
      required this.author,
      this.authorImage,
      this.createdAt});

  final String id;
  final String content;
  final String author;
  final String? authorImage;
  final DateTime? createdAt;

  factory Comment.fromJson(Map<String, dynamic> j) {
    final member = j['memberData'] as Map<String, dynamic>?;
    return Comment(
      id: '${j['_id']}',
      content: '${j['commentContent'] ?? ''}',
      author: '${member?['memberNick'] ?? ''}',
      authorImage: member?['memberImage'] as String?,
      createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
    );
  }
}

/// A community post (BoardArticle on the backend).
class Article {
  Article({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    this.image,
    this.views = 0,
    this.likes = 0,
    this.comments = 0,
    this.liked = false,
    this.createdAt,
    this.authorId,
    this.author = '',
    this.authorImage,
  });

  final String id;
  final String category;
  final String title;
  final String content;
  final String? image;
  final int views;
  final int likes;
  final int comments;
  final bool liked;
  final DateTime? createdAt;
  final String? authorId;
  final String author;
  final String? authorImage;

  factory Article.fromJson(Map<String, dynamic> j) {
    final member = j['memberData'] as Map<String, dynamic>?;
    final image = j['articleImage'] as String?;
    return Article(
      id: '${j['_id']}',
      category: '${j['articleCategory'] ?? 'FREE'}',
      title: '${j['articleTitle'] ?? ''}',
      content: '${j['articleContent'] ?? ''}',
      image: (image == null || image.isEmpty) ? null : image,
      views: (j['articleViews'] as num?)?.toInt() ?? 0,
      likes: (j['articleLikes'] as num?)?.toInt() ?? 0,
      comments: (j['articleComments'] as num?)?.toInt() ?? 0,
      liked: _flag(j['meLiked'], 'myFavorite'),
      createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
      authorId: member?['_id'] as String?,
      author: '${member?['memberNick'] ?? ''}',
      authorImage: member?['memberImage'] as String?,
    );
  }
}

/// A row of "Obunachilarim" / "Obunalarim": the other member and my relation.
class FollowMember {
  FollowMember({
    required this.id,
    required this.nick,
    this.image,
    this.followers = 0,
    this.followings = 0,
    this.likes = 0,
    this.liked = false,
    this.followed = false,
  });

  final String id;
  final String nick;
  final String? image;
  final int followers;
  final int followings;
  final int likes;
  final bool liked;
  final bool followed;

  /// [key] is followerData (followers list) or followingData (followings list).
  factory FollowMember.fromJson(Map<String, dynamic> j, String key) {
    final m = (j[key] as Map<String, dynamic>?) ?? const {};
    return FollowMember(
      id: '${m['_id'] ?? ''}',
      nick: '${m['memberNick'] ?? ''}',
      image: (m['memberImage'] as String?)?.isEmpty == true
          ? null
          : m['memberImage'] as String?,
      followers: (m['memberFollowers'] as num?)?.toInt() ?? 0,
      followings: (m['memberFollowings'] as num?)?.toInt() ?? 0,
      likes: (m['memberLikes'] as num?)?.toInt() ?? 0,
      liked: _flag(j['meLiked'], 'myFavorite'),
      followed: _flag(j['meFollowed'], 'myFollowing'),
    );
  }
}
