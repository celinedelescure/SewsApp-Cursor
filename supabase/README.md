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
| **Test** (recommandé) | `sk_test_` / `pk_test_` / webhook test `whsec_` | Développement — **aucun vrai paiement** |
| **Live / Production** | `sk_live_` / `pk_live_` | Argent réel — **ne pas brancher** avant validation Test |

**Bascule Test :** Stripe Dashboard → interrupteur **Test mode** (en haut à droite) → Developers → API keys → `sk_test_…` / `pk_test_…`.  
Utiliser la clé secrète **`sk_test_`** pour les Edge Functions (pas `rk_test_` restricted, sauf besoin spécifique).  
Ne collez **jamais** `sk_live_` dans le chat sans validation produit (vrais débits).

## Prochains clics (Céline) — secrets Supabase

Projet : **`uwszstlhdrkxznygdloe`**  
Dashboard : https://supabase.com/dashboard/project/uwszstlhdrkxznygdloe

1. Ouvrir **Project Settings** (icône engrenage) → **Edge Functions** → section **Secrets**  
   (ou URL directe : https://supabase.com/dashboard/project/uwszstlhdrkxznygdloe/settings/functions ).
2. **Add new secret** → nom `STRIPE_SECRET_KEY` → coller la valeur `sk_test_…` (mode Test) → Save.
3. **Add new secret** → nom `SITE_URL` → valeur `https://www.sewsapp.com` → Save.
4. (Plus tard, après création du webhook Stripe) **Add** `STRIPE_WEBHOOK_SECRET` = `whsec_…`  
   ⚠️ Ce n’est **pas** une clé `rk_test_` : le secret webhook commence toujours par `whsec_`.
5. Optionnel (non lu par ces fonctions) : `STRIPE_PUBLISHABLE_KEY` = `pk_test_…`.

`SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` sont déjà injectés par la plateforme — ne pas les écraser inutilement.

### Déployer les 2 fonctions (CLI)

Sur une machine avec [Supabase CLI](https://supabase.com/docs/guides/cli) + accès au projet :

```bash
# depuis la racine du repo SewsApp-Cursor (branche cursor/flutter-stripe-checkout)
supabase login
supabase link --project-ref uwszstlhdrkxznygdloe

# si les secrets n’ont pas été saisis dans l’UI :
supabase secrets set STRIPE_SECRET_KEY=sk_test_VOTRE_CLE
supabase secrets set SITE_URL=https://www.sewsapp.com
# après webhook :
# supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_VOTRE_SECRET

supabase functions deploy create-checkout-session --no-verify-jwt
# JWT vérifié dans le code (getUser). --no-verify-jwt évite un double rejet gateway.

supabase functions deploy stripe-webhook --no-verify-jwt
# Obligatoire : Stripe n’envoie pas de JWT Supabase.
```

Sans CLI : Dashboard → **Edge Functions** → Deploy depuis le repo / éditeur (même code sous `supabase/functions/`).

### Webhook Stripe (mode Test)

1. Stripe → **Test mode** → [Webhooks](https://dashboard.stripe.com/test/webhooks) → **Add endpoint**
2. URL : `https://uwszstlhdrkxznygdloe.supabase.co/functions/v1/stripe-webhook`
3. Événement : `checkout.session.completed`
4. Copier le **Signing secret** (`whsec_…`) → secret Supabase `STRIPE_WEBHOOK_SECRET`
5. Endpoint **Live** seulement après smoke Test OK.

## Comptes Connect designers

Les créatrices doivent avoir `profiles.stripe_account_id` (Express) + onboarding.  
Sans compte Connect, le checkout fonctionne en `connect_mode: platform` (fonds plateforme) — à corriger via onboarding Connect.

Commission : `profiles.commission_rate` (défaut **20** ; founding **10**), calculée sur le **HT** (TVA 20 %).

## Smoke test

| Check | Résultat |
|-------|----------|
| Secrets Stripe dans Supabase | **OK** (confirmé Céline) |
| `POST …/functions/v1/create-checkout-session` (fonction **V1** déjà live) | **OK** — renvoie `url` Checkout `cs_test_…` pour un patron réel |
| Clé `sk_test_` via API Stripe directe | OK |
| Comptes Connect Express sur ce Stripe Test | **0** (split destination non exercé) |
| Deploy depuis l’agent de la version rebuild (JWT) | **Bloqué** — manque `SUPABASE_ACCESS_TOKEN` |
| Secret webhook `whsec_` | **À créer** (étape webhook ci-dessus) |

La fonction **V1** live attend `{ pattern_id, user_id }`. Le client Flutter envoie les deux.  
Redéployer la version de ce repo (JWT + garde-fous) dès que vous avez un access token CLI — voir [`docs/stripe-finish-5-clicks.md`](../docs/stripe-finish-5-clicks.md).
