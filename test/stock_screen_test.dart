import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/roles/user_role.dart';
import 'package:sewsapp/features/patterns/data/pattern_listing.dart';
import 'package:sewsapp/features/patterns/data/pattern_purchase.dart';
import 'package:sewsapp/features/patterns/data/patterns_repository.dart';
import 'package:sewsapp/features/profile/presentation/stock_screen.dart';

class _FakePatternsSource implements PatternsSource {
  _FakePatternsSource({this.purchases = const [], this.error});

  final List<PatternPurchase> purchases;
  final PatternsFailure? error;

  @override
  Future<List<PatternListing>> fetchPublishedCatalog({String? typeFilter}) =>
      Future.value(const []);

  @override
  Future<List<PatternListing>> fetchDesignerPatterns(String authorId) =>
      Future.value(const []);

  @override
  Future<PatternListing> fetchById(String id) {
    throw UnimplementedError();
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
  Future<List<PatternPurchase>> fetchMyPurchases() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (error != null) throw error!;
    return purchases;
  }

  @override
  Future<Set<String>> fetchPurchasedPatternIds() async =>
      purchases.map((p) => p.patternId).toSet();
}

void main() {
  testWidgets('Stock vide affiche l’état empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StockScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucun patron dans votre stock'), findsOneWidget);
    expect(find.textContaining('tissus arrivent plus tard'), findsOneWidget);
  });

  testWidgets('Stock liste les patrons achetés', (tester) async {
    final purchases = [
      PatternPurchase(
        id: 'p1',
        userId: 'u1',
        patternId: 'pat-1',
        patternName: 'Robe Alba',
        brand: 'Maison Test',
        pricePaid: 12,
        purchasedAt: DateTime.utc(2026, 4, 8),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StockScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(purchases: purchases),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Patrons achetés (1)'), findsOneWidget);
    expect(find.text('Robe Alba'), findsOneWidget);
    expect(find.text('Maison Test'), findsOneWidget);
    expect(find.text('Possédé'), findsOneWidget);
    expect(find.text('12 EUR'), findsOneWidget);
  });

  testWidgets('Stock affiche l’erreur et Réessayer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StockScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(
            error: const PatternsFailure('Accès refusé aux achats.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accès refusé aux achats.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
