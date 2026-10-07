/// Commission SewsApp sur les ventes designers (HT, TVA 20 % côté Stripe).
///
/// Aligné V1 / décisions rebuild : founding 10 %, standard 20 %.
abstract final class DesignerCommission {
  /// Premiers designers « founding » (règle produit : 20 premières).
  static const foundingRatePercent = 10;

  /// Commission standard après le quota founding.
  static const standardRatePercent = 20;

  /// Nombre de designers founding (à confirmer côté données live).
  static const foundingQuota = 20;
}
