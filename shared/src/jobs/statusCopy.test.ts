import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  jobStatusDetail,
  jobStatusLabel,
  paymentStatusLabel,
} from './statusCopy.ts';

describe('textos de estado del trabajo', () => {
  it('traduce los códigos de la base', () => {
    assert.equal(jobStatusLabel('esperando_pago'), 'Esperando el pago');
    assert.equal(jobStatusLabel('en_curso'), 'En curso');
    assert.equal(jobStatusLabel('en_camino'), 'En camino');
    assert.equal(paymentStatusLabel('retenido'), 'Pago retenido');
  });

  it('no inventa un estado en curso si falta el código', () => {
    assert.equal(jobStatusLabel(null), 'Sin estado');
    assert.equal(jobStatusLabel('otro'), 'Estado no reconocido');
    assert.match(jobStatusDetail('pendiente'), /aceptar o rechazar/);
    assert.equal(paymentStatusLabel(undefined), 'Sin información de pago');
  });
});
