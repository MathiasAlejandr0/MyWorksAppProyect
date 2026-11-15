/**
 * Genera Dart desde shared/src/domain.ts
 * Output: myworksapp_app/lib/core/domain/generated_domain.dart
 *
 * Uso: node scripts/generate-domain-dart.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const domainPath = path.join(root, 'shared', 'src', 'domain.ts');
const outPath = path.join(
  root,
  'myworksapp_app',
  'lib',
  'core',
  'domain',
  'generated_domain.dart',
);

const src = fs.readFileSync(domainPath, 'utf8');

function extractObject(name) {
  const re = new RegExp(
    `export const ${name} = \\{([\\s\\S]*?)\\} as const;`,
  );
  const m = src.match(re);
  if (!m) throw new Error(`No se encontro ${name} en domain.ts`);
  const entries = [];
  const pairRe = /(\w+):\s*'([^']+)'/g;
  let p;
  while ((p = pairRe.exec(m[1])) !== null) {
    entries.push({ key: p[1], value: p[2] });
  }
  return entries;
}

function extractActiveStatuses() {
  const m = src.match(
    /export const WORKER_ACTIVE_JOB_STATUSES[^=]*=\s*\[([\s\S]*?)\];/,
  );
  if (!m) throw new Error('WORKER_ACTIVE_JOB_STATUSES no encontrado');
  const vals = [];
  const re = /JobStatuses\.(\w+)/g;
  let p;
  const jobMap = Object.fromEntries(
    extractObject('JobStatuses').map((e) => [e.key, e.value]),
  );
  while ((p = re.exec(m[1])) !== null) {
    vals.push(jobMap[p[1]]);
  }
  return vals;
}

function dartConstClass(className, entries, comment) {
  const lines = entries.map(
    (e) => `  static const String ${e.key} = '${e.value}';`,
  );
  return `/// ${comment}
class ${className} {
  ${className}._();

${lines.join('\n')}
}
`;
}

const roles = extractObject('UserRoles');
const jobs = extractObject('JobStatuses');
const payments = extractObject('PaymentStatuses');
const pricing = extractObject('PricingModes');
const disputes = extractObject('DisputeStatuses');
const active = extractActiveStatuses();

const header = `// GENERATED CODE - do not edit by hand.
// Source: shared/src/domain.ts
// Regenerate: node scripts/generate-domain-dart.mjs
// ignore_for_file: public_member_api_docs

`;

const activeBlock = `/// Active job statuses for workers (mirror of TS WORKER_ACTIVE_JOB_STATUSES).
class GeneratedWorkerActiveJobStatuses {
  GeneratedWorkerActiveJobStatuses._();

  static const List<String> values = [
${active.map((v) => `    '${v}',`).join('\n')}
  ];

  static bool contains(String status) => values.contains(status);
}
`;

const body = [
  dartConstClass(
    'GeneratedUserRoles',
    roles,
    'Roles - generated from shared/src/domain.ts',
  ),
  dartConstClass(
    'GeneratedJobStatuses',
    jobs,
    'Job statuses - generated from shared/src/domain.ts',
  ),
  dartConstClass(
    'GeneratedPaymentStatuses',
    payments,
    'Payment statuses - generated from shared/src/domain.ts',
  ),
  dartConstClass(
    'GeneratedPricingModes',
    pricing,
    'Pricing modes - generated from shared/src/domain.ts',
  ),
  dartConstClass(
    'GeneratedDisputeStatuses',
    disputes,
    'Dispute statuses - generated from shared/src/domain.ts',
  ),
  activeBlock,
].join('\n');

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, header + body, 'utf8');
console.log(`Wrote ${path.relative(root, outPath)}`);
