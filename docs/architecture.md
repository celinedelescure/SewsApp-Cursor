# Architecture — SewsApp Flutter

## Stack

| Couche | Choix |
|--------|--------|
| Client | Flutter (iOS + Android ; web pour smoke local) |
| Backend | **Supabase seul** (Auth, Postgres, Storage, Realtime, Edge Functions) |
| Paiements | Stripe Connect Express (patrons + tissus) — pas encore branché |
| Cloudflare | Non |

Greenfield : **pas** de reprise du code React/Capacitor V1.

## Auth (cette version)

- Init : `Supabase.initialize` avec `SUPABASE_URL` + `SUPABASE_ANON_KEY` via `--dart-define`
- Login / signup e-mail + mot de passe (`AuthRepository`)
- Restauration de session au démarrage (`onAuthStateChange` + stockage SDK)
- Rôle lu depuis `profiles.account_type` (`Regular User` → Couturière, `Designer`, `Seller` → Marchand)
- Déconnexion depuis l’écran Profil
- **Jamais** de clé `service_role` côté client

## Organisation du code

Feature-first sous `lib/features/` :

- `auth` — login, signup, gate session, repository
- `feed` — projets & inspiration (placeholder)
- `patterns` — marketplace patrons PDF (placeholder)
- `fabric_merchant` — catalogue tissus (placeholder)
- `profile` — profil + stock + logout

`lib/core/` : config (`Env`), client Supabase, thème, enum rôles, constantes commission.

`lib/shell/` : `AppShell` avec `NavigationBar` selon le `UserRole`.

## Config secrets

- Préféré : `--dart-define=SUPABASE_URL` / `SUPABASE_ANON_KEY`
- Doc : `.env.example` (pas de `.env` dans git)
- Sans clés : écran « configuration manquante »

Prod données : projet Supabase `uwszstlhdrkxznygdloe`.

## Rôles & commission

- **Couturière** · **Designer** · **Marchand tissus**
- Designers : 10 % founding (quota 20) / 20 % standard — `lib/core/constants/commission.dart`

## Prochaines phases

1. Feed / stock / marketplace branchés sur les tables prod
2. Edge Functions Stripe
3. Module marchand tissus
4. Staging dédié avant tout cutover schéma
