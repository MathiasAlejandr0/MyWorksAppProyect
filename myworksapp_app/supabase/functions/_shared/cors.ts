export function corsHeadersFor(req: Request): Record<string, string> {
  const origin = req.headers.get("Origin") || "";
  const allowed = (Deno.env.get("CORS_ALLOWED_ORIGINS") || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);

  // Sin lista: solo same-origin / sin Origin (SSR, curl, TBK redirect).
  let allow = "null";
  if (!origin) {
    allow = "*"; // requests sin Origin (navegación top-level / TBK)
  } else if (allowed.length === 0) {
    // Dev default: localhost + supabase
    if (
      /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin) ||
      origin.endsWith(".supabase.co")
    ) {
      allow = origin;
    }
  } else if (allowed.includes(origin) || allowed.includes("*")) {
    allow = origin;
  }

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
