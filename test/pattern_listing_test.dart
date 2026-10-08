import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/patterns/data/pattern_listing.dart';

void main() {
  test('PatternListing.fromMap parse catalogue publié', () {
    final pattern = PatternListing.fromMap({
      'id': 'p1',
      'author_id': 'a1',
      'name': 'Chemise Nicole',
      'price': 13.0,
      'currency': 'EUR',
      'description': 'Une chemise ample',
      'brand': 'Atelier Bernie',
      'type': 'Shirt',
      'cover_image': 'https://example.com/c.jpg',
      'images': ['https://example.com/c.jpg', 'https://example.com/2.jpg'],
      'is_published': true,
      'is_draft': false,
      'archived': false,
      'sales_count': 2,
      'difficulty': 'Intermediate',
      'created_at': '2026-04-20T09:29:03.016276+00:00',
      'author': {
        'username': 'atelier',
        'display_name': 'Atelier Bernie',
      },
    });

    expect(pattern.name, 'Chemise Nicole');
    expect(pattern.priceLabel, '13 EUR');
    expect(pattern.primaryImageUrl, 'https://example.com/c.jpg');
    expect(pattern.authorLabel, 'Atelier Bernie');
    expect(pattern.isLive, isTrue);
    expect(pattern.statusLabelFr, 'Publié');
    expect(pattern.images, hasLength(2));
  });

  test('PatternListing status brouillon / archivé', () {
    final draft = PatternListing.fromMap({
      'id': 'd1',
      'author_id': 'a',
      'name': 'Brouillon',
      'price': 10,
      'is_published': false,
      'is_draft': true,
      'archived': false,
    });
    expect(draft.statusLabelFr, 'Brouillon');
    expect(draft.isLive, isFalse);

    final archived = PatternListing.fromMap({
      'id': 'a1',
      'author_id': 'a',
      'name': 'Archivé',
      'price': 10,
      'is_published': true,
      'is_draft': false,
      'archived': true,
    });
    expect(archived.statusLabelFr, 'Archivé');
  });

  test('PatternListingInput conserve les champs du formulaire', () {
    const input = PatternListingInput(
      name: '  Robe Albane  ',
      price: 11.9,
      description: 'Romantique',
      coverImageUrl: 'https://example.com/p.jpg',
      type: 'Dress',
      isPublished: true,
    );
    expect(input.name.trim(), 'Robe Albane');
    expect(input.price, 11.9);
    expect(input.type, 'Dress');
    expect(input.isPublished, isTrue);
  });
}
