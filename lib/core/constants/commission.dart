/// Commission SewsApp sur les ventes designers (HT, TVA 20 % côté Stripe).
///
/// Aligné V1 / décisions rebuild : founding 10 %, standard 20 %.
/// Formule serveur (Edge Function) : `fee = round(round(TTC_cents / 1.20) * rate)`.
abstract final class DesignerCommission {
  /// Premiers designers « founding » (règle produit : 20 premières).
  static const foundingRatePercent = 10;

  /// Commission standard après le quota founding.
  static const standardRatePercent = 20;

  /// Nombre de designers founding (à confirmer côté données live).
  static const foundingQuota = 20;

  /// TVA numérique FR (biens digitaux) — diviseur TTC → HT.
  static const digitalVatDivisor = 1.20;

  /// `application_fee_amount` en centimes (même logique que l’Edge Function).
  static int applicationFeeCents(
    int priceTtcCents, {
    num commissionPercent = standardRatePercent,
  }) {
    final rate = commissionPercent / 100;
    final priceHtCents = (priceTtcCents / digitalVatDivisor).round();
    return (priceHtCents * rate).round();
  }
}
