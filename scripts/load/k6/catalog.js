/**
 * k6 — Lectura marketplace (anon): oficios + profesionales.
 * Profiles: smoke | baseline | stress | soak | free-ceiling
 *
 * free-ceiling: 100→300 VUs, solo lecturas públicas.
 * Umbrales: error < 1 %, p95 < 500 ms (techo Free medible).
 *
 * Opcional: K6_USE_RPC=1 llama listar_profesionales_catalogo (tras migrar 20260926).
 * No incluir Webpay ni guest-checkout.
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const url = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const key = __ENV.SUPABASE_ANON_KEY || '';
const profile = (__ENV.PROFILE || 'baseline').toLowerCase();
const useRpc = (__ENV.K6_USE_RPC || '') === '1';

if (!url || !key) {
  throw new Error('Faltan SUPABASE_URL y SUPABASE_ANON_KEY');
}

const errorRate = new Rate('mwa_errors');
const serviciosMs = new Trend('mwa_servicios_ms');
const trabajadoresMs = new Trend('mwa_trabajadores_ms');
const rpcMs = new Trend('mwa_rpc_catalogo_ms');

const profiles = {
  smoke: { executor: 'constant-vus', vus: 5, duration: '30s' },
  baseline: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 20 },
      { duration: '1m', target: 50 },
      { duration: '1m', target: 50 },
      { duration: '30s', target: 0 },
    ],
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '1m', target: 50 },
      { duration: '1m', target: 100 },
      { duration: '1m', target: 200 },
      { duration: '2m', target: 200 },
      { duration: '1m', target: 0 },
    ],
  },
  soak: { executor: 'constant-vus', vus: 40, duration: '10m' },
  'free-ceiling': {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 100 },
      { duration: '1m', target: 200 },
      { duration: '1m', target: 300 },
      { duration: '2m', target: 300 },
      { duration: '30s', target: 0 },
    ],
  },
};

const tight = profile === 'free-ceiling';

export const options = {
  scenarios: {
    catalog: profiles[profile] || profiles.baseline,
  },
  thresholds: tight
    ? {
        http_req_failed: ['rate<0.01'],
        http_req_duration: ['p(95)<500'],
        mwa_errors: ['rate<0.01'],
      }
    : {
        http_req_failed: ['rate<0.05'],
        http_req_duration: ['p(95)<1500'],
        mwa_errors: ['rate<0.05'],
      },
};

const headers = {
  apikey: key,
  Authorization: `Bearer ${key}`,
  Accept: 'application/json',
};

function get(path, tag) {
  return http.get(`${url}/rest/v1/${path}`, { headers, tags: { name: tag } });
}

export default function () {
  const s = get(
    'servicios?select=id,nombre,categoria,activo&activo=eq.1&limit=50',
    'servicios',
  );
  serviciosMs.add(s.timings.duration);
  const okS = check(s, {
    'servicios 200': (r) => r.status === 200,
    'servicios no 401': (r) => r.status !== 401,
    'servicios array': (r) => {
      try {
        return Array.isArray(r.json());
      } catch {
        return false;
      }
    },
  });

  const t = get(
    'trabajadores?select=id_usuario,profesion,calificacion,disponible,tarifa_visita,categoria_servicio&disponible=eq.1&limit=40',
    'trabajadores',
  );
  trabajadoresMs.add(t.timings.duration);
  const okT = check(t, {
    'trabajadores 200': (r) => r.status === 200,
    'trabajadores no 401': (r) => r.status !== 401,
  });

  let okRpc = true;
  if (useRpc) {
    const rpc = http.post(
      `${url}/rest/v1/rpc/listar_profesionales_catalogo`,
      JSON.stringify({
        p_categoria: 'electricidad',
        p_zona: null,
        p_cursor_calificacion: null,
        p_cursor_id: null,
        p_limit: 20,
      }),
      {
        headers: { ...headers, 'Content-Type': 'application/json' },
        tags: { name: 'rpc_catalogo' },
      },
    );
    rpcMs.add(rpc.timings.duration);
    okRpc = check(rpc, {
      'rpc catalogo 200': (r) => r.status === 200,
    });
  }

  errorRate.add(!(okS && okT && okRpc));
  sleep(Number(__ENV.THINK_TIME || 1));
}
