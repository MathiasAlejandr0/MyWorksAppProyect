/**
 * MyWorksApp — Prueba de carga y rendimiento (k6).
 *
 * Reproduce, solo con LECTURAS, lo que hace un visitante en la web pública:
 *   1. Abre la portada en Vercel (HTML + JS + CSS + una imagen de oficio).
 *   2. La web pide los oficios con profesionales disponibles (RPC
 *      categorias_con_disponibles) y el catálogo de servicios (REST servicios).
 *   3. Elige un oficio y lista profesionales (RPC listar_profesionales_catalogo,
 *      mismo payload que shared/src/repositories/workers.ts).
 *   4. Abre el perfil de un profesional y consulta sus horas libres
 *      (RPC horarios_libres_profesional, 14 días).
 *   5. Control de seguridad: GET /trabajos como anónimo DEBE ser rechazado
 *      (401/42501 por RLS/grants). Se marca como respuesta esperada.
 * Además, un escenario aparte a tasa fija y baja llama a la Edge Function
 * webpay-status (preflight CORS + lectura de un pago existente como invitado).
 *
 * No crea pagos, trabajos ni usuarios. No llama a Transbank.
 *
 * Uso:
 *   k6 run -e SUPABASE_URL=https://<ref>.supabase.co -e SUPABASE_ANON_KEY=<anon> \
 *          -e PROFILE=smoke|load|stress|pico \
 *          -e STATUS_PAYMENT_ID=<uuid> -e STATUS_JOB_ID=<uuid> \
 *          --summary-export=resultados/<perfil>.json docs/pruebas/k6/mwa_carga.js
 * La clave anon es la publicable del cliente web. Nunca uses service_role aquí.
 */
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

const WEB = (__ENV.WEB_URL || 'https://myworksapp-cl.vercel.app').replace(/\/$/, '');
const SB = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const KEY = __ENV.SUPABASE_ANON_KEY || '';
const PROFILE = (__ENV.PROFILE || 'smoke').toLowerCase();
const PAY_ID = __ENV.STATUS_PAYMENT_ID || '';
const JOB_ID = __ENV.STATUS_JOB_ID || '';
const ORIGIN = WEB;
// Igual que un navegador: pide la respuesta comprimida (k6 la descomprime).
const WEB_HEADERS = { 'Accept-Encoding': 'gzip, deflate, br' };

if (!SB || !KEY) throw new Error('Faltan SUPABASE_URL y SUPABASE_ANON_KEY');

// Oficios y profesionales reales de la demo (Puerto Montt). Cada VU rota.
const CATEGORIAS = ['gasfiteria', 'electricidad', 'plomeria', 'limpieza', 'cerrajeria', 'pintura'];
const IMAGENES = ['gasfiteria', 'plomeria', 'limpieza', 'cerrajeria', 'armado'];

// --- Métricas propias ---------------------------------------------------------
const errores = new Rate('mwa_errores'); // iteración con al menos 1 check fallido
const rateLimited = new Counter('mwa_http_429');
const server5xx = new Counter('mwa_http_5xx');
const timeouts = new Counter('mwa_timeouts'); // status 0 = sin respuesta / timeout
const rlsDenegado = new Rate('mwa_rls_anon_denegado');

// --- Perfiles -----------------------------------------------------------------
const perfilesNavegacion = {
  smoke: { executor: 'constant-vus', vus: 1, duration: '1m' },
  load: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '1m', target: 30 },
      { duration: '3m', target: 30 },
      { duration: '30s', target: 0 },
    ],
    gracefulRampDown: '15s',
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 50 },
      { duration: '30s', target: 100 },
      { duration: '1m', target: 100 },
      { duration: '30s', target: 0 },
    ],
    gracefulRampDown: '15s',
  },
  // Pico corto: duplica el estrés para buscar el punto de quiebre.
  pico: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 200 },
      { duration: '1m', target: 200 },
      { duration: '30s', target: 0 },
    ],
    gracefulRampDown: '15s',
  },
};
const edgeRate = { smoke: 0.5, load: 1, stress: 2, pico: 2 }; // llamadas/seg a la Edge Function
const edgeDur = { smoke: '1m', load: '4m30s', stress: '2m30s', pico: '2m' };

const scenarios = {
  navegacion: { ...(perfilesNavegacion[PROFILE] || perfilesNavegacion.smoke), exec: 'navegacion' },
};
if (PAY_ID && JOB_ID) {
  scenarios.edge_status = {
    executor: 'constant-arrival-rate',
    rate: Math.round((edgeRate[PROFILE] || 0.5) * 2),
    timeUnit: '2s',
    duration: edgeDur[PROFILE] || '1m',
    preAllocatedVUs: 4,
    maxVUs: 10,
    exec: 'edgeStatus',
  };
}

// Umbrales definidos ANTES de correr (criterios de aceptación).
export const options = {
  scenarios,
  discardResponseBodies: false,
  thresholds: {
    // Globales
    http_req_failed: [
      'rate<0.01',
      { threshold: 'rate<0.05', abortOnFail: true, delayAbortEval: '20s' }, // corte de seguridad
    ],
    http_req_duration: ['p(95)<800', 'p(99)<1500'],
    checks: ['rate>0.99'],
    mwa_errores: ['rate<0.01'],
    mwa_http_429: ['count<1'],
    mwa_http_5xx: ['count<1'],
    mwa_rls_anon_denegado: ['rate==1'],
    // Por tipo de recurso
    'http_req_duration{tipo:web}': ['p(95)<500'],
    'http_req_duration{tipo:supabase}': ['p(95)<800'],
    'http_req_duration{tipo:edge}': ['p(95)<1500'],
    // Por endpoint (también sirven para que el resumen traiga el desglose)
    'http_req_duration{name:web_portada}': ['p(95)<500'],
    'http_req_duration{name:web_js}': ['p(95)<500'],
    'http_req_duration{name:web_css}': ['p(95)<500'],
    'http_req_duration{name:web_imagen_oficio}': ['p(95)<500'],
    'http_req_duration{name:rpc_categorias}': ['p(95)<800'],
    'http_req_duration{name:rest_servicios}': ['p(95)<800'],
    'http_req_duration{name:rpc_catalogo}': ['p(95)<800'],
    'http_req_duration{name:rpc_horarios_libres}': ['p(95)<800'],
    'http_req_duration{name:rest_trabajos_anon_rls}': ['p(95)<800'],
    'http_req_duration{name:edge_status_preflight}': ['p(95)<1500'],
    'http_req_duration{name:edge_status_get}': ['p(95)<1500'],
  },
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max', 'count'],
};

const sbHeaders = {
  apikey: KEY,
  Authorization: `Bearer ${KEY}`,
  Accept: 'application/json',
  'Content-Type': 'application/json',
  Origin: ORIGIN,
};

function contar(res) {
  if (res.status === 429) rateLimited.add(1);
  if (res.status >= 500) server5xx.add(1);
  if (res.status === 0) timeouts.add(1);
}

function json(res) {
  try {
    return res.json();
  } catch (_) {
    return null;
  }
}

function rpc(nombre, body, tag) {
  const r = http.post(`${SB}/rest/v1/rpc/${nombre}`, JSON.stringify(body), {
    headers: sbHeaders,
    tags: { name: tag, tipo: 'supabase' },
    timeout: '30s',
  });
  contar(r);
  return r;
}

export function navegacion() {
  let ok = true;
  const cat = CATEGORIAS[(__VU + __ITER) % CATEGORIAS.length];

  group('1_web_vercel', () => {
    const home = http.get(`${WEB}/`, { headers: WEB_HEADERS, tags: { name: 'web_portada', tipo: 'web' }, timeout: '30s' });
    contar(home);
    const js = (home.body || '').match(/src="(\/assets\/index-[^"]+\.js)"/);
    const css = (home.body || '').match(/href="(\/assets\/index-[^"]+\.css)"/);
    ok = check(home, {
      'portada: status 200': (r) => r.status === 200,
      'portada: es HTML': (r) => String(r.headers['Content-Type'] || '').includes('text/html'),
      'portada: contiene <div id="root">': (r) => (r.body || '').includes('id="root"'),
      'portada: referencia bundle JS y CSS': () => !!js && !!css,
    }) && ok;
    if (js) {
      const r = http.get(`${WEB}${js[1]}`, { headers: WEB_HEADERS, tags: { name: 'web_js', tipo: 'web' }, timeout: '30s' });
      contar(r);
      ok = check(r, {
        'js: status 200': (x) => x.status === 200,
        'js: content-type javascript': (x) => String(x.headers['Content-Type'] || '').includes('javascript'),
        'js: tamaño > 50 KB': (x) => (x.body || '').length > 50000,
      }) && ok;
    }
    if (css) {
      const r = http.get(`${WEB}${css[1]}`, { headers: WEB_HEADERS, tags: { name: 'web_css', tipo: 'web' }, timeout: '30s' });
      contar(r);
      ok = check(r, {
        'css: status 200': (x) => x.status === 200,
        'css: content-type css': (x) => String(x.headers['Content-Type'] || '').includes('text/css'),
      }) && ok;
    }
    const img = IMAGENES[(__VU + __ITER) % IMAGENES.length];
    const im = http.get(`${WEB}/categories/${img}.webp`, {
      headers: WEB_HEADERS,
      tags: { name: 'web_imagen_oficio', tipo: 'web' },
      responseType: 'none',
      timeout: '30s',
    });
    contar(im);
    ok = check(im, {
      'imagen: status 200': (x) => x.status === 200,
      'imagen: content-type webp': (x) => String(x.headers['Content-Type'] || '').includes('image/webp'),
    }) && ok;
  });

  sleep(1 + Math.random()); // el usuario mira la portada

  let workerId = null;
  group('2_busqueda_supabase', () => {
    const c = rpc('categorias_con_disponibles', {}, 'rpc_categorias');
    const cj = json(c);
    ok = check(c, {
      'categorias: status 200': (r) => r.status === 200,
      'categorias: arreglo con >= 1 oficio': () => Array.isArray(cj) && cj.length >= 1,
    }) && ok;

    const s = http.get(
      `${SB}/rest/v1/servicios?select=id,nombre,descripcion,categoria,activo,modelo_precio&activo=eq.1&order=nombre.asc&limit=80`,
      { headers: sbHeaders, tags: { name: 'rest_servicios', tipo: 'supabase' }, timeout: '30s' },
    );
    contar(s);
    const sj = json(s);
    ok = check(s, {
      'servicios: status 200': (r) => r.status === 200,
      'servicios: filas activas con nombre': () =>
        Array.isArray(sj) && sj.length > 0 && sj.every((x) => x.activo === 1 && !!x.nombre),
    }) && ok;

    const k = rpc(
      'listar_profesionales_catalogo',
      { p_categoria: cat, p_zona: null, p_cursor_calificacion: null, p_cursor_id: null, p_limit: 20 },
      'rpc_catalogo',
    );
    const kj = json(k);
    ok = check(k, {
      'catalogo: status 200': (r) => r.status === 200,
      'catalogo: arreglo JSON': () => Array.isArray(kj),
      'catalogo: filas del oficio pedido': () =>
        Array.isArray(kj) && kj.every((x) => x.categoria_servicio === cat),
      'catalogo: no expone correo': () =>
        Array.isArray(kj) && kj.every((x) => !('correo' in x) && !('email' in x)),
    }) && ok;
    if (Array.isArray(kj) && kj.length > 0) workerId = kj[(__ITER) % kj.length].id_usuario;
  });

  sleep(1 + Math.random()); // revisa las tarjetas y el mapa

  group('3_perfil_y_horas', () => {
    const id = workerId || '11111111-1111-4111-8111-000000000206';
    const h = rpc('horarios_libres_profesional', { p_id_trabajador: id, p_dias: 14 }, 'rpc_horarios_libres');
    const hj = json(h);
    ok = check(h, {
      'horarios: status 200': (r) => r.status === 200,
      'horarios: arreglo con campo inicio': () =>
        Array.isArray(hj) && hj.every((x) => typeof x.inicio === 'string'),
    }) && ok;

    // Control negativo: un anónimo no puede leer pedidos (RLS / grants).
    const t = http.get(`${SB}/rest/v1/trabajos?select=id&limit=1`, {
      headers: sbHeaders,
      tags: { name: 'rest_trabajos_anon_rls', tipo: 'supabase' },
      responseCallback: http.expectedStatuses(401, 403),
      timeout: '30s',
    });
    contar(t);
    const denied = t.status === 401 || t.status === 403;
    rlsDenegado.add(denied);
    ok = check(t, {
      'rls: anónimo NO lee trabajos (401/403)': () => denied,
      'rls: no devuelve filas': (r) => !Array.isArray(json(r)),
    }) && ok;
  });

  errores.add(!ok);
  sleep(1 + Math.random()); // pausa antes de la siguiente visita
}

export function edgeStatus() {
  let ok = true;
  const url = `${SB}/functions/v1/webpay-status?paymentId=${PAY_ID}&jobId=${JOB_ID}`;
  if (__ITER % 2 === 0) {
    const p = http.options(url, null, {
      headers: {
        Origin: ORIGIN,
        'Access-Control-Request-Method': 'GET',
        'Access-Control-Request-Headers': 'authorization,apikey,content-type',
      },
      tags: { name: 'edge_status_preflight', tipo: 'edge' },
      timeout: '30s',
    });
    contar(p);
    ok = check(p, {
      'edge preflight: status 200': (r) => r.status === 200,
      'edge preflight: CORS permite la web pública': (r) =>
        r.headers['Access-Control-Allow-Origin'] === ORIGIN,
    }) && ok;
  } else {
    const g = http.get(url, {
      headers: sbHeaders,
      tags: { name: 'edge_status_get', tipo: 'edge' },
      timeout: '30s',
    });
    contar(g);
    const gj = json(g);
    ok = check(g, {
      'edge status: 200': (r) => r.status === 200,
      'edge status: pago correcto': () => !!gj && gj.payment && gj.payment.id === PAY_ID,
      'edge status: no expone token_tbk/url_tbk': (r) => !/token_tbk|url_tbk/.test(r.body || ''),
    }) && ok;
  }
  errores.add(!ok);
}
