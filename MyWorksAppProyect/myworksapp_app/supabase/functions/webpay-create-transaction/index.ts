import { corsHeadersFor } from "../_shared/cors.ts";

/** Stub para pisar la función vieja desplegada. El camino vigente es webpay-create. */
Deno.serve((req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeadersFor(req) });
  }
  return new Response(JSON.stringify({ error: "Esta función ya no existe" }), {
    status: 410,
    headers: {
      ...corsHeadersFor(req),
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
});
