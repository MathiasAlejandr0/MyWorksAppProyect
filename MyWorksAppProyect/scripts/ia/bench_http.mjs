/**
 * Servidor local para k6. /antes recalcula stats por profesional.
 * /despues lee el agregado, como mv_stats_profesional.
 * No usa Supabase.
 */
import http from 'node:http';
import { pathToFileURL } from 'node:url';

const N = 800;
const pros = Array.from({ length: N }, (_, i) => ({
  id: i,
  reviews: [4, 5, 4, 3 + (i % 2)],
  jobs: ['completado', 'completado', 'cancelado', 'completado'],
}));

function stats(pro) {
  const n = pro.reviews.length;
  const calificacion = pro.reviews.reduce((s, nro) => s + nro, 0) / n;
  const done = pro.jobs.filter((j) => j === 'completado').length;
  return { id: pro.id, calificacion, done };
}

const vista = pros.map(stats);

function porFila() {
  return pros.map(stats).sort((a, b) => b.calificacion - a.calificacion).slice(0, 20);
}

function porVista() {
  return vista.slice().sort((a, b) => b.calificacion - a.calificacion).slice(0, 20);
}

const server = http.createServer((req, res) => {
  const ruta = (req.url || '/').split('?')[0];
  const cuerpo = JSON.stringify(ruta === '/antes' ? porFila() : porVista());
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(cuerpo);
});

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  server.listen(8791, '127.0.0.1');
}

export { porFila, porVista };
