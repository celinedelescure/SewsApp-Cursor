# Finir Stripe checkout en 5 étapes (Céline)

Secrets Edge déjà OK (`STRIPE_SECRET_KEY` test). Il reste **déployer** les fonctions + **webhook**.

## 1. Créer un access token Supabase (CLI)

1. Ouvrir https://supabase.com/dashboard/account/tokens  
2. **Generate new token** → nom `sewsapp-deploy` → copier le token (une seule fois).

> L’agent Cloud n’a **pas** ce token → impossible de déployer depuis ici sans que vous le colliez (ou que vous déployiez en local).

## 2. Déployer les 2 fonctions

Sur votre Mac, depuis le repo (branche `cursor/flutter-stripe-checkout`) :

```bash
# une fois
brew install supabase/tap/supabase   # ou voir docs CLI

export SUPABASE_ACCESS_TOKEN=sbp_…   # le token de l’étape 1
cd /chemin/vers/SewsApp-Cursor
git checkout cursor/flutter-stripe-checkout
supabase link --project-ref uwszstlhdrkxznygdloe

supabase functions deploy create-checkout-session --no-verify-jwt
supabase functions deploy stripe-webhook --no-verify-jwt
```

Vérifier dans le dashboard :  
https://supabase.com/dashboard/project/uwszstlhdrkxznygdloe/functions

## 3. Créer le webhook Stripe (mode Test)

1. Stripe Dashboard → activer **Test mode** (interrupteur en haut à droite).  
2. **Developers** → **Webhooks** → **Add endpoint**  
   (lien direct : https://dashboard.stripe.com/test/webhooks ).  
3. **Endpoint URL** (copier-coller) :

```text
https://uwszstlhdrkxznygdloe.supabase.co/functions/v1/stripe-webhook
```

4. **Events** → sélectionner `checkout.session.completed` → Add endpoint.  
5. Ouvrir l’endpoint → **Signing secret** → **Reveal** → copier `whsec_…`.

## 4. Coller `whsec_…` dans Supabase

1. https://supabase.com/dashboard/project/uwszstlhdrkxznygdloe/settings/functions  
2. **Secrets** → Add `STRIPE_WEBHOOK_SECRET` = `whsec_…` → Save.  
   (Ce n’est **pas** `rk_test_` ni `sk_test_`.)

Optionnel : `SITE_URL` = `https://www.sewsapp.com` si pas déjà là.

## 5. Tester dans l’app

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://uwszstlhdrkxznygdloe.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=VOTRE_CLE_ANON
```

Patrons → fiche → **Acheter** → page Stripe Checkout (carte test `4242…`).  
Après paiement : badge **Possédé** (webhook).

Sans compte Connect designer (`stripe_account_id`), le paiement part en mode plateforme (OK pour smoke) ; le split commission nécessite un Express onboardé.

## Blocage agent

| Élément | État |
|---------|------|
| Secrets Stripe dans Supabase | OK (confirmé Céline) |
| `SUPABASE_ACCESS_TOKEN` sur l’agent | **absent** → deploy CLI impossible depuis ici |
| Smoke Checkout API Stripe directe | OK (`cs_test_…`) |
| Smoke Edge Function déployée | **en attente** du deploy (étape 2) |
