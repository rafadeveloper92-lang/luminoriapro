/**
 * Edge Function: notify-push
 * Envia notificação push via Firebase Cloud Messaging (HTTP v1 API).
 *
 * Chamada via:
 *   - Trigger SQL (pg_net) quando nova mensagem é inserida em direct_messages
 *   - Diretamente pelo app Flutter (amigo online, etc.)
 *
 * Variável de ambiente necessária:
 *   FCM_SERVICE_ACCOUNT_JSON — conteúdo do JSON da service account Firebase
 *
 * Para configurar o secret no Supabase CLI:
 *   supabase secrets set FCM_SERVICE_ACCOUNT_JSON='<conteúdo do json>'
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = "luminorapro";
const FCM_URL = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

interface ServiceAccount {
  client_email: string;
  private_key: string;
}

interface NotifyPayload {
  to_user_id: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

// ── JWT helpers ─────────────────────────────────────────────────────────────

function b64url(input: string | Uint8Array): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : input;
  let str = "";
  for (const b of bytes) str += String.fromCharCode(b);
  return btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

async function createJWT(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const sigInput = `${header}.${payload}`;

  // Import RSA private key
  const pemBody = sa.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");
  const derBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    derBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(sigInput),
  );

  return `${sigInput}.${b64url(new Uint8Array(sig))}`;
}

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const jwt = await createJWT(sa);
  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(`Token error: ${JSON.stringify(json)}`);
  return json.access_token;
}

// ── Main handler ─────────────────────────────────────────────────────────────

serve(async (req) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response(null, {
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
        },
      });
    }

    const payload: NotifyPayload = await req.json();
    const { to_user_id, title, body, data } = payload;

    if (!to_user_id || !title || !body) {
      return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400 });
    }

    // Obter token FCM do destinatário
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: tokenRow, error } = await supabase
      .from("user_fcm_tokens")
      .select("token")
      .eq("user_id", to_user_id)
      .maybeSingle();

    if (error || !tokenRow?.token) {
      return new Response(JSON.stringify({ skipped: "no token" }), { status: 200 });
    }

    // Obter service account e access token
    const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!saJson) throw new Error("FCM_SERVICE_ACCOUNT_JSON not set");
    const sa: ServiceAccount = JSON.parse(saJson);
    const accessToken = await getAccessToken(sa);

    // Enviar notificação via FCM HTTP v1
    const fcmPayload = {
      message: {
        token: tokenRow.token,
        notification: { title, body },
        data: data ?? {},
        android: {
          priority: "high",
          notification: { sound: "default", channel_id: "luminora_friends" },
        },
        apns: {
          payload: { aps: { sound: "default", badge: 1 } },
        },
      },
    };

    const fcmRes = await fetch(FCM_URL, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fcmPayload),
    });

    const fcmJson = await fcmRes.json();
    return new Response(JSON.stringify(fcmJson), {
      status: fcmRes.status,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
