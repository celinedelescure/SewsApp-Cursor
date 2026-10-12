/**
 * stripe-webhook — enregistre un achat patron après Checkout Connect.
 *
 * Secrets :
 *   STRIPE_SECRET_KEY
 *   STRIPE_WEBHOOK_SECRET (whsec_… — endpoint Checkout)
 *   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY
 *
 * Événement géré (rebuild) : checkout.session.completed (pattern_purchase).
 * Autres événements V1 (seller / abonnements) non portés ici.
 */
import Stripe from "https://esm.sh/stripe@17.7.0?target=deno";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4?target=deno";

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const stripeKey = Deno.env.get("STRIPE_SECRET_KEY");
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!stripeKey || !webhookSecret) {
    console.error("[stripe-webhook] Missing STRIPE_SECRET_KEY or STRIPE_WEBHOOK_SECRET");
    return new Response("Server configuration error", { status: 500 });
  }
  if (!supabaseUrl || !supabaseServiceKey) {
    console.error("[stripe-webhook] Missing Supabase env");
    return new Response("Server configuration error", { status: 500 });
  }

  const stripe = new Stripe(stripeKey, {
    apiVersion: "2024-12-18.acacia",
    httpClient: Stripe.createFetchHttpClient(),
  });
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  const body = await req.text();
  const signature = req.headers.get("stripe-signature");
  if (!signature) {
    return new Response("Missing signature", { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSecret);
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[stripe-webhook] Signature verification failed:", message);
    return new Response(`Webhook signature verification failed: ${message}`, {
      status: 400,
    });
  }

  console.log("[stripe-webhook] event", event.type, event.id);

  if (event.type !== "checkout.session.completed") {
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const session = event.data.object as Stripe.Checkout.Session;
  const userId = session.metadata?.user_id;
  const patternId = session.metadata?.pattern_id;
  const metaType = session.metadata?.type;

  if (!userId) {
    console.error("[stripe-webhook] Missing user_id in metadata", session.id);
    return new Response("Missing user_id", { status: 400 });
  }

  if (session.customer) {
    const customerId =
      typeof session.customer === "string" ? session.customer : session.customer.id;
    await supabase
      .from("profiles")
      .update({ stripe_customer_id: customerId })
      .eq("id", userId);
  }

  // Frais d’inscription designer (compat V1) — hors parcours Flutter rebuild pour l’instant.
  if (metaType === "designer_registration_fee") {
    await supabase
      .from("profiles")
      .update({ registration_fee_paid: true })
      .eq("id", userId);
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (session.mode !== "payment" || !patternId) {
    console.log("[stripe-webhook] Ignoring session (no pattern purchase)", session.id);
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const { data: profile, error: profileErr } = await supabase
    .from("profiles")
    .select("purchased_pattern_ids, library_statuses")
    .eq("id", userId)
    .single();

  if (profileErr || !profile) {
    console.error("[stripe-webhook] Profile fetch failed:", profileErr?.message);
    return new Response("Error fetching profile", { status: 500 });
  }

  const currentPurchased: string[] = profile.purchased_pattern_ids || [];
  if (!currentPurchased.includes(patternId)) {
    const newPurchased = [...currentPurchased, patternId];
    const newLibraryStatuses = {
      ...(profile.library_statuses || {}),
      [patternId]: { hasMaterials: false, isStarted: false, isFinished: false },
    };

    const { error: updateError } = await supabase
      .from("profiles")
      .update({
        purchased_pattern_ids: newPurchased,
        library_statuses: newLibraryStatuses,
      })
      .eq("id", userId);

    if (updateError) {
      console.error("[stripe-webhook] Profile update failed:", updateError.message);
      return new Response("Error updating profile", { status: 500 });
    }
  } else {
    console.log("[stripe-webhook] Already owned, ensuring purchase row", patternId);
  }

  // sales_count ++
  const { data: patternRow } = await supabase
    .from("patterns")
    .select(
      "name, brand, price, cover_image, category, type, difficulty, pdf_files, author_id, sales_count, currency",
    )
    .eq("id", patternId)
    .maybeSingle();

  if (patternRow && !currentPurchased.includes(patternId)) {
    const nextCount = (Number(patternRow.sales_count) || 0) + 1;
    await supabase.from("patterns").update({ sales_count: nextCount }).eq("id", patternId);
  }

  if (patternRow) {
    const { data: designer } = await supabase
      .from("profiles")
      .select("username, display_name")
      .eq("id", patternRow.author_id)
      .maybeSingle();
    const resolvedBrand =
      designer?.display_name || designer?.username || patternRow.brand || "Designer";
    const amountPaid = session.amount_total
      ? session.amount_total / 100
      : Number(patternRow.price);

    // Live / V1 : certaines bases ont `brand`, d’autres `pattern_brand`.
    const baseRow = {
      user_id: userId,
      pattern_id: patternId,
      pattern_name: patternRow.name,
      cover_image: patternRow.cover_image || null,
      category: patternRow.category || null,
      type: patternRow.type || null,
      difficulty: patternRow.difficulty || null,
      pdf_files: patternRow.pdf_files || [],
      price_paid: amountPaid,
      currency: patternRow.currency || "EUR",
    };

    let purchaseErr = (
      await supabase.from("purchases").upsert(
        { ...baseRow, brand: resolvedBrand, pattern_brand: resolvedBrand },
        { onConflict: "user_id,pattern_id" },
      )
    ).error;

    if (purchaseErr) {
      console.warn(
        "[stripe-webhook] Upsert with both brand fields failed, retry brand only:",
        purchaseErr.message,
      );
      purchaseErr = (
        await supabase.from("purchases").upsert(
          { ...baseRow, brand: resolvedBrand },
          { onConflict: "user_id,pattern_id" },
        )
      ).error;
    }

    if (purchaseErr) {
      console.warn(
        "[stripe-webhook] Upsert brand failed, retry pattern_brand:",
        purchaseErr.message,
      );
      const { error: retryErr } = await supabase.from("purchases").upsert(
        {
          user_id: userId,
          pattern_id: patternId,
          pattern_name: patternRow.name,
          pattern_brand: resolvedBrand,
          cover_image: patternRow.cover_image || null,
          category: patternRow.category || null,
          type: patternRow.type || null,
          difficulty: patternRow.difficulty || null,
          pdf_files: patternRow.pdf_files || [],
          price_paid: amountPaid,
        },
        { onConflict: "user_id,pattern_id" },
      );
      if (retryErr) {
        console.error("[stripe-webhook] Purchase upsert failed:", retryErr.message);
      }
    }

    // Notification designer (best-effort)
    try {
      await supabase.from("notifications").insert({
        user_id: patternRow.author_id,
        actor_id: userId,
        type: "SALE",
        pattern_id: patternId,
        text: `Quelqu’un a acheté votre patron « ${patternRow.name} ».`,
        is_read: false,
      });
    } catch (notifErr) {
      console.warn("[stripe-webhook] Notification skipped:", notifErr);
    }
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
