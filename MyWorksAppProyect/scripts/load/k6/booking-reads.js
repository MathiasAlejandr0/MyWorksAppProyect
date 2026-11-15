/**
 * k6 — Lecturas del funnel de reserva (anon, solo RPC).
 * Profiles: smoke | baseline | stress
 *
 * Simula: listar catálogo + huecos libres de un profesional publicado.
 * No escribe, no llama Webpay ni guest-checkout.
 *
 * horarios_libres_profesional recorre plantilla × días; por eso el stress
 * sube menos VUs que catalog.js (REST liviano).
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const url = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const key = __ENV.SUPABASE_ANON_KEY || '';
const profile = (__ENV.PROFILE || 'baseline').toLowerCase();
const workerId =
  __ENV.K6_WORKER_ID || '11111111-1111-4111-8111-000000000206';
const categoria = __ENV.K6_CATEGORIA || 'gasfiteria';

if (!url || !key) {
  throw new Error('Faltan SUPABASE_URL y SUPABASE_ANON_KEY');
}

const errorRate = new Rate('mwa_errors');
const catalogoMs = new Trend('mwa_rpc_catalogo_ms');
const huecosMs = new Trend('mwa_rpc_huecos_ms');
const categoriasMs = new Trend('mwa_rpc_categorias_ms');

const profiles = {
  smoke: { executor: 'constant-vus', vus: 5, duration: '30s' },
  baseline: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 10 },
      { duration: '1m', target: 30 },
      { duration: '1m', target: 30 },
      { duration: '30s', target: 0 },
    ],
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '45s', target: 30 },
      { duration: '1m', target: 60 },
      { duration: '1m', target: 80 },
      { duration: '1m', target: 80 },
      { duration: '30s', target: 0 },
    ],
  },
};

export const options = {
  scenarios: {
    booking: profiles[profile] || profiles.baseline,
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000'],
    mwa_errors: ['rate<0.05'],
  },
};

const headers = {
  apikey: key,
  Authorization: `Bearer ${key}`,
  Accept: 'application/json',
  'Content-Type': 'application/json',
};

function rpc(name, body, tag) {
  return http.post(`${url}/rest/v1/rpc/${name}`, JSON.stringify(body), {
    headers,
    tags: { name: tag },
  });
}

export default function () {
  const cats = rpc('categorias_con_disponibles', {}, 'rpc_categorias');
  categoriasMs.add(cats.timings.duration);
  const okCats = check(cats, {
    'categorias 200': (r) => r.status === 200,
  });

  const catalogo = rpc(
    'listar_profesionales_catalogo',
    {
      p_categoria: categoria,
      p_zona: null,
      p_cursor_calificacion: null,
      p_cursor_id: null,
      p_limit: 20,
    },
    'rpc_catalogo',
  );
  catalogoMs.add(catalogo.timings.duration);
  const okCat = check(catalogo, {
    'catalogo 200': (r) => r.status === 200,
    'catalogo con filas': (r) => {
      try {
        const rows = r.json();
        return Array.isArray(rows) && rows.length > 0;
      } catch {
        return false;
      }
    },
  });

  const huecos = rpc(
    'horarios_libres_profesional',
    { p_id_trabajador: workerId, p_dias: 14 },
    'rpc_huecos',
  );
  huecosMs.add(huecos.timings.duration);
  const okHuecos = check(huecos, {
    'huecos 200': (r) => r.status === 200,
    'huecos con filas': (r) => {
      try {
        const rows = r.json();
        return Array.isArray(rows) && rows.length > 0;
      } catch {
        return false;
      }
    },
  });

  errorRate.add(!(okCats && okCat && okHuecos));
  sleep(Number(__ENV.THINK_TIME || 1));
}
