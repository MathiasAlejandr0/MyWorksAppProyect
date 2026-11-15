/**
 * Latencia secuencial (1 cliente) de los endpoints de lectura del marketplace.
 * No es carga: 5 calentamientos + N muestras con pausa. Comparable entre fechas.
 *
 * Uso:
 *   node scripts/load/rendimiento-latencia.mjs
 * Env: SUPABASE_URL, SUPABASE_ANON_KEY
 * Opcional: SUPABASE_EMAIL, SUPABASE_PASSWORD (sesión demo, no se guarda el JWT)
 *           SAMPLES (default 30), OUT (ruta JSON)
 */
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { performance } from 'node:perf_hooks';

const url = (process.env.SUPABASE_URL || '').replace(/\/$/, '');
const key = process.env.SUPABASE_ANON_KEY || '';
const samples = Number(process.env.SAMPLES || 30);
const warmup = Number(process.env.WARMUP || 5);
const pauseMs = Number(process.env.PAUSE_MS || 200);
const workerId =
  process.env.WORKER_ID || '11111111-1111-4111-8111-000000000206';
const outPath = resolve(
  process.env.OUT ||
    'docs/anexos/2026-11-08-rendimiento-carga/rendimiento/latencia-endpoints.json',
);

if (!url || !key) {
  console.error('Faltan SUPABASE_URL y SUPABASE_ANON_KEY');
  process.exit(1);
}

const PATRICIA = workerId;
const PEDRO = '11111111-1111-4111-8111-000000000101';

function percentile(sorted, p) {
  if (!sorted.length) return null;
  const rank = (p / 100) * (sorted.length - 1);
  const lo = Math.floor(rank);
  const hi = Math.ceil(rank);
  if (lo === hi) return round1(sorted[lo]);
  const w = rank - lo;
  return round1(sorted[lo] * (1 - w) + sorted[hi] * w);
}

function round1(n) {
  return Math.round(n * 10) / 10;
}

function stats(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const sum = sorted.reduce((a, b) => a + b, 0);
  return {
    n: sorted.length,
    min_ms: sorted.length ? round1(sorted[0]) : null,
    p50_ms: percentile(sorted, 50),
    p95_ms: percentile(sorted, 95),
    p99_ms: percentile(sorted, 99),
    max_ms: sorted.length ? round1(sorted[sorted.length - 1]) : null,
    mean_ms: sorted.length ? round1(sum / sorted.length) : null,
  };
}

async function once(name, method, path, body, extraHeaders = {}) {
  const headers = {
    apikey: key,
    Authorization: extraHeaders.Authorization || `Bearer ${key}`,
    Accept: 'application/json',
    ...extraHeaders,
  };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  const t0 = performance.now();
  let status = 0;
  let bytes = 0;
  let ok = false;
  let error = null;
  let json = null;
  try {
    const res = await fetch(`${url}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const buf = Buffer.from(await res.arrayBuffer());
    status = res.status;
    bytes = buf.length;
    ok = res.ok;
    try {
      json = JSON.parse(buf.toString('utf8'));
    } catch {
      json = null;
    }
  } catch (err) {
    error = err instanceof Error ? err.message : String(err);
  }
  const ms = performance.now() - t0;
  return { name, ms, status, bytes, ok, error, json };
}

async function measure(def) {
  const runs = [];
  for (let i = 0; i < warmup + samples; i++) {
    const result = await def.run();
    if (i >= warmup) {
      runs.push({
        i: i - warmup + 1,
        ms: round1(result.ms),
        status: result.status,
        bytes: result.bytes,
        ok: result.ok,
        error: result.error,
      });
    }
    if (pauseMs > 0) await new Promise((r) => setTimeout(r, pauseMs));
  }
  const last = await def.run();
  const keys =
    last.json && !Array.isArray(last.json) && typeof last.json === 'object'
      ? Object.keys(last.json)
      : Array.isArray(last.json) && last.json[0] && typeof last.json[0] === 'object'
        ? Object.keys(last.json[0])
        : [];
  const rows = Array.isArray(last.json) ? last.json.length : last.json == null ? 0 : 1;
  return {
    id: def.id,
    label: def.label,
    method: def.method,
    path: def.path,
    ...stats(runs.map((r) => r.ms)),
    error_n: runs.filter((r) => !r.ok).length,
    bytes_last: last.bytes,
    status_last: last.status,
    rows_last: rows,
    keys_last: keys,
    samples: runs,
  };
}

async function login(email, password) {
  const res = await fetch(`${url}/auth/v1/token?grant_type=password`, {
    method: 'POST',
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`login ${email} ${res.status}: ${text.slice(0, 180)}`);
  }
  const data = await res.json();
  return data.access_token;
}

const defs = [
  {
    id: 'servicios',
    label: 'REST servicios activos',
    method: 'GET',
    path: '/rest/v1/servicios?select=id,nombre,categoria,activo&activo=eq.1&limit=50',
    run: () =>
      once(
        'servicios',
        'GET',
        '/rest/v1/servicios?select=id,nombre,categoria,activo&activo=eq.1&limit=50',
      ),
  },
  {
    id: 'trabajadores_catalogo',
    label: 'REST trabajadores disponibles (columnas de listado)',
    method: 'GET',
    path: '/rest/v1/trabajadores?select=id_usuario,profesion,calificacion,disponible,tarifa_visita,categoria_servicio&disponible=eq.1&limit=40',
    run: () =>
      once(
        'trabajadores',
        'GET',
        '/rest/v1/trabajadores?select=id_usuario,profesion,calificacion,disponible,tarifa_visita,categoria_servicio&disponible=eq.1&limit=40',
      ),
  },
  {
    id: 'trabajador_fila',
    label: 'REST trabajador Patricia SELECT * (sin agenda semanal)',
    method: 'GET',
    path: `/rest/v1/trabajadores?id_usuario=eq.${PATRICIA}&select=*`,
    run: () =>
      once(
        'trabajador_fila',
        'GET',
        `/rest/v1/trabajadores?id_usuario=eq.${PATRICIA}&select=*`,
      ),
  },
  {
    id: 'rpc_categorias',
    label: 'RPC categorias_con_disponibles',
    method: 'POST',
    path: '/rest/v1/rpc/categorias_con_disponibles',
    run: () =>
      once(
        'rpc_categorias',
        'POST',
        '/rest/v1/rpc/categorias_con_disponibles',
        {},
      ),
  },
  {
    id: 'rpc_catalogo_gasfiteria',
    label: 'RPC listar_profesionales_catalogo gasfiteria',
    method: 'POST',
    path: '/rest/v1/rpc/listar_profesionales_catalogo',
    run: () =>
      once(
        'rpc_catalogo',
        'POST',
        '/rest/v1/rpc/listar_profesionales_catalogo',
        {
          p_categoria: 'gasfiteria',
          p_zona: null,
          p_cursor_calificacion: null,
          p_cursor_id: null,
          p_limit: 20,
        },
      ),
  },
  {
    id: 'rpc_catalogo_plomeria',
    label: 'RPC listar_profesionales_catalogo plomeria',
    method: 'POST',
    path: '/rest/v1/rpc/listar_profesionales_catalogo',
    run: () =>
      once(
        'rpc_catalogo_plomeria',
        'POST',
        '/rest/v1/rpc/listar_profesionales_catalogo',
        {
          p_categoria: 'plomeria',
          p_zona: null,
          p_cursor_calificacion: null,
          p_cursor_id: null,
          p_limit: 20,
        },
      ),
  },
  {
    id: 'rpc_huecos_patricia',
    label: 'RPC horarios_libres_profesional Patricia 14 días',
    method: 'POST',
    path: '/rest/v1/rpc/horarios_libres_profesional',
    run: () =>
      once(
        'rpc_huecos',
        'POST',
        '/rest/v1/rpc/horarios_libres_profesional',
        { p_id_trabajador: PATRICIA, p_dias: 14 },
      ),
  },
  {
    id: 'rpc_huecos_pedro',
    label: 'RPC horarios_libres_profesional Pedro 14 días',
    method: 'POST',
    path: '/rest/v1/rpc/horarios_libres_profesional',
    run: () =>
      once(
        'rpc_huecos_pedro',
        'POST',
        '/rest/v1/rpc/horarios_libres_profesional',
        { p_id_trabajador: PEDRO, p_dias: 14 },
      ),
  },
];

const started = new Date().toISOString();
const results = [];
for (const def of defs) {
  process.stderr.write(`midiando ${def.id}…\n`);
  results.push(await measure(def));
}

const auth = { camila: null, patricia: null };
const email = process.env.SUPABASE_EMAIL || '';
const password = process.env.SUPABASE_PASSWORD || '';
if (email && password) {
  process.stderr.write('sesión cliente…\n');
  try {
    const jwt = await login(email, password);
    const trabajosDef = {
      id: 'trabajos_cliente',
      label: 'REST trabajos del cliente autenticado',
      method: 'GET',
      path: '/rest/v1/trabajos?select=id,estado,estado_pago,creado_en&order=creado_en.desc&limit=20',
      run: () =>
        once(
          'trabajos',
          'GET',
          '/rest/v1/trabajos?select=id,estado,estado_pago,creado_en&order=creado_en.desc&limit=20',
          undefined,
          { Authorization: `Bearer ${jwt}` },
        ),
    };
    results.push(await measure(trabajosDef));
    auth.camila = { ok: true, email };
  } catch (err) {
    auth.camila = {
      ok: false,
      email,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

const workerEmail = process.env.SUPABASE_WORKER_EMAIL || '';
const workerPassword = process.env.SUPABASE_WORKER_PASSWORD || password;
if (workerEmail && workerPassword) {
  process.stderr.write('sesión profesional…\n');
  try {
    const jwt = await login(workerEmail, workerPassword);
    const agendaDef = {
      id: 'rpc_agenda_propia',
      label: 'RPC horarios_disponibles_propios (profesional)',
      method: 'POST',
      path: '/rest/v1/rpc/horarios_disponibles_propios',
      run: () =>
        once(
          'agenda',
          'POST',
          '/rest/v1/rpc/horarios_disponibles_propios',
          {},
          { Authorization: `Bearer ${jwt}` },
        ),
    };
    results.push(await measure(agendaDef));
    auth.patricia = { ok: true, email: workerEmail };
  } catch (err) {
    auth.patricia = {
      ok: false,
      email: workerEmail,
      error: err instanceof Error ? err.message : String(err),
    };
  }
}

const patriciaRow = results.find((r) => r.id === 'trabajador_fila');
const leak =
  patriciaRow && Array.isArray(patriciaRow.keys_last)
    ? patriciaRow.keys_last.includes('horarios_disponibles')
    : null;

const report = {
  kind: 'rendimiento-latencia-secuencial',
  protocolo: {
    samples,
    warmup,
    pause_ms: pauseMs,
    percentil: 'interpolación lineal sobre orden de estadísticas (p50/p95/p99)',
    cliente: 'node fetch, 1 conexión lógica a la vez',
  },
  entorno: {
    supabase_url: url,
    git_sha: process.env.GIT_SHA || null,
    measured_at: started,
    finished_at: new Date().toISOString(),
    node: process.version,
    worker_id: PATRICIA,
  },
  auth_used: {
    camila: auth.camila ? { ok: auth.camila.ok, email: auth.camila.email } : null,
    profesional: auth.patricia
      ? { ok: auth.patricia.ok, email: auth.patricia.email }
      : null,
  },
  rest_sin_agenda_semanal: leak === false,
  endpoints: results.map(({ samples: _s, ...rest }) => rest),
  series: Object.fromEntries(results.map((r) => [r.id, r.samples])),
};

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(report, null, 2), 'utf8');
console.log(JSON.stringify({ out: outPath, endpoints: report.endpoints.map((e) => ({
  id: e.id,
  p50_ms: e.p50_ms,
  p95_ms: e.p95_ms,
  error_n: e.error_n,
  bytes_last: e.bytes_last,
})) }, null, 2));
