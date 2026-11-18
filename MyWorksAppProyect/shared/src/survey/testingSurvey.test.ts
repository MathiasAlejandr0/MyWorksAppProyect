import assert from 'node:assert/strict';
import { test } from 'node:test';
import { SUS_ITEMS, susGrade, susScore, validateTestingSurvey } from './testingSurvey';

test('SUS tiene 10 afirmaciones', () => {
  assert.equal(SUS_ITEMS.length, 10);
});

test('puntaje SUS con la fórmula estándar', () => {
  assert.equal(susScore([5, 1, 5, 1, 5, 1, 5, 1, 5, 1]), 100);
  assert.equal(susScore([1, 5, 1, 5, 1, 5, 1, 5, 1, 5]), 0);
  assert.equal(susScore([3, 3, 3, 3, 3, 3, 3, 3, 3, 3]), 50);
  assert.equal(susScore([4, 2, 4, 2, 4, 2, 4, 2, 4, 2]), 75);
});

test('respuestas incompletas no dan puntaje', () => {
  assert.equal(susScore([5, 1, 5]), null);
  assert.equal(susScore([5, 1, 5, 1, 5, 1, 5, 1, 5, 0]), null);
});

test('lectura del puntaje', () => {
  assert.equal(susGrade(90), 'Excelente');
  assert.equal(susGrade(70), 'Sobre el promedio');
  assert.equal(susGrade(40), 'Deficiente');
});

test('valida antes de enviar', () => {
  const base = {
    platform: 'web' as const,
    role: 'cliente' as const,
    taskCompleted: 'si' as const,
    satisfaction: 4,
    sus: [4, 2, 4, 2, 4, 2, 4, 2, 4, 2],
  };
  assert.equal(validateTestingSurvey(base), null);
  assert.match(validateTestingSurvey({ ...base, sus: [4, 2, 0, 0, 0, 0, 0, 0, 0, 0] }) ?? '', /llevas 2 de 10/);
  assert.match(validateTestingSurvey({ ...base, satisfaction: 0 }) ?? '', /satisfacción/);
});
