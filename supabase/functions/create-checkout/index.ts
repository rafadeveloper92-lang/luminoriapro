// Edge Function: cria sessão Stripe Checkout com metadata (device_id, user_id).
import Stripe from "https://esm.sh/stripe@14?target=denonext";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") as string, {
  apiVersion: "2024-11-20.acacia",
  httpClient: Stripe.createFetchHttpClient(),
});

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { device_id, user_id } = await req.json();
    const priceId = Deno.env.get("STRIPE_PRICE_ID");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!priceId || !supabaseUrl) {
      return new Response(
        JSON.stringify({ error: "STRIPE_PRICE_ID ou SUPABASE_URL não configurados" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    if (!device_id) {
      return new Response(
        JSON.stringify({ error: "device_id é obrigatório" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      payment_method_types: ["card"],
      locale: "pt",
      success_url: `${supabaseUrl}/functions/v1/stripe-success-placeholder?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${supabaseUrl}/functions/v1/stripe-cancel-placeholder`,
      metadata: {
        device_id: String(device_id),
        ...(user_id ? { user_id: String(user_id) } : {}),
      },
    });

    return new Response(
      JSON.stringify({ url: session.url }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error(e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
