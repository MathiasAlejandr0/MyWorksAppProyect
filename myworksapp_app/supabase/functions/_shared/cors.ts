import { resolveCorsAllowOrigin } from "./cors_origin.ts";

export function corsHeadersFor(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") || "";
  const allowed = (Deno.env.get("CORS_ALLOWED_ORIGINS") || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  const allow = resolveCorsAllowOrigin({
    origin,
    allowlist: allowed,
    tbkEnv: Deno.env.get("TBK_ENV"),
  });

  return {
    "Access-Control-Allow-Origin": allow,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Vary": "Origin",
  };
}

export function jsonResponse(
  req: Request,
  body: unknown,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeadersFor(req),
      "Content-Type": "application/json",
    },
  });
}
