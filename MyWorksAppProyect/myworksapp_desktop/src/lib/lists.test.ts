import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  LIST_ORDERS,
  cleanSearch,
  collectPages,
  listOrder,
  orIlike,
  paymentFilter,
  refundFilter,
  type PageResult,
} from './lists.ts';

describe('orden estable de las listas', () => {
  it('cada lista tiene una columna de desempate', () => {
    for (const [table, spec] of Object.entries(LIST_ORDERS)) {
      assert.ok(spec.column.length > 0, table);
      assert.ok(spec.tie.length > 0, table);
      assert.notEqual(spec.column, spec.tie, table);
    }
  });

  it('pedidos, errores y catálogo no quedan sin orden', () => {
    assert.deepEqual(listOrder('trabajos'), { column: 'creado_en', ascending: false, tie: 'id' });
    assert.deepEqual(listOrder('registros_error_app'), {
      column: 'creado_en',
      ascending: false,
      tie: 'id',
    });
    assert.deepEqual(listOrder('servicios'), { column: 'nombre', ascending: true, tie: 'id' });
    assert.equal(listOrder('trabajadores').tie, 'id_usuario');
  });
});

describe('búsqueda y filtros', () => {
  it('quita comodines y limita el largo', () => {
    assert.equal(cleanSearch('  %gas_fiter, *  '), 'gasfiter');
    assert.equal(cleanSearch('a'.repeat(80)).length, 60);
  });

  it('arma un or de ilike y filtra pagos y reembolsos', () => {
    assert.equal(orIlike(['nombre', 'correo'], 'Ana'), 'nombre.ilike.*Ana*,correo.ilike.*Ana*');
    assert.equal(orIlike(['nombre'], '  '), null);
    assert.deepEqual(paymentFilter('retenido'), {
      or: 'estado_pago.ilike.*retenido*,tipo_pago.ilike.*retenido*',
      paymentId: null,
    });
    assert.deepEqual(paymentFilter('11111111-2222-3333-4444-555555555555'), {
      or: null,
      paymentId: '11111111-2222-3333-4444-555555555555',
    });
    assert.equal(refundFilter('demo-1'), 'id.ilike.*demo-1*');
    assert.equal(refundFilter('15000'), 'id.ilike.*15000*,monto.eq.15000');
    assert.equal(refundFilter(''), null);
  });
});

describe('exportación por páginas', () => {
  it('junta todas las páginas y se detiene en la última corta', async () => {
    const pages: PageResult<{ id: string }>[] = [
      { rows: [{ id: 'a' }, { id: 'b' }], total: 5 },
      { rows: [{ id: 'c' }, { id: 'd' }], total: 5 },
      { rows: [{ id: 'e' }], total: 5 },
    ];
    const all = await collectPages((page) => Promise.resolve(pages[page] ?? { rows: [], total: 5 }), 2);
    assert.deepEqual(all.map((row) => row.id), ['a', 'b', 'c', 'd', 'e']);
  });

  it('no pasa de total ni de un tope de páginas', async () => {
    let calls = 0;
    const all = await collectPages(async () => {
      calls += 1;
      return { rows: [{ id: String(calls) }, { id: `${calls}b` }], total: 3 };
    }, 2, 10);
    assert.equal(all.length, 3);
    assert.equal(calls, 2);

    let extra = 0;
    const capped = await collectPages(async (page) => {
      extra += 1;
      return { rows: [{ id: String(page) }], total: 100 };
    }, 1, 2);
    assert.equal(capped.length, 2);
    assert.equal(extra, 2);
  });

  it('devuelve vacío si la primera página no trae filas', async () => {
    const all = await collectPages(async () => ({ rows: [], total: 0 }), 25);
    assert.deepEqual(all, []);
  });
});
