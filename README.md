# SewsApp

Rebuild greenfield de [sewsapp.com](https://www.sewsapp.com) : app couture (feed, marketplace patrons, marchand de tissus) en **Flutter** + **Supabase** + **Stripe Connect**.

Cette version branche la **connexion / inscription**, le **fil d’actualité**, la **publication d’un projet**, le **catalogue patrons** et le **checkout Stripe Connect** (via Edge Functions — jamais de secret Stripe dans l’app).

## Prérequis

- [Flutter](https://docs.flutter.dev/get-started/install) stable (3.24+ recommandé)
- Un compte SewsApp existant **ou** la possibilité de créer un compte (si les inscriptions sont ouvertes dans Auth)

```bash
flutter doctor
```

## Lancer en local (simple)

1. Récupérer la clé **anon** dans le dashboard Supabase → *Project Settings* → *API*  
   (ne jamais utiliser ni coller la clé `service_role` dans l’app).
2. Dans un terminal, à la racine du projet :

```bash
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://uwszstlhdrkxznygdloe.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
```

Remplacez `VOTRE_CLE_ANON` par la clé anon (JWT ou clé publishable selon le dashboard).  
Sur téléphone / simulateur : retirez `-d chrome` ou choisissez `-d ios` / `-d android`.

Sans `--dart-define`, l’app affiche un écran « configuration manquante » (pas de secrets dans le dépôt).

Variables documentées dans [`.env.example`](.env.example) (le fichier `.env` local est ignoré par git).

## Se connecter (pour tester)

1. Lancez l’app avec les `--dart-define` ci-dessus.
2. Sur l’écran **Se connecter**, saisissez l’e-mail et le mot de passe d’un compte existant.
3. Ou appuyez sur **Créer un compte** (si Auth autorise les inscriptions).
4. Après connexion, l’onglet **Feed** charge les posts prod (`posts` + auteur `profiles`).
5. Tirez vers le bas pour actualiser ; filtres type (Robes, Hauts…) en haut.
6. Appuyez sur **Publier** (ou l’icône +) → titre / légende / description → **Publier**.  
   L’upload d’image vers Storage peut être refusé par RLS : dans ce cas, collez une **URL** d’image ou publiez sans photo.
7. Onglet **Patrons** → fiche → **Acheter** : appelle l’Edge Function `create-checkout-session` puis ouvre Stripe Checkout.  
   Si les secrets Stripe / le déploiement manquent, l’UI affiche **Paiement en mode test** (aucun achat fictif en base).
8. Compte **Designer** → onglet **Mes patrons** : liste + **Nouveau**.
9. Onglet **Profil** → **Se déconnecter**.

| Valeur en base (`account_type`) | Affiché dans l’app |
|---------------------------------|--------------------|
| `Regular User` | Couturière |
| `Designer` | Designer |
| `Seller` | Marchand de tissus |

## Stripe Connect (checkout patrons)

- **Client Flutter** : clé anon uniquement → `functions.invoke('create-checkout-session')` → `url_launcher`
- **Serveur** : Edge Functions dans [`supabase/`](supabase/README.md)
  - `create-checkout-session` — Checkout + `application_fee` sur **HT** (TVA 20 %), Connect Express
  - `stripe-webhook` — `checkout.session.completed` → `purchases` + `purchased_pattern_ids`
- Commission : **10 %** founding / **20 %** standard (`profiles.commission_rate`)

### Secrets Supabase (pas dans Flutter)

**Utilisez le mode Test Stripe** (interrupteur Dashboard → Test mode) : clés `sk_test_` / `pk_test_`.  
Les clés **live** (`sk_live_`) débitent de vrais clients — hors scope tant que le parcours n’est pas validé.

Dashboard Supabase → Edge Functions → Secrets (projet `uwszstlhdrkxznygdloe`) :

1. `STRIPE_SECRET_KEY` = `sk_test_…`
2. `STRIPE_WEBHOOK_SECRET` = `whsec_…` (endpoint créé **en Test**)
3. `SITE_URL` = `https://www.sewsapp.com` (recommandé)

Puis déployer (voir [`supabase/README.md`](supabase/README.md)) et créer le webhook Stripe **test** vers  
`https://uwszstlhdrkxznygdloe.supabase.co/functions/v1/stripe-webhook`  
(événement `checkout.session.completed`).

`STRIPE_PUBLISHABLE_KEY` (`pk_test_…`) — optionnel pour ce Checkout redirect.

**Note agents Cursor :** les secrets saisis dans l’UI Cursor ne s’injectent que si un *Cloud environment* est lié. Sans cela, le code + README suffisent ; Céline configure les secrets **dans Supabase** (ou colle un `sk_test_` en chat si besoin de deploy depuis l’agent).

## Structure

```
lib/
  core/           # config (--dart-define), client Supabase, thème, rôles, commission
  features/
    auth/         # login, signup, session, lecture profiles
    feed/         # fil posts + publier un projet + filtres type
    patterns/     # catalogue + détail + checkout Stripe + fiche designer
    fabric_merchant/
    profile/      # profil + déconnexion + stock
  shell/          # NavigationBar selon le rôle
supabase/
  functions/      # create-checkout-session, stripe-webhook
docs/architecture.md
```

## Hors scope de ce PR

Likes/commentaires, onboarding Connect Express designer (création de compte), module marchand tissus, migration schéma prod.
