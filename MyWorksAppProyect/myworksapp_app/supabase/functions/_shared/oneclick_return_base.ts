import { APP_WEBVIEW_RETURN_ORIGIN } from "./webpay_return.ts";

/**
 * Dirección a la que vuelve el navegador después del paso del banco en Oneclick.
 *
 * - Desde la app: el sitio https que el WebView sabe seguir.
 * - Desde la web: el sitio que inició la inscripción, si está en la lista permitida.
 * - Sin origen válido: WEBPAY_WEB_RETURN_URL si es https, o el sitio publicado.
 *   Nunca localhost: en un teléfono o en producción eso es una página de error en blanco.
 */
export function oneclickReturnBase(input: {
  fromApp: boolean;
  webOrigin: string;
  allowedOrigins: string[];
  configured?: string | null;
}): string {
  if (input.fromApp) return APP_WEBVIEW_RETURN_ORIGIN;
  const origin = input.webOrigin.trim();
  if (origin && input.allowedOrigins.includes(origin)) return `${origin}/`;
  const configured = (input.configured ?? "").trim();
  if (configured.startsWith("https://")) {
    return configured.endsWith("/") ? configured : `${configured}/`;
  }
  return APP_WEBVIEW_RETURN_ORIGIN;
}
