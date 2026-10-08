/// Publication du fil d'actualité (table `posts` + auteur `profiles`).
class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorId,
    required this.createdAt,
    this.caption = '',
    this.imageUrl,
    this.images = const [],
    this.likesCount = 0,
    this.patternName,
    this.patternBrand,
    this.category,
    this.type,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
  });

  final String id;
  final String authorId;
  final DateTime createdAt;
  final String caption;
  final String? imageUrl;
  final List<String> images;
  final int likesCount;
  final String? patternName;
  final String? patternBrand;
  final String? category;
  final String? type;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;

  /// Première image utilisable (image_url ou images[]).
  String? get primaryImageUrl {
    final direct = imageUrl?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
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
    return 'Couturière';
  }

  /// Titre affiché : caption, sinon nom de patron, sinon type.
  String get titleText {
    final cap = caption.trim();
    if (cap.isNotEmpty) return cap;
    final pattern = patternName?.trim();
    if (pattern != null && pattern.isNotEmpty) {
      final brand = patternBrand?.trim();
      if (brand != null && brand.isNotEmpty) {
        return '$pattern · $brand';
      }
      return pattern;
    }
    final t = type?.trim();
    if (t != null && t.isNotEmpty) return t;
    return 'Création cousue';
  }

  bool get hasCaption => caption.trim().isNotEmpty;

  factory FeedPost.fromMap(Map<String, dynamic> map) {
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
    final createdAt = createdRaw is String
        ? DateTime.tryParse(createdRaw) ?? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);

    return FeedPost(
      id: map['id'] as String,
      authorId: map['author_id'] as String? ?? '',
      createdAt: createdAt,
      caption: (map['caption'] as String?) ?? '',
      imageUrl: map['image_url'] as String?,
      images: images,
      likesCount: (map['likes_count'] as num?)?.toInt() ?? 0,
      patternName: map['pattern_name'] as String?,
      patternBrand: map['pattern_brand'] as String?,
      category: map['category'] as String?,
      type: map['type'] as String?,
      authorUsername: authorMap?['username'] as String?,
      authorDisplayName: authorMap?['display_name'] as String?,
      authorAvatarUrl: authorMap?['avatar_url'] as String?,
    );
  }
}
