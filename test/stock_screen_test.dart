import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/roles/user_role.dart';
import 'package:sewsapp/features/patterns/data/pattern_listing.dart';
import 'package:sewsapp/features/patterns/data/pattern_purchase.dart';
import 'package:sewsapp/features/patterns/data/patterns_repository.dart';
import 'package:sewsapp/features/profile/data/fabric_item.dart';
import 'package:sewsapp/features/profile/data/fabrics_repository.dart';
import 'package:sewsapp/features/profile/presentation/stock_screen.dart';

class _FakePatternsSource implements PatternsSource {
  _FakePatternsSource({this.purchases = const []});

  final List<PatternPurchase> purchases;

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
    return purchases;
  }

  @override
  Future<Set<String>> fetchPurchasedPatternIds() async =>
      purchases.map((p) => p.patternId).toSet();
}

class _FakeFabricsSource implements FabricsSource {
  _FakeFabricsSource({this.fabrics = const [], this.error});

  final List<FabricItem> fabrics;
  final FabricsFailure? error;
  final List<FabricItemInput> added = [];

  @override
  Future<List<FabricItem>> fetchMyFabrics() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (error != null) throw error!;
    return fabrics;
  }

  @override
  Future<FabricItem> addFabric(FabricItemInput input) async {
    added.add(input);
    return FabricItem(
      id: 'new-${added.length}',
      userId: 'u1',
      name: input.name,
      type: input.type,
      color: input.color,
      length: input.length,
    );
  }
}

void main() {
  testWidgets('Stock vide affiche l’état empty tissus + patrons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StockScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(),
          fabricsSource: _FakeFabricsSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre stock est vide'), findsOneWidget);
    expect(find.text('Ajouter un tissu'), findsWidgets);
  });

  testWidgets('Stock liste tissus et patrons achetés', (tester) async {
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
    final fabrics = [
      const FabricItem(
        id: 'f1',
        userId: 'u1',
        name: 'Lin lavé ivoire',
        type: 'Lin',
        color: 'ivoire',
        length: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StockScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(purchases: purchases),
          fabricsSource: _FakeFabricsSource(fabrics: fabrics),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes tissus (1)'), findsOneWidget);
    expect(find.text('Lin lavé ivoire'), findsOneWidget);
    expect(find.text('Patrons achetés (1)'), findsOneWidget);
    expect(find.text('Robe Alba'), findsOneWidget);
    expect(find.text('Possédé'), findsOneWidget);
  });

  testWidgets('Stock affiche l’erreur tissus et Réessayer', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StockScreen(
          role: UserRole.couturiere,
          source: _FakePatternsSource(),
          fabricsSource: _FakeFabricsSource(
            error: const FabricsFailure('Accès refusé au stock tissus.'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accès refusé au stock tissus.'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });
}
