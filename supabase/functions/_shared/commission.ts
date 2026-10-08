/**
 * Commission SewsApp sur le prix HT (TVA numérique FR 20 %).
 * Aligné V1 : founding 10 % / standard 20 % via `profiles.commission_rate`.
 */
export const DIGITAL_VAT_RATE = 1.2;
export const DEFAULT_COMMISSION_PERCENT = 20;

export function priceToCents(price: number): number {
  return Math.round(Number(price) * 100);
}

/** Commission plateforme en centimes, calculée sur le HT. */
export function applicationFeeCents(
  priceTtcCents: number,
  commissionPercent: number | null | undefined,
): number {
  const rate = (commissionPercent ?? DEFAULT_COMMISSION_PERCENT) / 100;
  const priceHtCents = Math.round(priceTtcCents / DIGITAL_VAT_RATE);
  return Math.round(priceHtCents * rate);
}
