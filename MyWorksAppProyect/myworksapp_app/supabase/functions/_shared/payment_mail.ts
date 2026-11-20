import { renderEmail } from "./email_layout.ts";
import { scheduleAfterResponse, sendEmail } from "./email_send.ts";
import { isReservedEmailDomain } from "./guest_ticket.ts";
import {
  APP_WEBVIEW_RETURN_ORIGIN,
  bridgeCustomSchemeReturn,
  webReturnLocation,
} from "./webpay_return.ts";

type UserRecord = {
  email?: string | null;
  user_metadata?: Record<string, unknown>;
};

type MailAdmin = {
  auth: {
    admin: {
      getUserById: (id: string) => Promise<{
        data: { user: UserRecord | null } | null;
        error: unknown;
      }>;
    };
  };
  // El cliente de servicio no trae el genérico de tablas.
  // deno-lint-ignore no-explicit-any
  from: (table: string) => any;
};

type PaymentFacts = {
  paymentId: string;
  amount: number;
  order: string;
  when: string;
  serviceName: string;
  clientId: string;
  workerId: string;
};

const TEST_CARD_NOTE =
  "Este cobro usó una tarjeta de prueba de Transbank. No se cargó dinero real.";

/** Misma regla que correo_es_demo: demo.myworksapp.cl y demo.com. */
export function isDemoAccountEmail(email: string): boolean {
  const at = email.trim().toLowerCase().lastIndexOf("@");
  if (at < 0) return false;
  const domain = email.trim().toLowerCase().slice(at + 1).replace(/\.$/, "");
  return domain === "demo.myworksapp.cl" || domain === "demo.com";
}

/** Pesos chilenos, con punto de miles. */
export function formatClp(amount: number): string {
  const rounded = Math.round(Number(amount));
  if (!Number.isFinite(rounded)) return "$0";
  const negative = rounded < 0;
  const digits = String(Math.abs(rounded));
  const grouped = digits.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  return `${negative ? "-" : ""}$${grouped}`;
}

/** Fecha visible en America/Santiago. Un día suelto no se corre al día anterior. */
export function formatSantiago(iso: string | null | undefined): string {
  const value = (iso || "").trim();
  if (!value) return "Por coordinar";
  const dateOnly = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  const date = dateOnly
    ? new Date(Date.UTC(Number(dateOnly[1]), Number(dateOnly[2]) - 1, Number(dateOnly[3]), 15))
    : new Date(value);
  if (Number.isNaN(date.getTime())) return "Por coordinar";
  const options: Intl.DateTimeFormatOptions = dateOnly
    ? { timeZone: "America/Santiago", day: "2-digit", month: "long", year: "numeric" }
    : {
      timeZone: "America/Santiago",
      day: "2-digit",
      month: "long",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    };
  return new Intl.DateTimeFormat("es-CL", options).format(date);
}

/** El mismo enlace https que usa la redirección de Webpay, con el ticket de alta. */
export function guestPasswordUrl(input: {
  origin: string;
  paymentId: string;
  jobId: string;
  alta: string;
  webReturnUrl?: string | null;
}): string {
  const location = webReturnLocation({
    origin: input.origin,
    pago: "ok",
    paymentId: input.paymentId,
    jobId: input.jobId,
    guest: true,
    alta: input.alta,
  });
  const configured = (input.webReturnUrl || "").trim();
  const httpsOrigin = configured.startsWith("https://")
    ? configured
    : APP_WEBVIEW_RETURN_ORIGIN;
  return bridgeCustomSchemeReturn(location, httpsOrigin);
}

function metaIsDemo(metadata: Record<string, unknown> | undefined): boolean {
  const flag = metadata?.es_demo;
  return flag === true || flag === "true" || flag === 1;
}

async function recipientEmail(admin: MailAdmin, userId: string): Promise<string | null> {
  if (!userId) return null;
  const { data, error } = await admin.auth.admin.getUserById(userId);
  if (error || !data?.user) return null;
  const email = String(data.user.email || "").trim();
  if (!email) return null;
  if (metaIsDemo(data.user.user_metadata)) return null;
  if (isDemoAccountEmail(email) || isReservedEmailDomain(email)) return null;
  const worker = await admin
    .from("trabajadores")
    .select("es_demo")
    .eq("id_usuario", userId)
    .maybeSingle();
  if (!worker.error && worker.data && metaIsDemo({ es_demo: worker.data.es_demo })) return null;
  return email;
}

async function loadFacts(admin: MailAdmin, paymentId: string): Promise<PaymentFacts | null> {
  const payment = await admin
    .from("pagos")
    .select("id, monto, buy_order, id_trabajo, autorizado_en, creado_en")
    .eq("id", paymentId)
    .maybeSingle();
  if (payment.error || !payment.data?.id) return null;
  const row = payment.data;
  const job = await admin
    .from("trabajos")
    .select("id_usuario, id_trabajador, id_servicio, fecha_programada")
    .eq("id", String(row.id_trabajo || ""))
    .maybeSingle();
  let serviceName = "Servicio";
  const serviceId = job.data?.id_servicio ? String(job.data.id_servicio) : "";
  if (serviceId) {
    const service = await admin
      .from("servicios")
      .select("nombre")
      .eq("id", serviceId)
      .maybeSingle();
    if (!service.error && service.data?.nombre) serviceName = String(service.data.nombre);
  }
  return {
    paymentId: String(row.id),
    amount: Number(row.monto || 0),
    order: String(row.buy_order || row.id),
    when: String(job.data?.fecha_programada || row.autorizado_en || row.creado_en || ""),
    serviceName,
    clientId: job.data?.id_usuario ? String(job.data.id_usuario) : "",
    workerId: job.data?.id_trabajador ? String(job.data.id_trabajador) : "",
  };
}

function receiptRows(facts: PaymentFacts): { label: string; value: string }[] {
  return [
    { label: "Servicio", value: facts.serviceName },
    { label: "Fecha", value: formatSantiago(facts.when) },
    { label: "Monto", value: formatClp(facts.amount) },
    { label: "Orden", value: facts.order },
  ];
}

async function sendTo(
  to: string,
  subject: string,
  content: ReturnType<typeof renderEmail>,
  idempotencyKey: string,
  tag: string,
): Promise<void> {
  await sendEmail({
    to,
    subject,
    content,
    idempotencyKey,
    tags: [{ name: "tipo", value: tag }],
  });
}

async function deliverReceived(admin: MailAdmin, paymentId: string): Promise<void> {
  const facts = await loadFacts(admin, paymentId);
  if (!facts) return;
  const subject = `Pago recibido — reserva ${facts.serviceName}`;
  const contentFor = (who: string) => renderEmail({
    preheader: `Registramos el pago de ${facts.serviceName}.`,
    title: "Pago recibido",
    paragraphs: [
      who === "cliente"
        ? "Recibimos el pago de tu reserva. Queda retenido hasta que el servicio termine."
        : "El cliente ya pagó esta reserva. El monto queda retenido hasta el cierre del servicio.",
    ],
    rows: receiptRows(facts),
    note: TEST_CARD_NOTE,
  });
  const client = await recipientEmail(admin, facts.clientId);
  const worker = facts.workerId ? await recipientEmail(admin, facts.workerId) : null;
  if (client) {
    await sendTo(client, subject, contentFor("cliente"), `pago-${facts.paymentId}-recibido-cliente`, "pago_recibido");
  }
  if (worker && worker !== client) {
    await sendTo(
      worker,
      subject,
      contentFor("profesional"),
      `pago-${facts.paymentId}-recibido-profesional`,
      "pago_recibido",
    );
  }
}

async function deliverGuestPassword(admin: MailAdmin, paymentId: string, link: string): Promise<void> {
  if (!link.trim()) return;
  const facts = await loadFacts(admin, paymentId);
  if (!facts) return;
  const client = await recipientEmail(admin, facts.clientId);
  if (!client) return;
  const content = renderEmail({
    preheader: "Define tu contraseña para ver la reserva.",
    title: "Define tu contraseña",
    paragraphs: [
      "Tu reserva quedó registrada.",
      "Define una contraseña para entrar y ver el pedido.",
    ],
    rows: receiptRows(facts),
    button: { label: "Definir contraseña", url: link },
    note: TEST_CARD_NOTE,
  });
  await sendTo(
    client,
    "Tu reserva en MyWorksApp: define tu contraseña",
    content,
    `pago-${facts.paymentId}-alta`,
    "alta_invitado",
  );
}

async function deliverRefund(admin: MailAdmin, paymentId: string): Promise<void> {
  const facts = await loadFacts(admin, paymentId);
  if (!facts) return;
  const client = await recipientEmail(admin, facts.clientId);
  if (!client) return;
  const content = renderEmail({
    preheader: "Devolvimos el pago de tu reserva.",
    title: "Reembolso de tu pago",
    paragraphs: [
      "Devolvimos el pago a la tarjeta con la que reservaste.",
      "Si usaste una tarjeta de prueba de Transbank, no hubo un cargo de dinero real.",
    ],
    rows: receiptRows(facts),
    note: TEST_CARD_NOTE,
  });
  await sendTo(
    client,
    "Reembolso de tu pago en MyWorksApp",
    content,
    `pago-${facts.paymentId}-reembolso`,
    "reembolso",
  );
}

async function deliverReleased(admin: MailAdmin, paymentId: string): Promise<void> {
  const facts = await loadFacts(admin, paymentId);
  if (!facts || !facts.workerId) return;
  const worker = await recipientEmail(admin, facts.workerId);
  if (!worker) return;
  const content = renderEmail({
    preheader: "Liberamos el pago de tu servicio.",
    title: "Liberamos tu pago",
    paragraphs: [
      "Liberamos el pago de esta reserva.",
      "Recuerda emitir la boleta en el SII por este servicio.",
    ],
    rows: receiptRows(facts),
    note: TEST_CARD_NOTE,
  });
  await sendTo(
    worker,
    "Liberamos tu pago",
    content,
    `pago-${facts.paymentId}-liberado`,
    "pago_liberado",
  );
}

export function schedulePaymentReceivedEmail(admin: MailAdmin, paymentId: string): void {
  scheduleAfterResponse(deliverReceived(admin, paymentId));
}

export function scheduleGuestPasswordEmail(admin: MailAdmin, paymentId: string, link: string): void {
  scheduleAfterResponse(deliverGuestPassword(admin, paymentId, link));
}

export function scheduleRefundEmail(admin: MailAdmin, paymentId: string): void {
  scheduleAfterResponse(deliverRefund(admin, paymentId));
}

export function scheduleReleasedEmail(admin: MailAdmin, paymentId: string): void {
  scheduleAfterResponse(deliverReleased(admin, paymentId));
}
