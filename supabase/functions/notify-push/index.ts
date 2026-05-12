import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, content-type" } });
  }
  try {
    const { to_user_id, title, body, image_url } = await req.json();
    const supabase = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
    const { data: row } = await supabase.from("user_fcm_tokens").select("token").eq("user_id", to_user_id).maybeSingle();
    if (!row?.token) return new Response("no token", { status: 200 });

    const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT_JSON")!);
    const now = Math.floor(Date.now() / 1000);

    function b64u(s: string): string {
      return btoa(unescape(encodeURIComponent(s))).replace(/=/g,"").replace(/\+/g,"-").replace(/\//g,"_");
    }

    const hdr = b64u(JSON.stringify({ alg: "RS256", typ: "JWT" }));
    const pay = b64u(JSON.stringify({ iss: sa.client_email, scope: "https://www.googleapis.com/auth/firebase.messaging", aud: "https://oauth2.googleapis.com/token", iat: now, exp: now + 3600 }));
    const si = `${hdr}.${pay}`;
    const pem = sa.private_key.replace(/-----BEGIN PRIVATE KEY-----/,"").replace(/-----END PRIVATE KEY-----/,"").replace(/\n/g,"");
    const der = Uint8Array.from(atob(pem), c => c.charCodeAt(0));
    const key = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
    const sig = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(si));
    const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig))).replace(/=/g,"").replace(/\+/g,"-").replace(/\//g,"_");
    const jwt = `${si}.${sigB64}`;

    const tr = await fetch("https://oauth2.googleapis.com/token", { method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" }, body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}` });
    const { access_token } = await tr.json();

    // Monta notificação — com imagem se disponível
    const notification: Record<string, string> = { title, body };
    if (image_url && image_url.length > 0) {
      notification["image"] = image_url;
    }

    const fr = await fetch("https://fcm.googleapis.com/v1/projects/luminorapro/messages:send", {
      method: "POST",
      headers: { "Authorization": `Bearer ${access_token}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        message: {
          token: row.token,
          notification,
          android: {
            priority: "high",
            notification: {
              sound: "default",
              channel_id: "luminora_friends",
              image: image_url && image_url.length > 0 ? image_url : undefined,
            }
          },
        }
      })
    });
    return new Response(await fr.text(), { status: fr.status });
  } catch(e) {
    return new Response(String(e), { status: 500 });
  }
});
