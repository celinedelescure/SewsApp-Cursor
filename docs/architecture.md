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
- `feed` — fil `posts` + auteur (`profiles!author_id`), publication, pull-to-refresh, filtres type
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

## Prochaines phases

1. Stock / marketplace branchés sur les tables prod
2. Likes, commentaires
3. Edge Functions Stripe
4. Module marchand tissus
5. Staging dédié avant tout cutover schéma
