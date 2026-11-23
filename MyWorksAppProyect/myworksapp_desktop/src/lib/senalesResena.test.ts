import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { agruparSenalesResena, etiquetaSenal } from './senalesResena.ts';

describe('cola de reseñas dudosas', () => {
  it('traduce la señal que ya escribió el trigger', () => {
    assert.equal(etiquetaSenal('rafaga'), 'Ráfaga');
    assert.equal(etiquetaSenal('otra'), 'otra');
  });

  it('junta las señales de una misma reseña en una sola acción', () => {
    const grupos = agruparSenalesResena([
      {
        id_calificacion: 'c1',
        tipo_senal: 'cuenta_nueva',
        comentario: 'Muy bien',
        estado_revision: 'vigente',
        puntaje_resena: 5,
        nombre_trabajador: 'Ana',
        nombre_cliente: 'Luis',
        detalle: null,
        creado_en: '2026-11-22T12:00:00Z',
      },
      {
        id_calificacion: 'c1',
        tipo_senal: 'rafaga',
        comentario: 'Muy bien',
        estado_revision: 'vigente',
        puntaje_resena: 5,
        nombre_trabajador: 'Ana',
        nombre_cliente: 'Luis',
        detalle: 'tres en un minuto',
        creado_en: '2026-11-22T12:00:01Z',
      },
    ]);
    assert.equal(grupos.length, 1);
    assert.deepEqual(grupos[0]?.senales, ['Cuenta nueva', 'Ráfaga']);
    assert.equal(grupos[0]?.idCalificacion, 'c1');
  });
});
