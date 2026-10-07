# Architecture — SewsApp Flutter (scaffold)

## Stack

| Couche | Choix |
|--------|--------|
| Client | Flutter (iOS + Android ; web pour smoke local) |
| Backend | **Supabase seul** (Auth, Postgres, Storage, Realtime, Edge Functions) |
| Paiements | Stripe Connect Express (patrons + tissus) |
| Cloudflare | Non |

Greenfield : **pas** de reprise du code React/Capacitor V1.

## Organisation du code

Feature-first sous `lib/features/` :

- `auth` — entrée / rôles (auth Supabase à brancher)
- `feed` — projets & inspiration
- `patterns` — marketplace patrons PDF
- `fabric_merchant` — catalogue & ventes tissus natives
- `profile` — profil + stock personnel couturière

`lib/core/` : config (`Env` via `--dart-define`), client Supabase, thème, enum rôles, constantes commission.

`lib/shell/` : `AppShell` avec `NavigationBar` dont les destinations dépendent du `UserRole`.

## Config secrets

- Préféré : `--dart-define=SUPABASE_URL` / `SUPABASE_ANON_KEY`
- Doc : `.env.example` (pas de `.env` dans git)
- Sans clés : app démarre, banner « mode placeholder », pas d’appels API

Données prod actuelles : projet Supabase `pbeyfeepdrlfjxanvvwa` — **conservation / migration plus tard**, pas dans ce scaffold.

## Rôles & commission

- **Couturière** · **Designer** · **Marchand tissus** (vente native Stripe, pas Shopify V1)
- Designers : 10 % founding (quota 20) / 20 % standard — `lib/core/constants/commission.dart`

## Prochaines phases (hors scaffold)

1. Schema Supabase cible + RLS (rôles marchand inclus)
2. Auth & profils
3. Feed / stock / marketplace patrons + Edge Functions Stripe
4. Module marchand tissus
5. Migration données & cutover
