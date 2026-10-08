import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/core/roles/user_role.dart';
import 'package:sewsapp/features/patterns/data/pattern_listing.dart';
import 'package:sewsapp/features/patterns/data/pattern_purchase.dart';
import 'package:sewsapp/features/patterns/data/patterns_repository.dart';
import 'package:sewsapp/features/patterns/data/stripe_checkout_service.dart';
import 'package:sewsapp/features/patterns/presentation/pattern_detail_screen.dart';

class _FakePatternsSource implements PatternsSource {
  _FakePatternsSource(this.pattern);

  final PatternListing pattern;

  @override
  Future<List<PatternListing>> fetchPublishedCatalog({String? typeFilter}) async =>
      [pattern];

  @override
  Future<List<PatternListing>> fetchDesignerPatterns(String authorId) async =>
      [pattern];

  @override
  Future<PatternListing> fetchById(String id) async => pattern;

  @override
  Future<PatternListing> createPattern(PatternListingInput input) {
    throw UnimplementedError();
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

class _StubCheckout implements PatternCheckout {
  _StubCheckout(this.result);

  final CheckoutResult result;
  int createCalls = 0;
  String? lastOpenedUrl;

  @override
  Future<CheckoutResult> createCheckoutSession({
    required String patternId,
    String? successUrl,
    String? cancelUrl,
  }) async {
    createCalls++;
    return result;
  }

  @override
  Future<bool> openCheckoutUrl(String url) async {
    lastOpenedUrl = url;
    return true;
  }
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required PatternListing sample,
  required PatternCheckout checkout,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: PatternDetailScreen(
        patternId: sample.id,
        role: UserRole.couturiere,
        initialPattern: sample,
        source: _FakePatternsSource(sample),
        checkout: checkout,
      ),
    ),
  );
  await tester.pumpAndSettle();

  final buy = find.text('Acheter');
  await tester.ensureVisible(buy);
  await tester.pumpAndSettle();
}

void main() {
  final sample = PatternListing(
    id: 'pat-1',
    authorId: 'designer-1',
    name: 'Chemise Nicole',
    price: 13,
    brand: 'Atelier',
    type: 'Shirt',
    isPublished: true,
  );

  testWidgets('Acheter affiche mode test si Stripe indisponible', (tester) async {
    final checkout = _StubCheckout(
      const CheckoutUnavailable(
        'Stripe non configuré : ajoutez STRIPE_SECRET_KEY',
        code: 'stripe_not_configured',
      ),
    );

    await _pumpDetail(tester, sample: sample, checkout: checkout);

    await tester.tap(find.text('Acheter'));
    await tester.pumpAndSettle();

    expect(checkout.createCalls, 1);
    expect(find.text('Paiement en mode test'), findsOneWidget);
    expect(find.textContaining('STRIPE_SECRET_KEY'), findsOneWidget);
    expect(find.textContaining('Aucun achat fictif'), findsOneWidget);

    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();
  });

  testWidgets('Acheter affiche erreur métier FR', (tester) async {
    final checkout = _StubCheckout(
      const CheckoutFailure(
        'Vous possédez déjà ce patron.',
        code: 'already_owned',
      ),
    );

    await _pumpDetail(tester, sample: sample, checkout: checkout);

    await tester.tap(find.text('Acheter'));
    await tester.pumpAndSettle();

    expect(find.text('Achat impossible'), findsOneWidget);
    expect(find.textContaining('possédez déjà'), findsOneWidget);
  });

  testWidgets('Acheter ouvre l’URL Checkout quand disponible', (tester) async {
    final checkout = _StubCheckout(
      const CheckoutRedirect(
        url: 'https://checkout.stripe.com/c/pay/cs_test_demo',
        sessionId: 'cs_test_demo',
        connectMode: 'destination',
        commissionPercent: 10,
      ),
    );

    await _pumpDetail(tester, sample: sample, checkout: checkout);

    await tester.tap(find.text('Acheter'));
    await tester.pumpAndSettle();

    expect(checkout.createCalls, 1);
    expect(checkout.lastOpenedUrl, 'https://checkout.stripe.com/c/pay/cs_test_demo');
    expect(find.textContaining('Paiement ouvert'), findsOneWidget);
  });
}
