# Supabase Edge Functions — Stripe Connect (patrons)

Deux fonctions pour l’achat de patrons PDF, alignées V1 :

| Fonction | Rôle |
|----------|------|
| `create-checkout-session` | Crée une Checkout Session Connect (`application_fee` sur **HT**, TVA 20 %) |
| `stripe-webhook` | Sur `checkout.session.completed` → `purchases` + `purchased_pattern_ids` + `sales_count` |

**Jamais** de clé secrète Stripe dans l’app Flutter — uniquement ici (secrets Supabase).

## Mode Test vs Live (important)

| Mode Stripe Dashboard | Préfixe clés | Usage rebuild |
|-----------------------|--------------|---------------|
| **Test** (recommandé) | `sk_test_` / `pk_test_` / webhook test `whsec_` | Développement Flutter + Edge Functions — **aucun vrai paiement** |
| **Live / Production** | `sk_live_` / `pk_live_` | Argent réel — **ne pas brancher** tant que le parcours n’est pas validé en Test |

**Comment basculer en Test :** Stripe Dashboard → interrupteur **Test mode** (en haut à droite) → Developers → API keys → copier `sk_test_…` et `pk_test_…`. Créer le webhook **en mode Test**.

Si seules des clés **live** ont été saisies dans Cursor Secrets : elles **n’arrivent pas** sur un agent sans environnement Cloud lié, et de toute façon le rebuild doit d’abord tourner avec `sk_test_`. Ne collez **jamais** `sk_live_` dans le chat sans validation produit explicite (vrais débits).

## Secrets à ajouter (Dashboard Supabase)

Projet cible (prod données) : `uwszstlhdrkxznygdloe`

Supabase → **Project Settings → Edge Functions → Secrets** (ou CLI `supabase secrets set`) :

| Secret | Exemple | Obligatoire |
|--------|---------|-------------|
| `STRIPE_SECRET_KEY` | `sk_test_…` (**Test**) | oui (checkout + webhook) |
| `STRIPE_WEBHOOK_SECRET` | `whsec_…` (endpoint **Test**) | oui (webhook) |
| `SITE_URL` | `https://www.sewsapp.com` | recommandé (URLs retour) |

`SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` sont injectés automatiquement par la plateforme.

Optionnel côté doc Flutter (publishable, jamais secret) : `STRIPE_PUBLISHABLE_KEY` = `pk_test_…` — non lu par ces fonctions.

## Déploiement

Prérequis : [Supabase CLI](https://supabase.com/docs/guides/cli) + login + lien projet.

```bash
# depuis la racine du repo
supabase link --project-ref uwszstlhdrkxznygdloe

supabase secrets set STRIPE_SECRET_KEY=sk_test_xxx
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxx
supabase secrets set SITE_URL=https://www.sewsapp.com

supabase functions deploy create-checkout-session --no-verify-jwt
# Le JWT est vérifié dans le code (getUser). --no-verify-jwt évite le double rejet gateway
# si vous préférez verify-jwt=true, retirez le flag et gardez Authorization + apikey.

supabase functions deploy stripe-webhook --no-verify-jwt
# Le webhook Stripe n’envoie pas de JWT Supabase : verify-jwt doit être désactivé.
```

## Webhook Stripe Dashboard

1. Activer **Test mode** dans Stripe, puis [Webhooks (test)](https://dashboard.stripe.com/test/webhooks) → **Add endpoint**
2. URL :
   `https://uwszstlhdrkxznygdloe.supabase.co/functions/v1/stripe-webhook`
3. Événement : `checkout.session.completed`
4. Copier le **Signing secret** → `STRIPE_WEBHOOK_SECRET`
5. Ne créez l’endpoint **Live** qu’après smoke test réussi en Test.

## Comptes Connect designers

Les créatrices doivent avoir `profiles.stripe_account_id` (Express) + onboarding terminé.  
Sans compte Connect, le checkout part quand même mais l’argent reste sur le compte plateforme (`connect_mode: platform`) — à corriger en prod via onboarding Connect (hors scope de ce PR).

Commission lue depuis `profiles.commission_rate` (défaut **20** ; founding **10**).

## Blocage actuel (agents Cloud)

Sans `STRIPE_SECRET_KEY` / deploy CLI authentifié sur le projet, les fonctions sont **dans le dépôt** mais **pas live**. L’app Flutter détecte `stripe_not_configured` (HTTP 503) et affiche un mode test FR.
