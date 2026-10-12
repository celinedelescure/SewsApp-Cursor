/// Tissu du stock couturière (table prod `fabrics` — équivalent `fabric_stash`).
class FabricItem {
  const FabricItem({
    required this.id,
    required this.userId,
    required this.name,
    this.type,
    this.weave,
    this.weight,
    this.stretch,
    this.color,
    this.pattern,
    this.length,
    this.width,
    this.imageUrl,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? type;
  final String? weave;
  final String? weight;
  final String? stretch;
  final String? color;
  final String? pattern;
  final double? length;
  final double? width;
  final String? imageUrl;
  final String? notes;
  final DateTime? createdAt;

  String get titleLabel {
    final n = name.trim();
    if (n.isNotEmpty) return n;
    return 'Tissu';
  }

  String? get subtitleLabel {
    final parts = <String>[
      if (type != null && type!.trim().isNotEmpty) type!.trim(),
      if (color != null && color!.trim().isNotEmpty) color!.trim(),
      if (length != null) '${_fmtNum(length!)} m',
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String _fmtNum(double v) {
    if (v.truncateToDouble() == v) return v.toStringAsFixed(0);
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  factory FabricItem.fromMap(Map<String, dynamic> map) {
    DateTime? createdAt;
    final raw = map['created_at'];
    if (raw is String) createdAt = DateTime.tryParse(raw);

    return FabricItem(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      name: (map['name'] as String?)?.trim() ?? '',
      type: map['type'] as String?,
      weave: map['weave'] as String?,
      weight: map['weight'] as String?,
      stretch: map['stretch'] as String?,
      color: map['color'] as String?,
      pattern: map['pattern'] as String?,
      length: (map['length'] as num?)?.toDouble(),
      width: (map['width'] as num?)?.toDouble(),
      imageUrl: map['image_url'] as String?,
      notes: map['notes'] as String?,
      createdAt: createdAt,
    );
  }
}

/// Champs pour créer un tissu dans le stock.
class FabricItemInput {
  const FabricItemInput({
    required this.name,
    this.type,
    this.color,
    this.length,
    this.width,
    this.imageUrl,
    this.notes,
    this.weave,
    this.weight,
    this.stretch,
  });

  final String name;
  final String? type;
  final String? color;
  final double? length;
  final double? width;
  final String? imageUrl;
  final String? notes;
  final String? weave;
  final String? weight;
  final String? stretch;
}
