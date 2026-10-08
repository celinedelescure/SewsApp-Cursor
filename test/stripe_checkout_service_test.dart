import 'package:flutter_test/flutter_test.dart';
import 'package:sewsapp/features/patterns/data/stripe_checkout_service.dart';
import 'package:sewsapp/features/patterns/data/pattern_purchase.dart';

void main() {
  test('PatternPurchase accepte brand ou pattern_brand', () {
    final a = PatternPurchase.fromMap({
      'id': '1',
      'user_id': 'u',
      'pattern_id': 'p',
      'pattern_name': 'Robe',
      'brand': 'Atelier',
      'price_paid': 12.0,
    });
    expect(a.brand, 'Atelier');

    final b = PatternPurchase.fromMap({
      'id': '2',
      'user_id': 'u',
      'pattern_id': 'p',
      'pattern_name': 'Robe',
      'pattern_brand': 'Studio',
      'price_paid': 12.0,
    });
    expect(b.brand, 'Studio');
  });

  test('CheckoutResult types exposent messages FR utiles', () {
    const unavailable = CheckoutUnavailable(
      'Stripe non configuré',
      code: 'stripe_not_configured',
    );
    expect(unavailable.code, 'stripe_not_configured');
    expect(unavailable.message, contains('Stripe'));

    const failure = CheckoutFailure('Vous possédez déjà ce patron.', code: 'already_owned');
    expect(failure.code, 'already_owned');

    const redirect = CheckoutRedirect(
      url: 'https://checkout.stripe.com/c/pay/cs_test_x',
      sessionId: 'cs_test_x',
      connectMode: 'destination',
      commissionPercent: 10,
    );
    expect(redirect.url, startsWith('https://checkout.stripe.com'));
    expect(redirect.commissionPercent, 10);
  });

  test('nom de fonction Edge stable', () {
    expect(StripeCheckoutService.functionName, 'create-checkout-session');
  });
}
