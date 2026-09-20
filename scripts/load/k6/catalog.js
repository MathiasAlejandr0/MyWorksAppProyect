/**
 * k6 — Lectura marketplace (anon): oficios + profesionales.
 * Profiles: smoke | baseline | stress | soak
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const url = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const key = __ENV.SUPABASE_ANON_KEY || '';
const profile = (__ENV.PROFILE || 'baseline').toLowerCase();

if (!url || !key) {
  throw new Error('Faltan SUPABASE_URL y SUPABASE_ANON_KEY');
}

const errorRate = new Rate('mwa_errors');
const serviciosMs = new Trend('mwa_servicios_ms');
const trabajadoresMs = new Trend('mwa_trabajadores_ms');

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
};

export const options = {
  scenarios: {
    catalog: profiles[profile] || profiles.baseline,
  },
  thresholds: {
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
  });

  errorRate.add(!(okS && okT));
  sleep(Number(__ENV.THINK_TIME || 1));
}
