import { allowRate, clientIp } from "../_shared/rate_limit.ts";
import { serviceClient } from "../_shared/supabase.ts";
import {
  transbankAutoPostHtml,
  transbankFormResponse,
} from "../_shared/transbank_form.ts";

/** La app abre esta página. El TBK_TOKEN se lee en el servidor y se hace POST a Transbank. */
Deno.serve(async (req) => {
  if (req.method !== "GET" && req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  try {
    if (!allowRate(`oneclick-handoff:${clientIp(req)}`, 20, 60_000)) {
      return new Response("Demasiados intentos", { status: 429 });
    }

    const ticket = new URL(req.url).searchParams.get("t")?.trim() || "";
    if (!ticket) return new Response("ticket requerido", { status: 400 });

    const admin = serviceClient();
    const { data, error } = await admin
      .from("metodos_pago_oneclick")
      .update({
        ticket_handoff: null,
        actualizado_en: new Date().toISOString(),
      })
      .eq("ticket_handoff", ticket)
      .eq("estado", "pendiente")
      .select("token_inscripcion, url_inscripcion")
      .maybeSingle();

    if (error || !data?.token_inscripcion || !data?.url_inscripcion) {
      return new Response("La inscripción ya no está disponible", { status: 404 });
    }

    const html = transbankAutoPostHtml({
      action: String(data.url_inscripcion),
      fieldName: "TBK_TOKEN",
      token: String(data.token_inscripcion),
      title: "Guardar tarjeta",
      message: "Guardando tu tarjeta en Transbank. Solo esta vez.",
    });
    return transbankFormResponse(html);
  } catch (e) {
    const msg = e instanceof Error ? e.message : "No se pudo abrir Transbank";
    const safe = msg === "URL de pago inválida" ? msg : "No se pudo abrir Transbank";
    return new Response(safe, { status: 400 });
  }
});
