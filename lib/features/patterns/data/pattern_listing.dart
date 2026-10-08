/// Patron marketplace (table `patterns` + auteur `profiles`).
class PatternListing {
  const PatternListing({
    required this.id,
    required this.authorId,
    required this.name,
    required this.price,
    this.currency = 'EUR',
    this.description = '',
    this.brand,
    this.category,
    this.type,
    this.coverImage,
    this.images = const [],
    this.isPublished = false,
    this.isDraft = false,
    this.archived = false,
    this.salesCount = 0,
    this.difficulty,
    this.createdAt,
    this.authorUsername,
    this.authorDisplayName,
  });

  final String id;
  final String authorId;
  final String name;
  final double price;
  final String currency;
  final String description;
  final String? brand;
  final String? category;
  final String? type;
  final String? coverImage;
  final List<String> images;
  final bool isPublished;
  final bool isDraft;
  final bool archived;
  final int salesCount;
  final String? difficulty;
  final DateTime? createdAt;
  final String? authorUsername;
  final String? authorDisplayName;

  /// Première image utilisable (cover ou images[]).
  String? get primaryImageUrl {
    final cover = coverImage?.trim();
    if (cover != null && cover.isNotEmpty) return cover;
    for (final url in images) {
      final t = url.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }

  String get authorLabel {
    final display = authorDisplayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    final user = authorUsername?.trim();
    if (user != null && user.isNotEmpty) return user;
    final b = brand?.trim();
    if (b != null && b.isNotEmpty) return b;
    return 'Designer';
  }

  String get priceLabel {
    final formatted = price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
    return '$formatted $currency';
  }

  String get statusLabelFr {
    if (archived) return 'Archivé';
    if (isPublished && !isDraft) return 'Publié';
    if (isDraft) return 'Brouillon';
    return 'Non publié';
  }

  bool get isLive => isPublished && !isDraft && !archived;

  factory PatternListing.fromMap(Map<String, dynamic> map) {
    final author = map['author'];
    Map<String, dynamic>? authorMap;
    if (author is Map) {
      authorMap = Map<String, dynamic>.from(author);
    }

    final imagesRaw = map['images'];
    final images = <String>[];
    if (imagesRaw is List) {
      for (final item in imagesRaw) {
        if (item is String && item.trim().isNotEmpty) {
          images.add(item);
        }
      }
    }

    final createdRaw = map['created_at'];
    DateTime? createdAt;
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    return PatternListing(
      id: map['id'] as String,
      authorId: map['author_id'] as String? ?? '',
      name: (map['name'] as String?)?.trim().isNotEmpty == true
          ? (map['name'] as String).trim()
          : 'Patron sans nom',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      currency: (map['currency'] as String?)?.trim().isNotEmpty == true
          ? (map['currency'] as String).trim()
          : 'EUR',
      description: (map['description'] as String?) ?? '',
      brand: map['brand'] as String?,
      category: map['category'] as String?,
      type: map['type'] as String?,
      coverImage: map['cover_image'] as String?,
      images: images,
      isPublished: map['is_published'] as bool? ?? false,
      isDraft: map['is_draft'] as bool? ?? false,
      archived: map['archived'] as bool? ?? false,
      salesCount: (map['sales_count'] as num?)?.toInt() ?? 0,
      difficulty: map['difficulty'] as String?,
      createdAt: createdAt,
      authorUsername: authorMap?['username'] as String?,
      authorDisplayName: authorMap?['display_name'] as String?,
    );
  }
}

/// Champs minimaux pour créer / éditer une fiche patron.
class PatternListingInput {
  const PatternListingInput({
    required this.name,
    required this.price,
    this.description = '',
    this.coverImageUrl,
    this.type,
    this.isPublished = true,
  });

  final String name;
  final double price;
  final String description;
  final String? coverImageUrl;
  final String? type;
  final bool isPublished;
}
