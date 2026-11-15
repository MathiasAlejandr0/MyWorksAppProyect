/**
 * Tamaño y columnas de la fila pública del profesional vista por un cliente.
 * Complementa la latencia anon (RLS vacía). No guarda el JWT.
 */
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const url = (process.env.SUPABASE_URL || '').replace(/\/$/, '');
const key = process.env.SUPABASE_ANON_KEY || '';
const email = process.env.SUPABASE_EMAIL || '';
const password = process.env.SUPABASE_PASSWORD || '';
const workerId =
  process.env.WORKER_ID || '11111111-1111-4111-8111-000000000206';
const outPath = resolve(
  process.env.OUT ||
    'docs/anexos/2026-11-08-rendimiento-carga/rendimiento/trabajador-cliente-payload.json',
);

const loginRes = await fetch(`${url}/auth/v1/token?grant_type=password`, {
  method: 'POST',
  headers: {
    apikey: key,
    Authorization: `Bearer ${key}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ email, password }),
});
if (!loginRes.ok) {
  throw new Error(`login ${loginRes.status} ${await loginRes.text()}`);
}
const { access_token: jwt } = await loginRes.json();
const headers = {
  apikey: key,
  Authorization: `Bearer ${jwt}`,
  Accept: 'application/json',
};

const t0 = performance.now();
const res = await fetch(
  `${url}/rest/v1/trabajadores?id_usuario=eq.${workerId}&select=*`,
  { headers },
);
const buf = Buffer.from(await res.arrayBuffer());
const ms = Math.round((performance.now() - t0) * 10) / 10;
const json = JSON.parse(buf.toString('utf8'));
const row = Array.isArray(json) ? json[0] : json;
const keys = row && typeof row === 'object' ? Object.keys(row) : [];

const report = {
  kind: 'trabajador-vista-cliente',
  measured_at: new Date().toISOString(),
  git_sha: process.env.GIT_SHA || null,
  viewer: email,
  worker_id: workerId,
  status: res.status,
  ms,
  bytes: buf.length,
  rows: Array.isArray(json) ? json.length : 0,
  keys,
  tiene_horarios_disponibles: keys.includes('horarios_disponibles'),
};

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(report, null, 2), 'utf8');
console.log(JSON.stringify({ out: outPath, bytes: report.bytes, keys_n: keys.length, leak: report.tiene_horarios_disponibles, ms }, null, 2));
