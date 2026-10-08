import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/patterns/data/pattern_listing.dart';
import 'package:sewsapp/features/patterns/data/pattern_purchase.dart';
import 'package:sewsapp/features/patterns/data/patterns_repository.dart';
import 'package:sewsapp/features/patterns/presentation/pattern_edit_screen.dart';

class _RecordingPatternsSource implements PatternsSource {
  PatternListingInput? lastCreate;

  @override
  Future<List<PatternListing>> fetchPublishedCatalog({String? typeFilter}) async =>
      const [];

  @override
  Future<List<PatternListing>> fetchDesignerPatterns(String authorId) async =>
      const [];

  @override
  Future<PatternListing> fetchById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<PatternListing> createPattern(PatternListingInput input) async {
    lastCreate = input;
    return PatternListing(
      id: 'new-1',
      authorId: 'd1',
      name: input.name.trim(),
      price: input.price,
      description: input.description,
      coverImage: input.coverImageUrl,
      type: input.type,
      isPublished: input.isPublished,
      isDraft: !input.isPublished,
    );
  }

  @override
  Future<PatternListing> updatePattern(String id, PatternListingInput input) {
    throw UnimplementedError();
  }

  @override
  Future<List<PatternPurchase>> fetchMyPurchases() async => const [];

  @override
  Future<Set<String>> fetchPurchasedPatternIds() async => {};
}

Future<void> _tapSubmit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Créer le patron');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('formulaire crée un patron avec nom et prix', (tester) async {
    final source = _RecordingPatternsSource();
    PatternListing? popped;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push<PatternListing>(
                    MaterialPageRoute(
                      builder: (_) => PatternEditScreen(source: source),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau patron'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Robe Test');
    await tester.enterText(find.byType(TextFormField).at(1), '12.5');
    await _tapSubmit(tester);

    expect(source.lastCreate, isNotNull);
    expect(source.lastCreate!.name, 'Robe Test');
    expect(source.lastCreate!.price, 12.5);
    expect(popped?.name, 'Robe Test');
  });

  testWidgets('validation FR si nom vide', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatternEditScreen(source: _RecordingPatternsSource()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await _tapSubmit(tester);

    expect(find.text('Le nom est obligatoire.'), findsOneWidget);
  });
}
