/**
 * k6 contra PostgREST local: solo listar_profesionales_catalogo.
 * Rampa hasta 300 VU. No apunta a producción.
 *
 *   K6_URL=http://127.0.0.1:3000 K6_JWT=... k6 run catalogo-real.js
 */
import http from 'k6/http';
import exec from 'k6/execution';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const url = (__ENV.K6_URL || 'http://127.0.0.1:3000').replace(/\/$/, '');
const jwt = __ENV.K6_JWT || '';
if (!jwt) throw new Error('Falta K6_JWT');

const duracion = new Trend('catalogo_ms');
const errores = new Rate('catalogo_errores');

export const options = {
  scenarios: {
    catalogo: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '20s', target: 50 },
        { duration: '25s', target: 100 },
        { duration: '25s', target: 150 },
        { duration: '25s', target: 200 },
        { duration: '25s', target: 280 },
        { duration: '30s', target: 300 },
        { duration: '15s', target: 0 },
      ],
    },
  },
  summaryTrendStats: ['avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'count'],
  thresholds: {
    'catalogo_ms{banda:50}': ['p(95)<60000'],
    'catalogo_ms{banda:100}': ['p(95)<60000'],
    'catalogo_ms{banda:150}': ['p(95)<60000'],
    'catalogo_ms{banda:200}': ['p(95)<60000'],
    'catalogo_ms{banda:280}': ['p(95)<60000'],
    'catalogo_ms{banda:300}': ['p(95)<60000'],
  },
};

function banda() {
  const vus = exec.instance.vusActive;
  if (vus <= 60) return '50';
  if (vus <= 120) return '100';
  if (vus <= 170) return '150';
  if (vus <= 230) return '200';
  if (vus <= 290) return '280';
  return '300';
}

export default function () {
  const res = http.post(
    `${url}/rpc/listar_profesionales_catalogo`,
    JSON.stringify({
      p_categoria: 'electricidad',
      p_limit: 20,
      p_latitud: -41.47,
      p_longitud: -72.94,
    }),
    {
      headers: {
        apikey: jwt,
        Authorization: `Bearer ${jwt}`,
        'Content-Type': 'application/json',
      },
      tags: { banda: banda() },
      timeout: '30s',
    },
  );
  const ok = check(res, {
    '200': (r) => r.status === 200,
    'filas': (r) => {
      try {
        return Array.isArray(r.json()) && r.json().length > 0;
      } catch {
        return false;
      }
    },
  });
  duracion.add(res.timings.duration, { banda: banda() });
  errores.add(!ok);
  sleep(0.1);
}
