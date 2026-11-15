import assert from 'node:assert/strict';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

const root = join(import.meta.dirname, '../../../');
const roots = [
  'myworksapp_web/src',
  'myworksapp_desktop/src',
  'myworksapp_app/lib',
  'shared/src',
];
const forbidden = [
  'liberar_escrow_manual',
  'simular_transicion_pago',
  'aplicar_cierre_disputa',
  'marcar_pago_liberado',
  'crear_intencion_pago_servicio',
  'limpiar_invitados_sin_pago',
];

function filesOf(dir: string): string[] {
  const out: string[] = [];
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    const stat = statSync(path);
    if (stat.isDirectory()) {
      out.push(...filesOf(path));
      continue;
    }
    if (/\.(ts|tsx|dart)$/.test(name) && !name.endsWith('.test.ts')) {
      out.push(path);
    }
  }
  return out;
}

test('los clientes no escriben la tabla pagos', () => {
  const hits: string[] = [];
  const write = /\.from\(\s*['"]pagos['"]\)[\s\S]{0,180}\.(insert|update|upsert|delete)\(/;
  for (const rel of roots) {
    for (const file of filesOf(join(root, rel))) {
      if (file.endsWith('database.types.ts')) continue;
      const text = readFileSync(file, 'utf8');
      if (write.test(text)) hits.push(file);
    }
  }
  assert.deepEqual(hits, []);
});

test('los clientes no llaman RPCs de service_role', () => {
  const hits: string[] = [];
  for (const rel of roots) {
    for (const file of filesOf(join(root, rel))) {
      if (file.endsWith('database.types.ts')) continue;
      const text = readFileSync(file, 'utf8');
      for (const name of forbidden) {
        const call = new RegExp(`\\.rpc\\(\\s*['"]${name}['"]`);
        if (call.test(text)) hits.push(`${file} -> ${name}`);
      }
    }
  }
  assert.deepEqual(hits, []);
});
