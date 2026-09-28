import { tbkOneclickRefund, tbkRefund } from "./tbk.ts";

type RefundAdmin = {
  from: (table: string) => any;
};

/**
 * Pide el reembolso una sola vez.
 * Si Transbank ya devolvió y la base no alcanzó a guardarlo, el reintento
 * solo escribe `reembolsado` y no vuelve a llamar a la tarjeta.
 */
export async function refundHeldPaymentOnce(
  admin: RefundAdmin,
  paymentId: string,
): Promise<{ status: "already" | "refunded"; payment: Record<string, unknown> }> {
  const { data: payment, error } = await admin
    .from("pagos")
    .select(
      "id, monto, token_tbk, buy_order, orden_detalle_oneclick, metodo_pago, estado, id_trabajo, reembolso_solicitado_en",
    )
    .eq("id", paymentId)
    .maybeSingle();
  if (error || !payment) throw new Error("Pago no encontrado");
  if (payment.estado === "reembolsado") {
    return { status: "already", payment };
  }
  if (payment.estado === "liberado") {
    throw new Error("El pago ya fue liberado al profesional");
  }
  if (!["autorizado", "retenido", "pendiente"].includes(payment.estado)) {
    throw new Error("Estado no reembolsable");
  }

  if (!payment.reembolso_solicitado_en) {
    const claimedAt = new Date().toISOString();
    const { data: claimed } = await admin
      .from("pagos")
      .update({ reembolso_solicitado_en: claimedAt })
      .eq("id", paymentId)
      .is("reembolso_solicitado_en", null)
      .in("estado", ["autorizado", "retenido", "pendiente"])
      .select("id")
      .maybeSingle();
    if (!claimed) {
      const { data: again } = await admin
        .from("pagos")
        .select("estado")
        .eq("id", paymentId)
        .maybeSingle();
      if (again?.estado === "reembolsado") {
        return { status: "already", payment: again };
      }
      throw new Error("Reembolso en curso. Reintenta en unos segundos.");
    }
    const oneclickDetail = String(
      payment.orden_detalle_oneclick || payment.token_tbk || "",
    );
    const canRefund = payment.metodo_pago === "oneclick"
      ? Boolean(payment.buy_order) && Boolean(oneclickDetail)
      : Boolean(payment.token_tbk);
    if (!canRefund) {
      await admin
        .from("pagos")
        .update({ reembolso_solicitado_en: null })
        .eq("id", paymentId);
      throw new Error("El cobro no tiene token de Transbank para devolverlo a la tarjeta");
    }
    try {
      if (payment.metodo_pago === "oneclick") {
        const buyOrder = String(payment.buy_order || "");
        const detail = oneclickDetail;
        if (!buyOrder || !detail) {
          throw new Error("El cobro Oneclick no tiene orden para devolverlo a la tarjeta");
        }
        await tbkOneclickRefund({
          buyOrder,
          detailBuyOrder: detail,
          amount: Number(payment.monto),
        });
      } else {
        await tbkRefund(String(payment.token_tbk), Number(payment.monto));
      }
    } catch (e) {
      await admin
        .from("pagos")
        .update({ reembolso_solicitado_en: null })
        .eq("id", paymentId)
        .is("reembolsado_en", null);
      throw e;
    }
  }

  const now = new Date().toISOString();
  const { data: updated, error: upErr } = await admin
    .from("pagos")
    .update({
      estado: "reembolsado",
      reembolsado_en: now,
      actualizado_en: now,
    })
    .eq("id", paymentId)
    .select(
      "id, id_trabajo, monto, moneda, estado, metodo_pago, id_transaccion, autorizado_en, liberado_en, reembolsado_en, creado_en, actualizado_en",
    )
    .single();
  if (upErr || !updated) {
    throw new Error("No se pudo registrar el reembolso");
  }
  if (updated.id_trabajo) {
    await admin
      .from("trabajos")
      .update({
        estado_pago: "reembolsado",
        actualizado_en: now,
      })
      .eq("id", updated.id_trabajo);
  }
  return { status: "refunded", payment: updated };
}
