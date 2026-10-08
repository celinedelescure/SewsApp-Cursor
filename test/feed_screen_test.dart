import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/roles/user_role.dart';
import 'package:sewsapp/features/feed/data/feed_post.dart';
import 'package:sewsapp/features/feed/data/feed_repository.dart';
import 'package:sewsapp/features/feed/presentation/feed_screen.dart';

class _FakeFeedSource implements FeedSource {
  _FakeFeedSource(this._posts, {this.error});

  final List<FeedPost> _posts;
  final FeedFailure? error;

  @override
  Future<List<FeedPost>> fetchPosts({String? typeFilter}) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (error != null) throw error!;
    if (typeFilter == null || typeFilter.isEmpty) return _posts;
    return _posts.where((p) => p.type == typeFilter).toList();
  }
}

void main() {
  final sample = [
    FeedPost(
      id: '1',
      authorId: 'a',
      createdAt: DateTime.utc(2026, 10, 1),
      caption: 'Belle robe d’été',
      authorDisplayName: 'Camille',
      type: 'Dress',
    ),
  ];

  testWidgets('affiche les posts après chargement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          role: UserRole.couturiere,
          source: _FakeFeedSource(sample),
        ),
      ),
    );

    expect(find.text('Chargement du fil…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Belle robe d’été'), findsOneWidget);
    expect(find.text('Camille'), findsOneWidget);
    expect(find.textContaining('Couturière'), findsOneWidget);
  });

  testWidgets('affiche l’état vide en français', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          role: UserRole.designer,
          source: _FakeFeedSource(const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun post pour le moment'), findsOneWidget);
  });

  testWidgets('affiche l’état erreur en français', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FeedScreen(
          role: UserRole.couturiere,
          source: _FakeFeedSource(
            const [],
            error: const FeedFailure('Réseau indisponible.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Oups, une erreur est survenue'), findsOneWidget);
    expect(find.text('Réseau indisponible.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
