/**
 * k6 local del catálogo. Compara /antes (stats por fila) y /despues (vista).
 * Levantar antes: node MyWorksAppProyect/scripts/ia/bench_http.mjs
 * No apunta a producción.
 */
import http from 'k6/http';
import { check, sleep } from 'k6';

const base = (__ENV.BENCH_URL || 'http://127.0.0.1:8791').replace(/\/$/, '');
const ruta = __ENV.RUTA || 'despues';

export const options = {
  vus: 20,
  duration: '20s',
  thresholds: {
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get(`${base}/${ruta}`);
  check(res, { '200': (r) => r.status === 200 });
  sleep(0.2);
}
