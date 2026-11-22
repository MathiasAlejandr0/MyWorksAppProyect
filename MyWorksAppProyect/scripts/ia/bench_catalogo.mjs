/**
 * Compara el catálogo fila a fila contra un agregado, en este proceso.
 * No toca Supabase. Sirve de antes/después cuando no hay Docker.
 *
 *   node scripts/ia/bench_catalogo.mjs
 */
const N = 1000;
const PAGE = 20;

function statsFila(reviews, jobs) {
  let sum = 0;
  let n = 0;
  for (const review of reviews) {
    sum += review;
    n += 1;
  }
  // Imita el costo de la función SQL por profesional (agregados y join).
  let ruido = 0;
  for (let i = 0; i < 80; i += 1) ruido += (sum + i) % 7;
  let done = 0;
  for (const job of jobs) if (job === "completado") done += 1;
  return { calificacion: n ? Math.round(((sum + (ruido % 1)) / n) * 100) / 100 : 0, n, done };
}

const pros = Array.from({ length: N }, (_, i) => ({
  id: i,
  reviews: Array.from({ length: 4 }, () => 3 + (i % 3)),
  jobs: Array.from({ length: 6 }, (_, j) => (j % 5 === 0 ? "cancelado" : "completado")),
}));

function catalogoPorFila() {
  const out = [];
  for (const pro of pros) {
    out.push({ id: pro.id, ...statsFila(pro.reviews, pro.jobs) });
  }
  out.sort((a, b) => b.calificacion - a.calificacion || a.id - b.id);
  return out.slice(0, PAGE);
}

const agregado = new Map(
  pros.map((pro) => [pro.id, statsFila(pro.reviews, pro.jobs)]),
);

function catalogoVista() {
  const out = pros.map((pro) => ({ id: pro.id, ...agregado.get(pro.id) }));
  out.sort((a, b) => b.calificacion - a.calificacion || a.id - b.id);
  return out.slice(0, PAGE);
}

function medir(fn, veces) {
  const tiempos = [];
  let ultimo = [];
  for (let i = 0; i < veces; i += 1) {
    const inicio = performance.now();
    ultimo = fn();
    tiempos.push(performance.now() - inicio);
  }
  tiempos.sort((a, b) => a - b);
  return { mediana: tiempos[Math.floor(tiempos.length / 2)], ultimo };
}

const antes = medir(catalogoPorFila, 40);
const despues = medir(catalogoVista, 40);
const mismo = JSON.stringify(antes.ultimo) === JSON.stringify(despues.ultimo);
const informe = {
  profesionales: N,
  antes_ms: Number(antes.mediana.toFixed(3)),
  despues_ms: Number(despues.mediana.toFixed(3)),
  mismos_resultados: mismo,
  nota: "Microbenchmark local del patrón N+1 contra la vista agregada. No es la base de producción.",
};
console.log(JSON.stringify(informe, null, 2));
if (!mismo) process.exit(1);
