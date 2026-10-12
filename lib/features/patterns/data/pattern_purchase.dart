/// Achat de patron (table `purchases`) — lecture seule côté client.
class PatternPurchase {
  const PatternPurchase({
    required this.id,
    required this.userId,
    required this.patternId,
    this.patternName,
    this.brand,
    this.pricePaid,
    this.currency = 'EUR',
    this.purchasedAt,
    this.coverImage,
  });

  final String id;
  final String userId;
  final String patternId;
  final String? patternName;
  final String? brand;
  final double? pricePaid;
  final String currency;
  final DateTime? purchasedAt;
  final String? coverImage;

  String get titleLabel {
    final name = patternName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Patron acheté';
  }

  String? get priceLabel {
    final paid = pricePaid;
    if (paid == null) return null;
    final formatted =
        paid.toStringAsFixed(paid.truncateToDouble() == paid ? 0 : 2);
    return '$formatted $currency';
  }

  factory PatternPurchase.fromMap(Map<String, dynamic> map) {
    final purchasedRaw = map['purchased_at'];
    DateTime? purchasedAt;
    if (purchasedRaw is String) {
      purchasedAt = DateTime.tryParse(purchasedRaw);
    }

    return PatternPurchase(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      patternId: map['pattern_id'] as String? ?? '',
      patternName: map['pattern_name'] as String?,
      brand: (map['brand'] as String?) ?? (map['pattern_brand'] as String?),
      pricePaid: (map['price_paid'] as num?)?.toDouble(),
      currency: (map['currency'] as String?)?.trim().isNotEmpty == true
          ? (map['currency'] as String).trim()
          : 'EUR',
      purchasedAt: purchasedAt,
      coverImage: map['cover_image'] as String?,
    );
  }
}
