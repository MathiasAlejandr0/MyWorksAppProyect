import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { categoryFromPath, pathForView, viewFromPath } from './paths.ts';

describe('rutas de la web', () => {
  it('reconoce las rutas públicas y el 404', () => {
    assert.equal(viewFromPath('/'), 'landing');
    assert.equal(viewFromPath('/encuesta'), 'landing');
    assert.equal(viewFromPath('/servicios'), 'categories');
    assert.equal(viewFromPath('/servicios/electricidad'), 'search');
    assert.equal(viewFromPath('/profesional/abc'), 'profile');
    assert.equal(viewFromPath('/pedido/job-1'), 'tracking');
    assert.equal(viewFromPath('/pago/retorno'), 'paid');
    assert.equal(viewFromPath('/xyz'), 'notfound');
  });

  it('arma una URL de categoría y de pedido', () => {
    assert.equal(categoryFromPath('/servicios/gasfiteria'), 'gasfiteria');
    assert.equal(pathForView('search', { category: 'plomeria' }), '/servicios/plomeria');
    assert.equal(pathForView('tracking', { jobId: 'p-1' }), '/pedido/p-1');
  });
});
