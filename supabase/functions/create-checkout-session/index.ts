/**
 * create-checkout-session — Stripe Connect Checkout pour l’achat d’un patron.
 *
 * Secrets (Supabase Dashboard → Edge Functions → Secrets) :
 *   STRIPE_SECRET_KEY (test: sk_test_…)
 *   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY (injectés par défaut)
 * Optionnel :
 *   SITE_URL (URLs succès / annulation si non fournies par le client)
 *   STRIPE_PUBLISHABLE_KEY (non utilisé ici — doc côté client seulement)
 *
 * Corps JSON : { pattern_id, success_url?, cancel_url? }
 * Auth : Bearer JWT utilisateur (anon + session) — `user_id` pris du JWT, jamais du body.
 */
import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4?target=deno";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { applicationFeeCents, priceToCents } from "../_shared/commission.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!stripeKey) {
      return jsonResponse(
        {
          error:
            "Stripe non configuré : ajoutez STRIPE_SECRET_KEY (sk_test_…, mode Test) dans les secrets Edge Functions.",
          code: "stripe_not_configured",
        },
        503,
      );
    }

    // Garde-fou soft : les clés live passent, mais on journalise clairement.
    // Ne jamais logger la clé elle-même.
    if (stripeKey.startsWith("sk_live_")) {
      console.warn(
        "[create-checkout-session] STRIPE_SECRET_KEY is LIVE — real charges will occur",
      );
    } else if (!stripeKey.startsWith("sk_test_")) {
      console.warn(
        "[create-checkout-session] STRIPE_SECRET_KEY prefix unexpected (expect sk_test_ during rebuild)",
      );
    }

    if (!supabaseUrl || !supabaseServiceKey) {
      return jsonResponse(
        { error: "Configuration serveur Supabase manquante.", code: "server_misconfigured" },
        500,
      );
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return jsonResponse(
        { error: "Authentification requise.", code: "unauthorized" },
        401,
      );
    }

    // Client utilisateur pour valider le JWT ; service role pour lire prix / designer.
    const userClient = createClient(supabaseUrl, supabaseAnonKey ?? supabaseServiceKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const {
      data: { user },
      error: userErr,
    } = await userClient.auth.getUser();

    if (userErr || !user) {
      return jsonResponse(
        { error: "Session invalide. Reconnectez-vous.", code: "unauthorized" },
        401,
      );
    }

    const body = await req.json().catch(() => ({}));
    const patternId = typeof body.pattern_id === "string" ? body.pattern_id.trim() : "";
    if (!patternId) {
      return jsonResponse(
        { error: "Champ requis manquant : pattern_id", code: "bad_request" },
        400,
      );
    }

    const admin = createClient(supabaseUrl, supabaseServiceKey);

    const { data: pattern, error: patternErr } = await admin
      .from("patterns")
      .select(
        "id,name,brand,price,currency,author_id,is_published,is_draft,archived,cover_image",
      )
      .eq("id", patternId)
      .maybeSingle();

    if (patternErr || !pattern) {
      return jsonResponse({ error: "Patron introuvable.", code: "not_found" }, 404);
    }

    if (!pattern.is_published || pattern.is_draft || pattern.archived) {
      return jsonResponse(
        { error: "Ce patron n’est pas en vente.", code: "not_for_sale" },
        400,
      );
    }

    if (pattern.author_id === user.id) {
      return jsonResponse(
        { error: "Vous ne pouvez pas acheter votre propre patron.", code: "own_pattern" },
        400,
      );
    }

    // Déjà acheté ?
    const { data: buyerProfile } = await admin
      .from("profiles")
      .select("purchased_pattern_ids")
      .eq("id", user.id)
      .maybeSingle();
    const owned: string[] = buyerProfile?.purchased_pattern_ids ?? [];
    if (owned.includes(patternId)) {
      return jsonResponse(
        { error: "Vous possédez déjà ce patron.", code: "already_owned" },
        409,
      );
    }

    const { data: designer } = await admin
      .from("profiles")
      .select("stripe_account_id, commission_rate, username, display_name")
      .eq("id", pattern.author_id)
      .maybeSingle();

    const designerName =
      designer?.display_name || designer?.username || pattern.brand || "Designer";
    const productName = `${designerName} — ${pattern.name}`;
    const priceInCents = priceToCents(pattern.price);
    if (!Number.isFinite(priceInCents) || priceInCents <= 0) {
      return jsonResponse(
        { error: "Prix du patron invalide.", code: "invalid_price" },
        400,
      );
    }

    const stripe = new Stripe(stripeKey, {
      apiVersion: "2024-12-18.acacia",
      httpClient: Stripe.createFetchHttpClient(),
    });

    const siteUrl =
      Deno.env.get("SITE_URL")?.replace(/\/$/, "") || "https://www.sewsapp.com";
    const successUrl =
      (typeof body.success_url === "string" && body.success_url.trim()) ||
      `${siteUrl}/purchase-success?pattern_id=${patternId}&session_id={CHECKOUT_SESSION_ID}`;
    const cancelUrl =
      (typeof body.cancel_url === "string" && body.cancel_url.trim()) ||
      `${siteUrl}/?purchase=cancelled`;

    const sessionParams: Stripe.Checkout.SessionCreateParams = {
      mode: "payment",
      line_items: [
        {
          price_data: {
            currency: (pattern.currency || "eur").toLowerCase(),
            product_data: {
              name: productName,
              metadata: { pattern_id: patternId },
              ...(pattern.cover_image
                ? { images: [pattern.cover_image] }
                : {}),
            },
            unit_amount: priceInCents,
          },
          quantity: 1,
        },
      ],
      metadata: {
        pattern_id: patternId,
        user_id: user.id,
        type: "pattern_purchase",
      },
      success_url: successUrl,
      cancel_url: cancelUrl,
      client_reference_id: user.id,
    };

    // Split Connect Express : commission sur HT (TVA 20 %), reste vers le designer.
    let connectMode: "destination" | "platform" = "platform";
    if (designer?.stripe_account_id) {
      const fee = applicationFeeCents(
        priceInCents,
        designer.commission_rate as number | null,
      );
      sessionParams.payment_intent_data = {
        application_fee_amount: fee,
        on_behalf_of: designer.stripe_account_id,
        transfer_data: {
          destination: designer.stripe_account_id,
        },
        metadata: {
          pattern_id: patternId,
          user_id: user.id,
          type: "pattern_purchase",
        },
      };
      connectMode = "destination";
    }

    const session = await stripe.checkout.sessions.create(sessionParams);

    return jsonResponse({
      url: session.url,
      session_id: session.id,
      connect_mode: connectMode,
      commission_percent: designer?.commission_rate ?? 20,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[create-checkout-session]", message);
    return jsonResponse({ error: message, code: "stripe_error" }, 500);
  }
});
