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

### Stripe — état & finition

- Secrets Edge (`sk_test_`) : **OK**  
- Checkout live (fonction V1 déjà sur `uwsz…`) : **smoke OK** (`cs_test_…`)  
- Guide finition (deploy rebuild + webhook) : [`docs/stripe-finish-5-clicks.md`](docs/stripe-finish-5-clicks.md)

**Webhook à ajouter (Stripe → Test mode → Developers → Webhooks) :**

```text
https://uwszstlhdrkxznygdloe.supabase.co/functions/v1/stripe-webhook
```

Événement : `checkout.session.completed` → copier `whsec_…` → secret Supabase `STRIPE_WEBHOOK_SECRET`.

Deploy rebuild depuis l’agent : **bloqué** (pas de `SUPABASE_ACCESS_TOKEN`) — Céline déploie en local (guide 5 étapes).

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
