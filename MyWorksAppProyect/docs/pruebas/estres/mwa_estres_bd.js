// Prueba de estrés de la base de datos de MyWorksApp (PostgREST + RPC de Supabase).
//
// Ejecuta una mezcla realista de lecturas anónimas (catálogo), lecturas con
// sesión (RLS) y escrituras (solo datos de prueba qa-audit-stress-*), subiendo
// por escalones de 10, 50, 100 y 200 usuarios virtuales y terminando con un pico
// brusco. Cada request lleva la etiqueta "etapa" para analizar cada escalón.
//
// Uso: k6 run -e SB_URL=... -e SB_ANON=... -e QA_PW=... mwa_estres_bd.js
// QA_PW es la contraseña de los usuarios temporales qa.audit.*; no se guarda.
import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

const URL = __ENV.SB_URL;
const ANON = __ENV.SB_ANON;
const PW = __ENV.QA_PW;
const USERS = ['cliente1', 'cliente2', 'cliente3', 'cliente4', 'pro1', 'pro2'];
const JOB = 'qa-audit-job-1';

// Línea de tiempo (segundos desde el inicio) -> etapa medida.
const ETAPAS = [
  [0, 30, 'rampa'], [30, 90, 'E010'], [90, 120, 'rampa'], [120, 180, 'E050'],
  [180, 210, 'rampa'], [210, 270, 'E100'], [270, 300, 'rampa'], [300, 360, 'E200'],
  [360, 390, 'rampa'], [390, 420, 'R020'], [420, 430, 'rampa'], [430, 460, 'PICO'],
  [460, 999, 'rampa'],
];
function etapa(t) {
  for (const [a, b, n] of ETAPAS) if (t >= a && t < b) return n;
  return 'rampa';
}

const errores = new Counter('errores_negocio');
const tOp = {};
for (const op of ['catalogo', 'categorias', 'horarios', 'servicios', 'mis_trabajos', 'notificaciones', 'chat', 'escribir_mensaje', 'evento_analitica', 'marcar_leido']) {
  tOp[op] = new Trend(`op_${op}`, true);
}

const th = { http_req_failed: ['rate<0.05'] };
for (const e of ['E010', 'E050', 'E100', 'E200', 'R020', 'PICO']) {
  th[`http_req_duration{etapa:${e}}`] = ['p(95)<3000'];
  th[`http_req_failed{etapa:${e}}`] = ['rate<0.05'];
  th[`http_reqs{etapa:${e}}`] = ['count>=0'];
}

export const options = {
  scenarios: {
    estres: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 10 }, { duration: '60s', target: 10 },
        { duration: '30s', target: 50 }, { duration: '60s', target: 50 },
        { duration: '30s', target: 100 }, { duration: '60s', target: 100 },
        { duration: '30s', target: 200 }, { duration: '60s', target: 200 },
        { duration: '30s', target: 20 }, { duration: '30s', target: 20 },
        { duration: '10s', target: 200 }, { duration: '30s', target: 200 },
        { duration: '20s', target: 0 },
      ],
      gracefulRampDown: '10s',
    },
  },
  thresholds: th,
  summaryTrendStats: ['avg', 'min', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
  discardResponseBodies: false,
};

export function setup() {
  const tok = {};
  const ids = {};
  for (const u of USERS) {
    const r = http.post(`${URL}/auth/v1/token?grant_type=password`,
      JSON.stringify({ email: `qa.audit.${u}@test.myworksapp.cl`, password: PW }),
      { headers: { apikey: ANON, 'Content-Type': 'application/json' } });
    if (r.status !== 200) throw new Error(`login ${u}: ${r.status}`);
    tok[u] = r.json('access_token');
    ids[u] = r.json('user.id');
  }
  const h = { headers: { apikey: ANON, Authorization: `Bearer ${ANON}`, 'Content-Type': 'application/json' } };
  const cats = http.post(`${URL}/rest/v1/rpc/categorias_con_disponibles`, '{}', h).json();
  const categorias = (cats || []).map((c) => (typeof c === 'string' ? c : Object.values(c)[0])).filter(Boolean);
  const pros = http.post(`${URL}/rest/v1/rpc/listar_profesionales_catalogo`,
    JSON.stringify({ p_categoria: categorias[0], p_zona: null, p_cursor_calificacion: null, p_cursor_id: null, p_limit: 20 }), h).json();
  const proIds = (pros || []).map((p) => p.id_usuario || p.id).filter(Boolean);
  return { tok, ids, categorias, proIds, inicio: Date.now() };
}

function hdr(d, who, extra) {
  const hd = { apikey: ANON, 'Content-Type': 'application/json', Authorization: `Bearer ${who ? d.tok[who] : ANON}` };
  return Object.assign(hd, extra || {});
}

function pick(a) { return a[Math.floor(Math.random() * a.length)]; }

function call(op, d, res, okStatus) {
  tOp[op].add(res.timings.duration);
  const ok = check(res, { [`${op} ${okStatus.join('/')}`]: (r) => okStatus.includes(r.status) });
  if (!ok) errores.add(1, { op });
}

export default function (d) {
  const tags = { etapa: etapa((Date.now() - d.inicio) / 1000) };
  const x = Math.random();
  if (x < 0.25) {
    const r = http.post(`${URL}/rest/v1/rpc/listar_profesionales_catalogo`,
      JSON.stringify({ p_categoria: pick(d.categorias), p_zona: null, p_cursor_calificacion: null, p_cursor_id: null, p_limit: 20 }),
      { headers: hdr(d), tags: Object.assign({ op: 'catalogo' }, tags) });
    call('catalogo', d, r, [200]);
  } else if (x < 0.35) {
    const r = http.post(`${URL}/rest/v1/rpc/categorias_con_disponibles`, '{}', { headers: hdr(d), tags: Object.assign({ op: 'categorias' }, tags) });
    call('categorias', d, r, [200]);
  } else if (x < 0.50) {
    const r = http.post(`${URL}/rest/v1/rpc/horarios_libres_profesional`,
      JSON.stringify({ p_id_trabajador: pick(d.proIds), p_dias: 14 }), { headers: hdr(d), tags: Object.assign({ op: 'horarios' }, tags) });
    call('horarios', d, r, [200]);
  } else if (x < 0.60) {
    const r = http.get(`${URL}/rest/v1/servicios?select=id,nombre,categoria,activo&activo=eq.1`, { headers: hdr(d), tags: Object.assign({ op: 'servicios' }, tags) });
    call('servicios', d, r, [200]);
  } else if (x < 0.72) {
    const u = pick(USERS);
    const col = u.startsWith('pro') ? 'id_trabajador' : 'id_usuario';
    const r = http.get(`${URL}/rest/v1/trabajos?select=id,estado,estado_pago,creado_en&${col}=eq.${d.ids[u]}&order=creado_en.desc&limit=50`,
      { headers: hdr(d, u), tags: Object.assign({ op: 'mis_trabajos' }, tags) });
    call('mis_trabajos', d, r, [200]);
  } else if (x < 0.80) {
    const u = pick(USERS);
    const r = http.get(`${URL}/rest/v1/notificaciones?select=id,titulo,leido,creado_en&id_usuario=eq.${d.ids[u]}&order=creado_en.desc&limit=30`,
      { headers: hdr(d, u), tags: Object.assign({ op: 'notificaciones' }, tags) });
    call('notificaciones', d, r, [200]);
  } else if (x < 0.90) {
    const u = pick(['cliente1', 'pro1']);
    const r = http.get(`${URL}/rest/v1/mensajes?select=id,contenido,id_remitente,creado_en,leido&id_trabajo=eq.${JOB}&order=creado_en.asc&limit=100`,
      { headers: hdr(d, u), tags: Object.assign({ op: 'chat' }, tags) });
    call('chat', d, r, [200]);
  } else if (x < 0.95) {
    const u = pick(['cliente1', 'pro1']);
    const otro = u === 'cliente1' ? 'pro1' : 'cliente1';
    const id = `qa-audit-stress-${__VU}-${__ITER}-${Date.now()}`;
    const r = http.post(`${URL}/rest/v1/mensajes`, JSON.stringify({
      id, id_trabajo: JOB, id_remitente: d.ids[u], id_destinatario: d.ids[otro],
      contenido: 'mensaje de prueba de estres', tipo: 'texto', leido: 0, creado_en: new Date().toISOString(),
    }), { headers: hdr(d, u, { Prefer: 'return=minimal' }), tags: Object.assign({ op: 'escribir_mensaje' }, tags) });
    call('escribir_mensaje', d, r, [201]);
  } else if (x < 0.98) {
    const u = pick(USERS);
    const r = http.post(`${URL}/rest/v1/eventos_analitica`, JSON.stringify({
      id: `qa-audit-stress-${__VU}-${__ITER}-${Date.now()}`, nombre_evento: 'qa_audit_stress', id_usuario: d.ids[u],
      rol: u.startsWith('pro') ? 'trabajador' : 'usuario', marca_tiempo: new Date().toISOString(), metadatos: '{}',
    }), { headers: hdr(d, u, { Prefer: 'return=minimal' }), tags: Object.assign({ op: 'evento_analitica' }, tags) });
    call('evento_analitica', d, r, [201]);
  } else {
    const r = http.patch(`${URL}/rest/v1/mensajes?id=eq.qa-audit-msg-2&id_trabajo=eq.${JOB}`, JSON.stringify({ leido: 1 }),
      { headers: hdr(d, 'cliente1', { Prefer: 'return=minimal' }), tags: Object.assign({ op: 'marcar_leido' }, tags) });
    call('marcar_leido', d, r, [204, 200]);
  }
  sleep(0.5 + Math.random());
}
