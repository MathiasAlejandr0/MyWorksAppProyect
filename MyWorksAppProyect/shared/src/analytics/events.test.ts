import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import {
  EVENTOS_USO,
  filaEventoAnalitica,
  listaProfesionalesParecidos,
  resumenResenasPublico,
} from './events.ts';

describe('eventos de uso', () => {
  it('usa los mismos tres nombres en web y app', () => {
    assert.deepEqual(Object.values(EVENTOS_USO), [
      'vio_ficha_profesional',
      'eligio_hora_reserva',
      'confirmo_pedido',
    ]);
  });

  it('arma una fila que cabe en eventos_analitica', () => {
    const fila = filaEventoAnalitica(
      EVENTOS_USO.vioFicha,
      { id_profesional: 'abc' },
      null,
      new Date('2026-11-23T06:00:00.000Z'),
      '11111111-1111-4111-8111-111111111111',
    );
    assert.equal(fila.nombre_evento, 'vio_ficha_profesional');
    assert.equal(fila.id_usuario, null);
    assert.equal(fila.marca_tiempo, '2026-11-23T06:00:00.000Z');
    assert.equal(fila.metadatos, '{"id_profesional":"abc"}');
  });
});

describe('resumen y parecidos', () => {
  it('no inventa resumen si no hay fila', () => {
    assert.equal(resumenResenasPublico(null), null);
    assert.equal(resumenResenasPublico({}), null);
    assert.equal(resumenResenasPublico({ resumen: '   ' }), null);
  });

  it('muestra el texto guardado', () => {
    assert.equal(resumenResenasPublico({ resumen: ' Puntual y claro. ' }), 'Puntual y claro.');
  });

  it('oculta el bloque si la función no devuelve filas', () => {
    assert.deepEqual(listaProfesionalesParecidos(null), []);
    assert.deepEqual(listaProfesionalesParecidos([]), []);
    assert.deepEqual(listaProfesionalesParecidos({ error: true }), []);
  });

  it('conserva las filas reales y una nota numérica', () => {
    const lista = listaProfesionalesParecidos([
      { id_usuario: 'a', nombre: 'Ana', profesion: 'Gasfitería', calificacion: '4.5' },
      { id_usuario: 'a', nombre: 'Ana otra vez', profesion: 'Gasfitería', calificacion: 1 },
      { id_usuario: 'b', nombre: ' ', profesion: '', calificacion: null },
    ]);
    assert.equal(lista.length, 2);
    assert.equal(lista[0]?.calificacion, 4.5);
    assert.equal(lista[1]?.nombre, 'Profesional');
    assert.equal(lista[1]?.calificacion, null);
  });
});
