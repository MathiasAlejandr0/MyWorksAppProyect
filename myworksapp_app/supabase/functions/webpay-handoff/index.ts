import { verifyHandoffTicket } from "../_shared/security.ts";
import { serviceClient } from "../_shared/supabase.ts";
import {
  transbankAutoPostHtml,
  transbankFormResponse,
} from "../_shared/transbank_form.ts";

/** Handoff Webpay: ticket HMAC de un solo uso (marca handoff_consumido_en). */
Deno.serve(async (req) => {
  try {
    const url = new URL(req.url);
    const ticket = url.searchParams.get("t") || url.searchParams.get("ticket");
    if (!ticket) {
      return new Response("ticket requerido", { status: 400 });
    }

    const verified = await verifyHandoffTicket(ticket);
    if (!verified.ok) {
      return new Response(verified.error, { status: 403 });
    }

    const admin = serviceClient();
    const { data, error } = await admin
      .from("pagos")
      .select("token_tbk, url_tbk, estado, handoff_consumido_en")
      .eq("id", verified.paymentId)
      .maybeSingle();

    if (error || !data?.token_tbk || !data?.url_tbk) {
      return new Response("Intención de pago no encontrada", { status: 404 });
    }
    if (data.estado !== "pendiente") {
      return new Response("Pago ya no está pendiente", { status: 409 });
    }
    if (data.handoff_consumido_en) {
      return new Response("Ticket ya utilizado", { status: 409 });
    }

    const { data: claimed, error: claimErr } = await admin
      .from("pagos")
      .update({ handoff_consumido_en: new Date().toISOString() })
      .eq("id", verified.paymentId)
      .is("handoff_consumido_en", null)
      .eq("estado", "pendiente")
      .select("id")
      .maybeSingle();

    if (claimErr || !claimed) {
      return new Response("Ticket ya utilizado", { status: 409 });
    }

    const html = transbankAutoPostHtml({
      action: String(data.url_tbk),
      fieldName: "token_ws",
      token: String(data.token_tbk),
      title: "Redirigiendo a Webpay",
      message: "Redirigiendo a Transbank Webpay de forma segura.",
    });
    return transbankFormResponse(html);
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const status = msg.includes("WEBPAY_HANDOFF_SECRET") ? 503 : 500;
    return new Response(msg, { status });
  }
});
