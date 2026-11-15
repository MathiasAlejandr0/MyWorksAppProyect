/**
 * Genera shared/src/database.types.ts desde el proyecto remoto de Supabase.
 *
 * Requiere: `npx supabase login` o env SUPABASE_ACCESS_TOKEN
 * Uso: node scripts/gen-supabase-types.mjs
 */
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const outPath = path.join(root, 'shared', 'src', 'database.types.ts');
const projectId =
  process.env.SUPABASE_PROJECT_ID?.trim() || 'wxqrfcqifkfgawrnqmnj';

const result = spawnSync(
  'npx',
  [
    'supabase',
    'gen',
    'types',
    'typescript',
    '--project-id',
    projectId,
    '--schema',
    'public',
  ],
  { encoding: 'utf8', shell: true },
);

if (result.status !== 0) {
  console.error(result.stderr || result.stdout || 'supabase gen types falló');
  console.error(
    '\nSin token no se puede regenerar desde remoto. Se mantiene database.types.ts actual.\n' +
      'Haz: npx supabase login   o   set SUPABASE_ACCESS_TOKEN=...',
  );
  process.exit(result.status ?? 1);
}

const header = `/**
 * GENERATED — no editar a mano salvo emergencia.
 * Fuente: supabase gen types (project ${projectId})
 * Regenerar: node scripts/gen-supabase-types.mjs
 */

`;

fs.writeFileSync(outPath, header + result.stdout, 'utf8');
console.log(`OK → ${path.relative(root, outPath)}`);
