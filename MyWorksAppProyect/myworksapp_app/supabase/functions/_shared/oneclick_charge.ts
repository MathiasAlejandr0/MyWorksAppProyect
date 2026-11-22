import { asCoord, roundClp, transportExtraClp } from "./transport.ts";
import { detailBuyOrder, freshBuyOrder } from "./buy_order.ts";
import {
  holdOptionsForPayment,
  openJobAfterHold,
} from "./open_job_after_hold.ts";
import { serviceClient } from "./supabase.ts";
import {
  oneclickAuthCode,
  oneclickAuthorized,
  oneclickConfig,
  oneclickDeclined,
  tbkOneclickAuthorize,
  tbkOneclickStatus,
} from "./tbk.ts";
type Admin = ReturnType<typeof serviceClient>;

export { cardLast4 } from "./oneclick_inscription.ts";

async function markHeld(
  admin: Admin,
  input: {
    paymentId: string;
    jobId: string;
    buyOrder: string;
    detailOrder: string;
    authCode: string;
    changeOrderId?: string | null;
  },
) {
  const now = new Date().toISOString();
  const { env } = oneclickConfig();
  const { error } = await admin
    .from("pagos")
    .update({
      estado: "retenido",
      metodo_pago: "oneclick",
      buy_order: input.buyOrder,
      orden_detalle_oneclick: input.detailOrder,
      token_tbk: null,
      cobro_reclamado_en: null,
      id_transaccion: input.authCode || input.buyOrder,
      ambiente: env,
      autorizado_en: now,
      actualizado_en: now,
    })
    .eq("id", input.paymentId);
  if (error) throw new Error("No se pudo registrar el cobro.");

  await openJobAfterHold(
    admin,
    input.jobId,
    holdOptionsForPayment({
      id: input.paymentId,
      id_orden_cambio: input.changeOrderId,
    }),
  );
}

async function releaseClaim(admin: Admin, paymentId: string) {
  await admin
    .from("pagos")
    .update({
      cobro_reclamado_en: null,
      actualizado_en: new Date().toISOString(),
    })
    .eq("id", paymentId)
    .eq("estado", "pendiente");
}

/**
 * Cobra la tarjeta inscrita y deja el pago retenido.
 * reclamar_cobro_oneclick deja una sola autorización en curso.
 * Si Transbank ya autorizó ese buy_order, no vuelve a cobrar.
 */
export async function chargeInscribedCard(
  admin: Admin,
  input: {
    userId: string;
    username: string;
    tbkUser: string;
    jobId: string;
    amountClp: number;
    payment: {
      id: string;
      buy_order?: string | null;
      estado?: string | null;
      metodo_pago?: string | null;
      id_orden_cambio?: string | null;
    };
  },
): Promise<{ paymentId: string; amount: number }> {
  const amount = Math.round(input.amountClp);
  const holdOpts = holdOptionsForPayment(input.payment);
  if (
    input.payment.estado === "retenido" ||
    input.payment.estado === "autorizado" ||
    input.payment.estado === "liberado"
  ) {
    await openJobAfterHold(admin, input.jobId, holdOpts);
    return { paymentId: input.payment.id, amount };
  }

  let buyOrder = freshBuyOrder(input.payment.id, null);
  const existing = String(input.payment.buy_order || "");
  if (existing && String(input.payment.metodo_pago || "") === "oneclick") {
    const priorExisting = await tbkOneclickStatus(existing);
    if (oneclickAuthorized(priorExisting)) {
      await markHeld(admin, {
        paymentId: input.payment.id,
        jobId: input.jobId,
        buyOrder: existing,
        detailOrder: detailBuyOrder(existing),
        authCode: oneclickAuthCode(priorExisting),
        changeOrderId: holdOpts.changeOrderId,
      });
      return { paymentId: input.payment.id, amount };
    }
    buyOrder = oneclickDeclined(priorExisting)
      ? freshBuyOrder(input.payment.id, existing)
      : existing;
  }

  const { data: claim, error: claimErr } = await admin.rpc(
    "reclamar_cobro_oneclick",
    {
      p_id_pago: input.payment.id,
      p_buy_order: buyOrder,
      p_monto: amount,
    },
  );
  if (claimErr) {
    const message = String(claimErr.message || "");
    if (message.includes("cobro en curso")) {
      throw new Error("Ya hay un pago Webpay en curso para este pedido.");
    }
    throw new Error("No se pudo preparar el cobro.");
  }
  if (claim === "listo") {
    await openJobAfterHold(admin, input.jobId, holdOpts);
    return { paymentId: input.payment.id, amount };
  }

  const detail = detailBuyOrder(buyOrder);
  const prior = await tbkOneclickStatus(buyOrder);
  if (oneclickAuthorized(prior)) {
    await markHeld(admin, {
      paymentId: input.payment.id,
      jobId: input.jobId,
      buyOrder,
      detailOrder: detail,
      authCode: oneclickAuthCode(prior),
      changeOrderId: holdOpts.changeOrderId,
    });
    return { paymentId: input.payment.id, amount };
  }

  if (claim === "en_curso") {
    const { data: row } = await admin
      .from("pagos")
      .select("buy_order, estado")
      .eq("id", input.payment.id)
      .maybeSingle();
    if (
      row?.estado === "retenido" ||
      row?.estado === "autorizado" ||
      row?.estado === "liberado"
    ) {
      await openJobAfterHold(admin, input.jobId, holdOpts);
      return { paymentId: input.payment.id, amount };
    }
    const current = String(row?.buy_order || "");
    if (current) {
      const racing = await tbkOneclickStatus(current);
      if (oneclickAuthorized(racing)) {
        await markHeld(admin, {
          paymentId: input.payment.id,
          jobId: input.jobId,
          buyOrder: current,
          detailOrder: detailBuyOrder(current),
          authCode: oneclickAuthCode(racing),
          changeOrderId: holdOpts.changeOrderId,
        });
        return { paymentId: input.payment.id, amount };
      }
    }
    throw new Error(
      "Ya hay un cobro en curso para este pedido. Espera un momento e inténtalo de nuevo.",
    );
  }

  let commit: Record<string, unknown>;
  try {
    commit = await tbkOneclickAuthorize({
      username: input.username,
      tbkUser: input.tbkUser,
      buyOrder,
      detailBuyOrder: detail,
      amount,
    });
  } catch (e) {
    // Sin esto el cobro queda reclamado 90 s y el reintento choca con "cobro en curso".
    await releaseClaim(admin, input.payment.id);
    throw e;
  }

  if (!oneclickAuthorized(commit)) {
    await releaseClaim(admin, input.payment.id);
    throw new Error("El banco no autorizó el cobro a tu tarjeta.");
  }

  await markHeld(admin, {
    paymentId: input.payment.id,
    jobId: input.jobId,
    buyOrder,
    detailOrder: detail,
    authCode: oneclickAuthCode(commit),
    changeOrderId: holdOpts.changeOrderId,
  });

  return { paymentId: input.payment.id, amount };
}

export async function expectedJobAmount(
  admin: Admin,
  jobId: string,
): Promise<number> {
  const { data, error } = await admin.rpc("monto_esperado_trabajo_id", {
    p_id: jobId,
  });
  const missing = error != null &&
    /monto_esperado_trabajo_id|42883|schema cache/i.test(error.message ?? "");
  if (!error && data != null) {
    const amount = Number(data);
    if (Number.isFinite(amount) && amount > 0) return Math.round(amount);
  }
  if (!missing) return 0;

  const { data: job } = await admin
    .from("trabajos")
    .select("id_trabajador, id_cotizacion_seleccionada, modalidad_cobro, latitud, longitud")
    .eq("id", jobId)
    .maybeSingle();
  if (!job) return 0;
  if (job.id_cotizacion_seleccionada && job.id_trabajador) {
    const { data: quote } = await admin
      .from("propuestas_cotizacion")
      .select("monto_total_clp")
      .eq("id", job.id_cotizacion_seleccionada)
      .eq("id_trabajador", job.id_trabajador)
      .in("estado", ["seleccionada", "aceptada"])
      .maybeSingle();
    return roundClp(Number(quote?.monto_total_clp || 0));
  }
  if (
    job.modalidad_cobro === "cotizacion_abierta" ||
    job.modalidad_cobro === "cotizacion" ||
    !job.id_trabajador
  ) {
    return 0;
  }
  const { data: worker } = await admin
    .from("trabajadores")
    .select("tarifa_visita, latitud_base, longitud_base, radio_servicio_km")
    .eq("id_usuario", job.id_trabajador)
    .maybeSingle();
  const visit = roundClp(Number(worker?.tarifa_visita || 0));
  const extra = transportExtraClp({
    workerLat: asCoord(worker?.latitud_base),
    workerLng: asCoord(worker?.longitud_base),
    jobLat: asCoord(job.latitud),
    jobLng: asCoord(job.longitud),
    radiusKm: asCoord(worker?.radio_servicio_km),
  });
  return visit + extra;
}
