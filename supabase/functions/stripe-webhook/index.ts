// Edge Function: recebe webhook do Stripe (checkout.session.completed), valida a assinatura
// e atualiza a data de expiração na tabela licenses (coluna expires_at = +30 dias).
// URL do webhook no Stripe: https://<projeto>.supabase.co/functions/v1/stripe-webhook
import Stripe from "https://esm.sh/stripe@14?target=denonext";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string, {
  apiVersion: "2024-11-20.acacia",
  httpClient: Stripe.createFetchHttpClient(),
});
const cryptoProvider = Stripe.createSubtleCryptoProvider();

Deno.serve(async (req) => {
  const signature = req.headers.get("Stripe-Signature");
  const body = await req.text();
  const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SIGNING_SECRET");

  if (!signature || !webhookSecret) {
    return new Response("Missing signature or webhook secret", { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(
      body,
      signature,
      webhookSecret,
      undefined,
      cryptoProvider
    );
  } catch (err) {
    console.error("Webhook signature verification failed:", err);
    return new Response((err as Error).message, { status: 400 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, supabaseServiceKey);

  // Eventos de fatura para histórico de pagamentos (falhas e sucessos)
  if (event.type === "invoice.payment_failed" || event.type === "invoice.paid") {
    const invoice = event.data.object as Stripe.Invoice;
    const customerEmail = invoice.customer_email ?? invoice.customer_details?.email ?? null;
    const amount = event.type === "invoice.paid" ? (invoice.amount_paid ?? invoice.amount_due ?? 0) : (invoice.amount_due ?? 0);
    const failureReason = event.type === "invoice.payment_failed"
      ? (invoice.last_finalization_error?.message ?? "payment_failed")
      : null;
    try {
      const { error } = await supabase.from("payment_events").insert({
        stripe_event_id: event.id,
        type: event.type,
        customer_email: customerEmail,
        amount_cents: amount,
        currency: invoice.currency ?? "eur",
        failure_reason: failureReason,
      });
      if (error) console.error("payment_events insert:", error);
    } catch (e) {
      console.error("Erro ao guardar payment_event:", e);
    }
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (event.type !== "checkout.session.completed") {
    return new Response(JSON.stringify({ received: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const session = event.data.object as Stripe.Checkout.Session;
  const deviceId = session.metadata?.device_id;
  const userId = session.metadata?.user_id;

  if (!deviceId && !userId) {
    console.error("checkout.session.completed sem device_id nem user_id em metadata");
    return new Response(JSON.stringify({ error: "metadata missing" }), { status: 400 });
  }

  const now = new Date();
  const expiresAt = new Date(now);
  expiresAt.setFullYear(expiresAt.getFullYear() + 1);

  try {
    if (userId) {
      const { error: upsertError } = await supabase.from("licenses").upsert(
        {
          user_id: userId,
          device_id: deviceId || null,
          expires_at: expiresAt.toISOString(),
          plan: "30d",
          notes: "Stripe checkout.session.completed",
          updated_at: now.toISOString(),
        },
        { onConflict: "user_id" }
      );
      if (upsertError) throw upsertError;
    } else if (deviceId) {
      const { data: existing } = await supabase
        .from("licenses")
        .select("id")
        .eq("device_id", deviceId)
        .maybeSingle();
      if (existing) {
        await supabase
          .from("licenses")
          .update({
            expires_at: expiresAt.toISOString(),
            plan: "30d",
            notes: "Stripe checkout.session.completed",
            updated_at: now.toISOString(),
          })
          .eq("id", existing.id);
      } else {
        await supabase.from("licenses").insert({
          user_id: crypto.randomUUID(),
          device_id: deviceId,
          expires_at: expiresAt.toISOString(),
          plan: "30d",
          notes: "Stripe checkout.session.completed",
        });
      }
    }
  } catch (e) {
    console.error("Erro ao atualizar licenses:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
