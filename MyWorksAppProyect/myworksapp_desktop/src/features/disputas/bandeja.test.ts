import assert from 'node:assert/strict';
import test from 'node:test';
import { filtrarDisputas, ordenarDisputas, textoProcedencia } from './bandeja.ts';

test('la bandeja ordena alta antes que baja y filtra prioridad', () => {
  const filas = ordenarDisputas([
    { id: 'b', prioridad: 'baja', vence_en: '2026-11-01', asignado_a: null },
    { id: 'a', prioridad: 'alta', vence_en: '2026-11-20', asignado_a: 'yo' },
    { id: 'm', prioridad: 'media', vence_en: '2026-11-02', asignado_a: null },
  ]);
  assert.deepEqual(filas.map((fila) => fila.id), ['a', 'm', 'b']);
  assert.equal(filtrarDisputas(filas, 'alta', null).length, 1);
  assert.equal(filtrarDisputas(filas, 'sin_asignar', 'yo').length, 2);
  assert.equal(filtrarDisputas(filas, 'mias', 'yo')[0]?.id, 'a');
});

test('la procedencia distingue verificada de no verificada y el duplicado', () => {
  assert.match(textoProcedencia({
    confianza: 'no_verificada',
    tipo_evidencia: 'detalle',
    distancia_metros: 2400,
    duplicado: true,
    origen_captura: 'web_archivo',
  }), /No verificada/);
  assert.match(textoProcedencia({
    confianza: 'confiable',
    tipo_evidencia: 'despues',
    distancia_metros: 12,
    duplicado: false,
    origen_captura: 'camara_app',
  }), /Verificada/);
  assert.match(textoProcedencia({ confianza: 'confiable', duplicado: true }), /Duplicada/);
});
