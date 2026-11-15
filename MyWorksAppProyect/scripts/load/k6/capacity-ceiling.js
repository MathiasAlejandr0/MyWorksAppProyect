/**
 * k6 — Techo de RPS sobre lectura marketplace (trabajadores).
 */
import http from 'k6/http';
import { check, sleep } from 'k6';

const url = (__ENV.SUPABASE_URL || '').replace(/\/$/, '');
const key = __ENV.SUPABASE_ANON_KEY || '';

if (!url || !key) {
  throw new Error('Faltan SUPABASE_URL y SUPABASE_ANON_KEY');
}

export const options = {
  scenarios: {
    ceiling: {
      executor: 'ramping-arrival-rate',
      startRate: 5,
      timeUnit: '1s',
      preAllocatedVUs: 50,
      maxVUs: 300,
      stages: [
        { duration: '30s', target: 10 },
        { duration: '30s', target: 25 },
        { duration: '30s', target: 50 },
        { duration: '30s', target: 75 },
        { duration: '30s', target: 100 },
        { duration: '1m', target: 100 },
        { duration: '30s', target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.10'],
    http_req_duration: ['p(95)<3000'],
  },
};

const headers = {
  apikey: key,
  Authorization: `Bearer ${key}`,
  Accept: 'application/json',
};

export default function () {
  const res = http.get(
    `${url}/rest/v1/trabajadores?select=id_usuario,profesion,tarifa_visita&disponible=eq.1&limit=20`,
    { headers, tags: { name: 'trabajadores_ceiling' } },
  );
  check(res, { '200': (r) => r.status === 200 });
  sleep(0.1);
}
