import { serviceClient } from "./supabase.ts";

type Admin = ReturnType<typeof serviceClient>;

/** El pago ya está retenido: el profesional puede aceptar el pedido. */
export async function openJobAfterHold(admin: Admin, jobId: string) {
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
