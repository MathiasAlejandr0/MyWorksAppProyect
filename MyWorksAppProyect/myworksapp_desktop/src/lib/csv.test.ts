import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { csvCell, toCsv } from './csv.ts';

describe('CSV', () => {
  it('escapa comillas, comas y saltos, y neutraliza fórmulas', () => {
    assert.equal(csvCell('hola, "mundo"'), '"hola, ""mundo"""');
    assert.equal(csvCell('=SUMA(1)'), '"\'=SUMA(1)"');
    assert.equal(csvCell('+569'), '"\'+569"');
    assert.equal(csvCell('-1'), '"\'-1"');
    assert.equal(csvCell('@cmd'), '"\'@cmd"');
    const csv = toCsv(['nota'], [['línea\n2']]);
    assert.equal(csv.charCodeAt(0), 0xfeff);
    assert.match(csv, /"línea\n2"/);
  });
});
