import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/roles/user_role.dart';
import 'package:sewsapp/features/auth/data/user_profile.dart';
import 'package:sewsapp/features/patterns/data/pattern_listing.dart';
import 'package:sewsapp/features/patterns/data/pattern_purchase.dart';
import 'package:sewsapp/features/patterns/data/patterns_repository.dart';
import 'package:sewsapp/features/patterns/presentation/patterns_marketplace_screen.dart';

class _FakePatternsSource implements PatternsSource {
  _FakePatternsSource({
    this.catalog = const [],
    this.designer = const [],
    this.purchases = const [],
    this.ownedIds = const {},
    this.error,
  });

  final List<PatternListing> catalog;
  final List<PatternListing> designer;
  final List<PatternPurchase> purchases;
  final Set<String> ownedIds;
  final PatternsFailure? error;

  @override
  Future<List<PatternListing>> fetchPublishedCatalog({String? typeFilter}) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (error != null) throw error!;
    if (typeFilter == null || typeFilter.isEmpty) return catalog;
    return catalog.where((p) => p.type == typeFilter).toList();
  }

  @override
  Future<List<PatternListing>> fetchDesignerPatterns(String authorId) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (error != null) throw error!;
    return designer.where((p) => p.authorId == authorId).toList();
  }

  @override
  Future<PatternListing> fetchById(String id) async {
    final all = [...catalog, ...designer];
    return all.firstWhere((p) => p.id == id);
  }

  @override
  Future<PatternListing> createPattern(PatternListingInput input) {
    throw UnimplementedError();
  }

  @override
  Future<PatternListing> updatePattern(String id, PatternListingInput input) {
    throw UnimplementedError();
  }

  @override
  Future<List<PatternPurchase>> fetchMyPurchases() async => purchases;

  @override
  Future<Set<String>> fetchPurchasedPatternIds() async => ownedIds;
}

PatternListing _sample({
  String id = '1',
  String name = 'Chemise Nicole',
  String authorId = 'designer-1',
  String? type = 'Shirt',
}) {
  return PatternListing(
    id: id,
    authorId: authorId,
    name: name,
    price: 13,
    brand: 'Atelier',
    type: type,
    coverImage: null,
    isPublished: true,
  );
}

void main() {
  testWidgets('catalogue couturière affiche les patrons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatternsMarketplaceScreen(
          role: UserRole.couturiere,
          profile: UserProfile.fallback(id: 'u1'),
          source: _FakePatternsSource(catalog: [_sample()]),
        ),
      ),
    );

    expect(find.text('Chargement des patrons…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Patrons'), findsOneWidget);
    expect(find.text('Chemise Nicole'), findsOneWidget);
    expect(find.textContaining('13'), findsWidgets);
  });

  testWidgets('état vide FR', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatternsMarketplaceScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(catalog: const []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun patron publié'), findsOneWidget);
  });

  testWidgets('état erreur FR', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatternsMarketplaceScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(
            error: const PatternsFailure('Réseau indisponible.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réseau indisponible.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('designer voit Mes patrons + FAB Nouveau', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatternsMarketplaceScreen(
          role: UserRole.designer,
          profile: const UserProfile(
            id: 'designer-1',
            role: UserRole.designer,
            accountType: 'Designer',
          ),
          source: _FakePatternsSource(
            designer: [_sample(name: 'Mon patron')],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes patrons'), findsOneWidget);
    expect(find.text('Mon patron'), findsOneWidget);
    expect(find.text('Nouveau'), findsOneWidget);
  });

  testWidgets('affiche badge Possédé si acheté', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PatternsMarketplaceScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(
            catalog: [_sample(id: 'owned-1')],
            ownedIds: {'owned-1'},
            purchases: [
              const PatternPurchase(
                id: 'pur-1',
                userId: 'u1',
                patternId: 'owned-1',
                patternName: 'Chemise Nicole',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Possédé'), findsOneWidget);
    expect(find.text('Mes achats'), findsOneWidget);
  });
}
