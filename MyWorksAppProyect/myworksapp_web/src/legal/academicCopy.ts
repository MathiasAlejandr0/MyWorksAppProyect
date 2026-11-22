/**
 * Webpay (`tbkConfig`) y Oneclick (`oneclickConfig`) leen `TBK_ENV` en
 * `myworksapp_app/supabase/functions/_shared/tbk.ts`. Con `integration` usan
 * https://webpay3gint.transbank.cl y los códigos públicos de integración.
 * El secreto de producción está confirmado como `integration` (digest SHA-256).
 */
export const PAYMENTS_CONFIRMED_AS_INTEGRATION = true;

export const TRANSBANK_TEST_CARDS_URL =
  'https://www.transbankdevelopers.cl/documentacion/como_empezar#tarjetas-de-prueba';

export const ACADEMIC_BANNER_TEXT =
  'Proyecto de título académico — Duoc UC. Este sitio es un prototipo con fines educativos: no es un servicio comercial, los profesionales y reseñas son de demostración. Los pagos se realizan con tarjetas de prueba de Transbank (ambiente de integración); no se cobra dinero real.';

export const ACADEMIC_ACTION_NOTE =
  'Sitio académico de demostración. Los pagos se realizan con tarjetas de prueba de Transbank (ambiente de integración); no se cobra dinero real. No ingreses datos de tarjetas reales.';

export const ACADEMIC_META_DESCRIPTION =
  'Proyecto de título académico de Ingeniería en Informática, Duoc UC (sede Puerto Montt). Prototipo educativo de MyWorksApp: no es un servicio comercial. Los pagos se realizan con tarjetas de prueba de Transbank (ambiente de integración); no se cobra dinero real.';

export const ACADEMIC_INDICATOR = 'Proyecto de título académico — Duoc UC';
