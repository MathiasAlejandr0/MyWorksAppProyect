import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { formatClp, formatDateTime, statusLabel } from './format.ts';

describe('formato de la consola', () => {
  it('muestra pesos chilenos', () => {
    assert.match(formatClp(1000), /1\.000/);
    assert.equal(formatClp(null), '—');
  });

  it('indica la zona de Santiago', () => {
    const text = formatDateTime('2026-11-20T15:00:00.000Z');
    assert.match(text, /CLT/);
    assert.doesNotMatch(text, /NaN/);
  });

  it('no muestra el valor técnico de un pago', () => {
    assert.equal(statusLabel('pagado_por_confirmar'), 'Pagado por confirmar');
    assert.equal(statusLabel('retenido'), 'Retenido');
    assert.equal(statusLabel('alta'), 'Alta');
    assert.equal(statusLabel('algo_desconocido'), 'Estado no reconocido');
  });
});
