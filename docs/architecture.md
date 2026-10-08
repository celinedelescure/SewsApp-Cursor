# Architecture — SewsApp Flutter

## Stack

| Couche | Choix |
|--------|--------|
| Client | Flutter (iOS + Android ; web pour smoke local) |
| Backend | **Supabase seul** (Auth, Postgres, Storage, Realtime, Edge Functions) |
| Paiements | Stripe Connect Express — Edge Functions `create-checkout-session` + `stripe-webhook` |
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
- `feed` — fil `posts` + auteur (`profiles!author_id`), publication, pull-to-refresh, filtres type
- `patterns` — marketplace patrons (`patterns` + achats `purchases`)
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

## Feed (cette version)

- Source : table `posts` (anon), join `author:profiles!author_id`
- Affiche : image (`image_url` / `images`), auteur, caption ou patron, likes
- États FR : chargement, vide, erreur + pull-to-refresh
- Filtres simples sur `type` (Dress, Top, …) — stub avancé plus tard

## Publication (cette version)

- Écran **Publier un projet** (FAB / + sur le feed)
- Insert `posts` avec `author_id` = utilisateur connecté
- Mapping champs UI → colonnes réelles :
  - Titre → `pattern_name`
  - Légende → `caption`
  - Description → `modifications` (pas de colonne `description`)
  - Type → `type`
  - Image → `image_url` + `images[]`
- Storage prod : bucket **`sewsapp-images`** (préfixe `posts/`) — pas de bucket nommé `posts`
- Upload image optionnel ; si RLS refuse → message FR + champ URL
- Après succès : retour au feed + refresh

## Patrons / marketplace (cette version)

- Onglet **Patrons** (couturière) / **Mes patrons** (designer)
- Lecture catalogue : `patterns` filtrés `is_published=true`, `is_draft=false`, `archived=false`
- Join auteur `profiles!author_id` (username / display_name)
- Fiche détail : image, prix, description, type, difficulté
- Achats : lecture `purchases` (RLS = souvent seulement les siens) + `profiles.purchased_pattern_ids` → badge **Possédé**
- **Acheter** : `StripeCheckoutService` → Edge Function `create-checkout-session` → ouverture URL Checkout (`url_launcher`)
- Si secrets / deploy manquants : dialog FR **Paiement en mode test** (code `stripe_not_configured`) — pas d’insert fake
- Designer : liste `author_id = moi` + formulaire créer/éditer (nom, prix, description, URL couverture, type, publié/brouillon)
- Insert/update `patterns` sous session utilisateur ; RLS peut refuser selon le compte

### Stripe Connect (cette version)

1. Edge Function `create-checkout-session` : prix lu en DB, JWT utilisateur, `application_fee_amount` sur **HT** (TVA 20 %), `transfer_data.destination` = `profiles.stripe_account_id`
2. Commission : `profiles.commission_rate` (défaut 20 ; founding 10) — voir `lib/core/constants/commission.dart`
3. Edge Function `stripe-webhook` : `checkout.session.completed` → `purchases`, `purchased_pattern_ids`, `sales_count`, notif `SALE`
4. Secrets : `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (Supabase Dashboard) — jamais dans Flutter
5. Doc ops : [`supabase/README.md`](../supabase/README.md)

## Prochaines phases

1. Déployer les Edge Functions + webhook Stripe test (ops Céline)
2. Onboarding Connect Express designer (création compte / Account Link)
3. Likes, commentaires
4. Module marchand tissus
5. Staging dédié avant tout cutover schéma
