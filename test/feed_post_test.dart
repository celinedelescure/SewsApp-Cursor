import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/feed/data/feed_post.dart';

void main() {
  test('FeedPost.fromMap lit auteur join + image', () {
    final post = FeedPost.fromMap({
      'id': 'p1',
      'author_id': 'u1',
      'caption': 'Mon top en lin',
      'image_url': 'https://example.com/a.jpg',
      'images': ['https://example.com/b.jpg'],
      'likes_count': 3,
      'pattern_name': 'Riley',
      'pattern_brand': 'Les Patronnes',
      'category': 'Women',
      'type': 'Top',
      'created_at': '2026-09-21T18:15:23.209607+00:00',
      'author': {
        'username': 'marie',
        'display_name': 'Marie',
        'avatar_url': 'https://example.com/av.jpg',
      },
    });

    expect(post.authorLabel, 'Marie');
    expect(post.primaryImageUrl, 'https://example.com/a.jpg');
    expect(post.titleText, 'Mon top en lin');
    expect(post.hasCaption, isTrue);
    expect(post.likesCount, 3);
    expect(post.type, 'Top');
  });

  test('sans caption → titre patron ; sans image_url → images[]', () {
    final post = FeedPost.fromMap({
      'id': 'p2',
      'author_id': 'u2',
      'caption': '',
      'image_url': '',
      'images': ['https://example.com/c.jpg'],
      'likes_count': 0,
      'pattern_name': 'Katrice',
      'pattern_brand': 'Schnittmuster',
      'created_at': '2026-10-01T19:22:50.198916+00:00',
      'author': {'username': 'Elisa', 'display_name': null, 'avatar_url': null},
    });

    expect(post.authorLabel, 'Elisa');
    expect(post.primaryImageUrl, 'https://example.com/c.jpg');
    expect(post.titleText, 'Katrice · Schnittmuster');
    expect(post.hasCaption, isFalse);
  });

  test('fallback auteur et titre si champs vides', () {
    final post = FeedPost.fromMap({
      'id': 'p3',
      'author_id': 'u3',
      'caption': '   ',
      'created_at': 'not-a-date',
      'author': null,
    });

    expect(post.authorLabel, 'Couturière');
    expect(post.titleText, 'Création cousue');
    expect(post.primaryImageUrl, isNull);
  });
}
