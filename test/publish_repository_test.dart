import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/feed/data/publish_repository.dart';

void main() {
  test('PublishProjectInput conserve titre / caption / description', () {
    const input = PublishProjectInput(
      title: '  Venice  ',
      caption: 'Essai',
      description: 'Ourlets plus courts',
      type: 'Dress',
      imageUrl: 'https://example.com/p.jpg',
    );

    expect(input.title.trim(), 'Venice');
    expect(input.caption, 'Essai');
    expect(input.description, 'Ourlets plus courts');
    expect(input.type, 'Dress');
    expect(input.imageUrl, 'https://example.com/p.jpg');
  });

  test('bucket Storage prod = sewsapp-images (préfixe posts/)', () {
    expect(PublishRepository.storageBucket, 'sewsapp-images');
    expect(PublishRepository.storagePrefix, 'posts');
  });
}
