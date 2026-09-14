import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { mapMetricsPayload } from './metrics.ts';

describe('mapMetricsPayload', () => {
  it('lee claves ES del RPC admin_metricas_resumen', () => {
    const m = mapMetricsPayload({
      usuarios: 10,
      trabajadores: 18,
      trabajos: 3,
      disputas_abiertas: 1,
      disputas_en_revision: 2,
      reportes_pendientes: 0,
      trabajos_activos: 1,
      errores_nuevos: 0,
      abusos_abiertos: 0,
      sync_fallidos: 0,
    });
    assert.equal(m.usersCount, 10);
    assert.equal(m.workersCount, 18);
    assert.equal(m.openDisputesCount, 1);
    assert.equal(m.underReviewDisputesCount, 2);
  });

  it('acepta camelCase legacy', () => {
    const m = mapMetricsPayload({ usersCount: 4, workersCount: 2 });
    assert.equal(m.usersCount, 4);
    assert.equal(m.workersCount, 2);
  });

  it('usa 0 si el payload es inválido', () => {
    const m = mapMetricsPayload(null);
    assert.equal(m.usersCount, 0);
    assert.equal(m.jobsCount, 0);
  });
});
