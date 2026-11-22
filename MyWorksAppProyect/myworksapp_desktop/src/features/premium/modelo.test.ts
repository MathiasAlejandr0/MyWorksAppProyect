import assert from 'node:assert/strict';
import test from 'node:test';
import { clasificarComentario, rango, redactar, variacion, ventanaVirtual } from './modelo.ts';

test('clasifica por estrellas y marca temas', () => {
  const buena = clasificarComentario(5, 'Llegó puntual y dejó todo limpio');
  assert.equal(buena.sentimiento, 'positivo');
  assert.equal(buena.fuente, 'reglas_estrellas');
  assert.deepEqual(buena.temas, ['puntualidad', 'limpieza']);
  assert.equal(buena.alertaGrave, false);

  const grave = clasificarComentario(1, 'No llegó y el trato fue una amenaza');
  assert.equal(grave.sentimiento, 'negativo');
  assert.equal(grave.alertaGrave, true);
  assert.ok(grave.temas.includes('alerta_grave'));

  assert.equal(clasificarComentario(3, 'Normal').sentimiento, 'neutro');
  assert.equal(clasificarComentario(null, '').sentimiento, 'sin_dato');
});

test('la variación compara contra el período anterior', () => {
  assert.equal(variacion(150, 100), 50);
  assert.equal(variacion(50, 100), -50);
  assert.equal(variacion(0, 0), 0);
  assert.equal(variacion(10, 0), null);
  assert.equal(variacion(null, 4), null);
});

test('redacta rut, teléfono y correo', () => {
  const limpio = redactar('RUT 12.345.678-5, fono +56912345678, ana@correo.cl');
  assert.equal(limpio.includes('12.345'), false);
  assert.equal(limpio.includes('ana@'), false);
  assert.equal(limpio.includes('[dato]'), true);
});

test('el rango deja el período anterior del mismo largo', () => {
  const fechas = rango(7, new Date('2026-11-22T15:00:00Z'));
  const largo = new Date(fechas.hasta).getTime() - new Date(fechas.desde).getTime();
  const anterior = new Date(fechas.anteriorHasta).getTime() - new Date(fechas.anteriorDesde).getTime();
  assert.equal(largo, 7 * 86_400_000);
  assert.equal(anterior, largo);
  assert.equal(fechas.anteriorHasta, fechas.desde);
});

test('la ventana virtual no pinta las 10.000 filas', () => {
  const arriba = ventanaVirtual(0, 360, 36, 10_000);
  assert.ok(arriba.fin - arriba.inicio < 30);
  const fondo = ventanaVirtual(10_000 * 36 - 360, 360, 36, 10_000);
  assert.ok(fondo.inicio > 9800);
  assert.equal(fondo.fin, 10_000);
});
