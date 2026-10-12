import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/feed/data/feed_post.dart';
import 'package:sewsapp/features/feed/data/feed_repository.dart';
import 'package:sewsapp/features/feed/data/publish_repository.dart';
import 'package:sewsapp/features/feed/presentation/publish_project_screen.dart';

class _FakePublishSource implements PublishSource {
  _FakePublishSource({this.failWith});

  final FeedFailure? failWith;
  PublishProjectInput? lastInput;

  @override
  Future<FeedPost> createPost(PublishProjectInput input) async {
    lastInput = input;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failWith != null) throw failWith!;
    return FeedPost(
      id: 'new-1',
      authorId: 'u1',
      createdAt: DateTime.utc(2026, 10, 8),
      caption: input.caption,
      patternName: input.title,
      imageUrl: input.imageUrl,
      type: input.type,
    );
  }

  @override
  Future<String?> uploadPostImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    return null;
  }
}

Finder get _publishButton => find.widgetWithText(FilledButton, 'Publier');

Future<void> _prepareTallSurface(WidgetTester tester) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tapPublish(WidgetTester tester) async {
  await tester.ensureVisible(_publishButton);
  await tester.pumpAndSettle();
  await tester.tap(_publishButton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('validation : titre ou légende requis', (tester) async {
    await _prepareTallSurface(tester);
    final fake = _FakePublishSource();
    await tester.pumpWidget(
      MaterialApp(home: PublishProjectScreen(source: fake)),
    );

    await _tapPublish(tester);

    expect(find.text('Titre ou légende requis'), findsOneWidget);
    expect(fake.lastInput, isNull);
  });

  testWidgets('succès : pop avec le post créé', (tester) async {
    await _prepareTallSurface(tester);
    final fake = _FakePublishSource();
    FeedPost? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<FeedPost>(
                      MaterialPageRoute(
                        builder: (_) => PublishProjectScreen(source: fake),
                      ),
                    );
                  },
                  child: const Text('Ouvrir'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Robe d’essai');
    await tester.enterText(fields.at(1), 'Première couture');
    await _tapPublish(tester);

    expect(result, isNotNull);
    expect(result!.patternName, 'Robe d’essai');
    expect(fake.lastInput?.title, 'Robe d’essai');
    expect(fake.lastInput?.caption, 'Première couture');
  });

  testWidgets('affiche l’erreur FR si publication échoue', (tester) async {
    await _prepareTallSurface(tester);
    final fake = _FakePublishSource(
      failWith: const FeedFailure('Publication refusée (droits insuffisants).'),
    );

    await tester.pumpWidget(
      MaterialApp(home: PublishProjectScreen(source: fake)),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Test');
    await _tapPublish(tester);

    expect(
      find.text('Publication refusée (droits insuffisants).'),
      findsOneWidget,
    );
  });
}
