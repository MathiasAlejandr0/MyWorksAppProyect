import { escapeHtml } from "./invite_html.ts";

const LOGO_URL = "https://myworksapp.cl/brand/mark-email.png";
const SITE = "https://myworksapp.cl";
const ACADEMIC_NOTICE =
  "Aviso académico: MyWorksApp es un proyecto de título académico de Duoc UC y no es un servicio comercial. Los pagos se realizan solo con tarjetas de prueba de Transbank; no se cobra dinero real.";
const AUTO_NOTICE = "Este es un correo automático, no lo respondas.";

export type EmailRow = { label: string; value: string };
export type EmailButton = { label: string; url: string };

export type RenderEmailInput = {
  preheader: string;
  title: string;
  paragraphs: string[];
  rows?: EmailRow[];
  button?: EmailButton;
  note?: string;
};

export type RenderedEmail = { html: string; text: string };

const ALLOWED_PROTOCOLS = new Set(["https:", "myworksapp-admin:", "cl.myworksapp.auth:"]);

/** Solo https, el esquema de la consola o el de la app. El resto se descarta. */
export function safeHref(value: string | undefined | null): string | null {
  if (!value) return null;
  let url: URL;
  try {
    url = new URL(value.trim());
  } catch {
    return null;
  }
  if (!ALLOWED_PROTOCOLS.has(url.protocol)) return null;
  return url.toString();
}

function buttonHtml(label: string, href: string): string {
  const safeLabel = escapeHtml(label);
  const safeUrl = escapeHtml(href);
  return `<table role="presentation" cellpadding="0" cellspacing="0" border="0" style="margin:8px 0 4px;">
<tr><td align="center" bgcolor="#FF5E03" style="border-radius:8px;">
<!--[if mso]>
<v:roundrect xmlns:v="urn:schemas-microsoft-com:vml" xmlns:w="urn:schemas-microsoft-com:office:word" href="${safeUrl}" style="height:48px;v-text-anchor:middle;width:260px;" arcsize="14%" stroke="f" fillcolor="#FF5E03">
<w:anchorlock/>
<center style="color:#ffffff;font-family:Arial,sans-serif;font-size:16px;font-weight:bold;">${safeLabel}</center>
</v:roundrect>
<![endif]-->
<!--[if !mso]><!-->
<a href="${safeUrl}" style="display:inline-block;background:#FF5E03;color:#ffffff;font-family:Arial,Helvetica,sans-serif;font-size:16px;font-weight:bold;line-height:48px;text-align:center;text-decoration:none;border-radius:8px;padding:0 28px;mso-hide:all;">${safeLabel}</a>
<!--<![endif]-->
</td></tr></table>
<p style="margin:12px 0 0;font-family:Arial,Helvetica,sans-serif;font-size:13px;line-height:1.5;color:#5C6370;">Si el botón no funciona, copia este enlace:<br><a href="${safeUrl}" style="color:#00205B;word-break:break-all;">${safeUrl}</a></p>`;
}

function rowsHtml(rows: EmailRow[]): string {
  const body = rows.map((row) => `<tr>
<td style="padding:8px 12px;font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#5C6370;width:34%;">${escapeHtml(row.label)}</td>
<td style="padding:8px 12px;font-family:Arial,Helvetica,sans-serif;font-size:14px;color:#12141A;font-weight:bold;">${escapeHtml(row.value)}</td>
</tr>`).join("");
  return `<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin:16px 0;background:#F7F5F2;border-radius:8px;">${body}</table>`;
}

/** Correo en tablas, compatible con Gmail, Outlook y el móvil. Ancho 600. */
export function renderEmail(input: RenderEmailInput): RenderedEmail {
  const title = escapeHtml(input.title);
  const preheader = escapeHtml(input.preheader);
  const paragraphs = input.paragraphs
    .filter((paragraph) => paragraph.trim())
    .map((paragraph) =>
      `<p style="margin:0 0 14px;font-family:Arial,Helvetica,sans-serif;font-size:16px;line-height:1.5;color:#12141A;">${escapeHtml(paragraph)}</p>`
    )
    .join("");
  const href = input.button ? safeHref(input.button.url) : null;
  const button = href && input.button ? buttonHtml(input.button.label, href) : "";
  const rows = input.rows && input.rows.length > 0 ? rowsHtml(input.rows) : "";
  const note = input.note?.trim()
    ? `<p style="margin:16px 0 0;font-family:Arial,Helvetica,sans-serif;font-size:13px;line-height:1.5;color:#5C6370;">${escapeHtml(input.note)}</p>`
    : "";
  const legal = escapeHtml(ACADEMIC_NOTICE);
  const auto = escapeHtml(AUTO_NOTICE);
  const aviso = `${SITE}/aviso-legal`;
  const privacidad = `${SITE}/privacidad`;

  const html = `<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title></head>
<body style="margin:0;padding:0;background:#F7F5F2;">
<div style="display:none;max-height:0;overflow:hidden;mso-hide:all;">${preheader}</div>
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background:#F7F5F2;">
<tr><td align="center" style="padding:24px 12px;">
<table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="width:600px;max-width:600px;">
<tr><td style="background:#00205B;border-bottom:4px solid #FF5E03;padding:20px 24px;">
<table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
<td style="padding-right:12px;"><img src="${LOGO_URL}" width="36" height="36" alt="MyWorksApp" style="display:block;border:0;width:36px;height:36px;"></td>
<td style="font-family:Arial,Helvetica,sans-serif;font-size:22px;line-height:36px;font-weight:bold;"><span style="color:#ffffff;">MyWorks</span><span style="color:#FF5E03;">App</span></td>
</tr></table>
</td></tr>
<tr><td style="background:#ffffff;padding:28px 24px 24px;">
<h1 style="margin:0 0 16px;font-family:Arial,Helvetica,sans-serif;font-size:24px;line-height:1.3;color:#12141A;font-weight:bold;">${title}</h1>
${paragraphs}${rows}${button}${note}
</td></tr>
<tr><td style="background:#EFEBE5;padding:20px 24px;">
<p style="margin:0 0 10px;font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:1.5;color:#5C6370;">${legal}</p>
<p style="margin:0 0 10px;font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:1.5;color:#5C6370;">${auto}</p>
<p style="margin:0;font-family:Arial,Helvetica,sans-serif;font-size:12px;line-height:1.5;">
<a href="${aviso}" style="color:#00205B;">Aviso legal</a>
&nbsp;·&nbsp;
<a href="${privacidad}" style="color:#00205B;">Privacidad</a>
</p>
</td></tr>
</table>
</td></tr>
</table>
</body>
</html>`;

  const textRows = (input.rows ?? [])
    .map((row) => `${row.label}: ${row.value}`)
    .join("\n");
  const textButton = href && input.button ? `${input.button.label}: ${href}` : "";
  const text = [
    input.title,
    "",
    ...input.paragraphs.filter((paragraph) => paragraph.trim()),
    textRows,
    textButton,
    input.note?.trim() ?? "",
    "",
    ACADEMIC_NOTICE,
    AUTO_NOTICE,
    `Aviso legal: ${aviso}`,
    `Privacidad: ${privacidad}`,
  ].filter((line) => line !== "").join("\n");

  return { html, text };
}
