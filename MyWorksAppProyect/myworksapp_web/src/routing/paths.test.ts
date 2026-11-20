import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { categoryFromPath, pathForView, recordIdFromPath, viewFromPath } from './paths.ts';

describe('rutas de la web', () => {
  it('reconoce las rutas públicas y el 404', () => {
    assert.equal(viewFromPath('/'), 'landing');
    assert.equal(viewFromPath('/encuesta'), 'landing');
    assert.equal(viewFromPath('/servicios'), 'categories');
    assert.equal(viewFromPath('/servicios/electricidad'), 'search');
    assert.equal(viewFromPath('/profesional/abc'), 'profile');
    assert.equal(viewFromPath('/pedido/job-1'), 'tracking');
    assert.equal(viewFromPath('/pago/retorno'), 'paid');
    assert.equal(viewFromPath('/aviso-legal'), 'aviso');
    assert.equal(viewFromPath('/terminos'), 'terminos');
    assert.equal(viewFromPath('/privacidad'), 'privacidad');
    assert.equal(viewFromPath('/xyz'), 'notfound');
  });

  it('saca el id del profesional y del pedido desde la ruta', () => {
    const id = '11111111-1111-4111-8111-111111111111';
    assert.equal(recordIdFromPath(`/profesional/${id}`, 'profesional'), id);
    assert.equal(recordIdFromPath('/profesional/abc%20def/', 'profesional'), 'abc def');
    assert.equal(recordIdFromPath('/profesional/', 'profesional'), null);
    assert.equal(recordIdFromPath('/pedido/job-1', 'pedido'), 'job-1');
  });

  it('arma una URL de categoría y de pedido', () => {
    assert.equal(categoryFromPath('/servicios/gasfiteria'), 'gasfiteria');
    assert.equal(pathForView('search', { category: 'plomeria' }), '/servicios/plomeria');
    assert.equal(pathForView('tracking', { jobId: 'p-1' }), '/pedido/p-1');
    assert.equal(pathForView('aviso'), '/aviso-legal');
  });
});
