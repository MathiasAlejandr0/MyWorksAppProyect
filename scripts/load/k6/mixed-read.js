/**
 * k6 — Mezcla lectura pública + (opcional) lectura autenticada de trabajos.
 *
 * Sin JWT: solo catálogo (mismo que catalog.js).
 * Con JWT de un usuario de prueba:
 *   -e SUPABASE_USER_JWT=eyJ...
 *
 * No crea pagos ni llama Edge Webpay.
 */
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const url = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const key = __ENV.SUPABASE_ANON_KEY || '';
const userJwt = __ENV.SUPABASE_USER_JWT || '';
const profile = (__ENV.PROFILE || 'baseline').toLowerCase();

if (!url || !key) {
  throw new Error('Faltan SUPABASE_URL y SUPABASE_ANON_KEY');
}

const errorRate = new Rate('mwa_errors');

const profiles = {
  smoke: { executor: 'constant-vus', vus: 5, duration: '30s' },
  baseline: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 15 },
      { duration: '1m', target: 40 },
      { duration: '1m', target: 40 },
      { duration: '30s', target: 0 },
    ],
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '1m', target: 40 },
      { duration: '1m', target: 80 },
      { duration: '1m', target: 150 },
      { duration: '2m', target: 150 },
      { duration: '1m', target: 0 },
    ],
  },
  soak: { executor: 'constant-vus', vus: 30, duration: '10m' },
};

export const options = {
  scenarios: {
    mixed: profiles[profile] || profiles.baseline,
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<2000'],
    mwa_errors: ['rate<0.05'],
  },
};

function anonHeaders() {
  return {
    apikey: key,
    Authorization: `Bearer ${key}`,
    Accept: 'application/json',
  };
}

function userHeaders() {
  return {
    apikey: key,
    Authorization: `Bearer ${userJwt}`,
    Accept: 'application/json',
  };
}

export default function () {
  let ok = true;

  const s = http.get(
    `${url}/rest/v1/servicios?select=id,nombre,categoria&activo=eq.1&limit=30`,
    { headers: anonHeaders(), tags: { name: 'servicios' } },
  );
  ok = check(s, { 'servicios 200': (r) => r.status === 200 }) && ok;

  const w = http.get(
    `${url}/rest/v1/trabajadores?select=id_usuario,profesion,tarifa_visita&disponible=eq.1&limit=30`,
    { headers: anonHeaders(), tags: { name: 'trabajadores' } },
  );
  ok = check(w, { 'trabajadores 200': (r) => r.status === 200 }) && ok;

  if (userJwt) {
    const jobs = http.get(
      `${url}/rest/v1/trabajos?select=id,estado,estado_pago,creado_en&order=creado_en.desc&limit=20`,
      { headers: userHeaders(), tags: { name: 'trabajos_auth' } },
    );
    ok =
      check(jobs, {
        'trabajos 200 o vacío ok': (r) => r.status === 200 || r.status === 406,
      }) && ok;
  }

  errorRate.add(!ok);
  sleep(Number(__ENV.THINK_TIME || 1.2));
}
