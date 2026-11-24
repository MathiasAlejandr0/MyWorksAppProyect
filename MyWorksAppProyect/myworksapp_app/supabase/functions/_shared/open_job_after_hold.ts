type Admin = {
  rpc: (
    fn: string,
    args: Record<string, unknown>,
  ) => Promise<{ error: { message?: string } | null }>;
  from: (table: string) => {
    update: (values: Record<string, unknown>) => {
      eq: (column: string, value: string) => {
        eq: (
          column: string,
          value: string,
        ) => Promise<{ error: { message?: string } | null }>;
      };
    };
  };
};

export type HoldOptions = {
  changeOrderId?: string | null;
  paymentId?: string | null;
};

export function holdOptionsForPayment(payment: {
  id?: string | null;
  id_orden_cambio?: string | null;
}): HoldOptions {
  const paymentId = String(payment.id || "").trim();
  const changeOrderId = String(payment.id_orden_cambio || "").trim();
  return {
    paymentId: paymentId || null,
    changeOrderId: changeOrderId || null,
  };
}

/** El pago ya está retenido: el profesional puede aceptar el pedido. */
export async function openJobAfterHold(
  admin: Admin,
  jobId: string,
  options?: HoldOptions,
) {
  const changeOrderId = (options?.changeOrderId || "").trim();
  const paymentId = (options?.paymentId || "").trim();
  if (changeOrderId && paymentId) {
    const { error } = await admin.rpc("marcar_orden_cambio_pagada", {
      p_id_orden_cambio: changeOrderId,
      p_id_pago: paymentId,
    });
    if (error) {
      throw new Error(
        error.message || "No se pudo marcar la orden de cambio como pagada.",
      );
    }
    return;
  }

  const now = new Date().toISOString();
  const { error } = await admin
    .from("trabajos")
    .update({
      estado: "pendiente",
      estado_pago: "retenido",
      actualizado_en: now,
    })
    .eq("id", jobId)
    .eq("estado", "esperando_pago");
  if (error) throw new Error("No se pudo abrir el pedido al profesional.");
}
