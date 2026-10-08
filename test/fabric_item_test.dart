import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/profile/data/fabric_item.dart';

void main() {
  test('FabricItem.fromMap parse les champs prod fabrics', () {
    final item = FabricItem.fromMap({
      'id': 'f1',
      'user_id': 'u1',
      'name': 'Lin lavé',
      'type': 'Lin',
      'color': 'ivoire',
      'length': 2.5,
      'width': 1.4,
      'image_url': 'https://example.com/a.jpg',
      'notes': 'Soldes',
      'created_at': '2026-04-08T10:00:00Z',
    });

    expect(item.id, 'f1');
    expect(item.titleLabel, 'Lin lavé');
    expect(item.subtitleLabel, 'Lin · ivoire · 2.5 m');
    expect(item.imageUrl, 'https://example.com/a.jpg');
    expect(item.createdAt, isNotNull);
  });
}
