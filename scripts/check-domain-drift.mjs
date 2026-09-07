#!/usr/bin/env node
/**
 * Drift check: shared/src/domain.ts ↔ Dart constants.
 * Exit 1 if values diverge.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');

const domainPath = path.join(root, 'shared', 'src', 'domain.ts');
const constantsPath = path.join(
  root,
  'myworksapp_app',
  'lib',
  'core',
  'utils',
  'constants.dart',
);
const pricingPath = path.join(
  root,
  'myworksapp_app',
  'lib',
  'core',
  'domain',
  'pricing_constants.dart',
);
const workerStatusPath = path.join(
  root,
  'myworksapp_app',
  'lib',
  'core',
  'utils',
  'worker_job_status.dart',
);
const disputeModelPath = path.join(
  root,
  'myworksapp_app',
  'lib',
  'core',
  'database',
  'models',
  'dispute_model.dart',
);

function read(filePath) {
  if (!fs.existsSync(filePath)) {
    console.error(`Missing file: ${filePath}`);
    process.exit(1);
  }
  return fs.readFileSync(filePath, 'utf8');
}

/** Extract string literal values from `export const Name = { ... } as const`. */
function extractTsObjectValues(source, name) {
  const re = new RegExp(
    `export\\s+const\\s+${name}\\s*=\\s*\\{([\\s\\S]*?)\\}\\s*as\\s+const`,
  );
  const m = source.match(re);
  if (!m) {
    throw new Error(`Could not find export const ${name} = { ... } as const`);
  }
  const values = [...m[1].matchAll(/:\s*'([^']+)'/g)].map((x) => x[1]);
  return new Set(values);
}

/** Extract string literals / JobStatuses.x refs resolved via JobStatuses map. */
function extractWorkerActiveStatuses(source, jobStatuses) {
  const re =
    /export\s+const\s+WORKER_ACTIVE_JOB_STATUSES[^=]*=\s*\[([\s\S]*?)\];/;
  const m = source.match(re);
  if (!m) {
    throw new Error('Could not find WORKER_ACTIVE_JOB_STATUSES');
  }
  const body = m[1];
  const values = new Set();
  for (const lit of body.matchAll(/'([^']+)'/g)) {
    values.add(lit[1]);
  }
  for (const ref of body.matchAll(/JobStatuses\.(\w+)/g)) {
    const key = ref[1];
    // Resolve via object block: key: 'value'
    const objMatch = source.match(
      /export\s+const\s+JobStatuses\s*=\s*\{([\s\S]*?)\}\s*as\s+const/,
    );
    if (!objMatch) throw new Error('JobStatuses not found while resolving refs');
    const keyRe = new RegExp(`${key}\\s*:\\s*'([^']+)'`);
    const kv = objMatch[1].match(keyRe);
    if (!kv) {
      throw new Error(`JobStatuses.${key} not found`);
    }
    values.add(kv[1]);
  }
  if (values.size === 0 && jobStatuses.size === 0) {
    throw new Error('WORKER_ACTIVE_JOB_STATUSES is empty');
  }
  return values;
}

/** All `static const String x = 'value'` in Dart source. */
function extractDartStringConsts(source) {
  const values = new Set();
  for (const m of source.matchAll(
    /static\s+const\s+String\s+\w+\s*=\s*'([^']+)'/g,
  )) {
    values.add(m[1]);
  }
  return values;
}

/** String literals inside a named Dart list const. */
function extractDartListLiterals(source, listName) {
  const re = new RegExp(
    `static\\s+const\\s+List<String>\\s+${listName}\\s*=\\s*\\[([\\s\\S]*?)\\];`,
  );
  const m = source.match(re);
  if (!m) {
    throw new Error(`Could not find List ${listName}`);
  }
  // Resolve AppConstants.xxx / PricingConstants.xxx via their source files later;
  // also accept raw 'literals'.
  return m[1];
}

function resolveDartRefs(listBody, constMap) {
  const values = new Set();
  for (const lit of listBody.matchAll(/'([^']+)'/g)) {
    values.add(lit[1]);
  }
  for (const ref of listBody.matchAll(
    /(AppConstants|PricingConstants)\.(\w+)/g,
  )) {
    const key = `${ref[1]}.${ref[2]}`;
    const v = constMap.get(key);
    if (v == null) {
      throw new Error(`Unresolved Dart ref: ${key}`);
    }
    values.add(v);
  }
  return values;
}

function buildDartConstMap(...sources) {
  const map = new Map();
  for (const source of sources) {
    const classMatch = source.match(/class\s+(\w+)/);
    const className = classMatch?.[1];
    if (!className) continue;
    for (const m of source.matchAll(
      /static\s+const\s+String\s+(\w+)\s*=\s*'([^']+)'/g,
    )) {
      map.set(`${className}.${m[1]}`, m[2]);
    }
  }
  return map;
}

function missingIn(from, to) {
  return [...from].filter((v) => !to.has(v)).sort();
}

function report(label, missing) {
  if (missing.length === 0) return false;
  console.error(`  ✗ ${label}:`);
  for (const v of missing) {
    console.error(`      - '${v}'`);
  }
  return true;
}

const domain = read(domainPath);
const constants = read(constantsPath);
const pricing = read(pricingPath);
const workerStatus = read(workerStatusPath);
const disputeModel = read(disputeModelPath);
const generatedPath = path.join(
  root,
  'myworksapp_app',
  'lib',
  'core',
  'domain',
  'generated_domain.dart',
);
const generated = fs.existsSync(generatedPath) ? read(generatedPath) : '';

const userRolesTs = extractTsObjectValues(domain, 'UserRoles');
const jobStatusesTs = extractTsObjectValues(domain, 'JobStatuses');
const paymentStatusesTs = extractTsObjectValues(domain, 'PaymentStatuses');
const pricingModesTs = extractTsObjectValues(domain, 'PricingModes');
const disputeStatusesTs = extractTsObjectValues(domain, 'DisputeStatuses');
const workerActiveTs = extractWorkerActiveStatuses(domain, jobStatusesTs);

const dartAllConsts = new Set([
  ...extractDartStringConsts(constants),
  ...extractDartStringConsts(pricing),
]);

// Roles from AppConstants (role*)
const dartRoles = new Set(
  [...extractDartStringConsts(constants)].filter((v) =>
    ['user', 'worker', 'admin'].includes(v),
  ),
);
// Prefer explicit role* fields
const roleFromConsts = [...constants.matchAll(
  /static\s+const\s+String\s+role\w+\s*=\s*'([^']+)'/g,
)].map((m) => m[1]);
if (roleFromConsts.length > 0) {
  dartRoles.clear();
  for (const r of roleFromConsts) dartRoles.add(r);
}

// Job statuses: AppConstants.jobStatus* + PricingConstants.job*
const dartJobStatuses = new Set();
for (const m of constants.matchAll(
  /static\s+const\s+String\s+jobStatus\w+\s*=\s*'([^']+)'/g,
)) {
  dartJobStatuses.add(m[1]);
}
for (const m of pricing.matchAll(
  /static\s+const\s+String\s+job\w+\s*=\s*'([^']+)'/g,
)) {
  dartJobStatuses.add(m[1]);
}

const dartPayment = new Set(
  [...pricing.matchAll(
    /static\s+const\s+String\s+payment(?!Type)\w+\s*=\s*'([^']+)'/g,
  )].map((m) => m[1]),
);
const dartModes = new Set(
  [...pricing.matchAll(
    /static\s+const\s+String\s+mode\w+\s*=\s*'([^']+)'/g,
  )].map((m) => m[1]),
);

// Dispute statuses: literals in dispute_model (+ fallbacks in dartAllConsts / file text)
const dartDispute = new Set(
  [...disputeModel.matchAll(/'([a-z_]+)'/g)]
    .map((m) => m[1])
    .filter((v) => ['open', 'under_review', 'resolved'].includes(v) || disputeStatusesTs.has(v)),
);
// Also accept any dispute status string appearing in the three Dart sources
for (const src of [constants, pricing, disputeModel]) {
  for (const v of disputeStatusesTs) {
    if (src.includes(`'${v}'`)) dartDispute.add(v);
  }
}

const constMap = buildDartConstMap(constants, pricing);
let dartWorkerActive;
if (generated.includes('GeneratedWorkerActiveJobStatuses')) {
  const body = extractDartListLiterals(generated, 'values');
  dartWorkerActive = resolveDartRefs(body, constMap);
} else {
  const activeListBody = extractDartListLiterals(workerStatus, 'activeStatuses');
  dartWorkerActive = resolveDartRefs(activeListBody, constMap);
}

let failed = false;
console.log('Domain drift check (domain.ts ↔ Dart)\n');

failed |= report(
  'UserRoles in domain.ts missing in Dart',
  missingIn(userRolesTs, dartRoles),
);
failed |= report(
  'Dart roles missing in domain.ts UserRoles',
  missingIn(dartRoles, userRolesTs),
);

failed |= report(
  'JobStatuses in domain.ts missing in Dart',
  missingIn(jobStatusesTs, dartJobStatuses),
);
failed |= report(
  'Dart job statuses missing in domain.ts JobStatuses',
  missingIn(dartJobStatuses, jobStatusesTs),
);

failed |= report(
  'PaymentStatuses in domain.ts missing in Dart',
  missingIn(paymentStatusesTs, dartPayment.size ? dartPayment : dartAllConsts),
);
failed |= report(
  'PricingModes in domain.ts missing in Dart',
  missingIn(pricingModesTs, dartModes.size ? dartModes : dartAllConsts),
);
failed |= report(
  'DisputeStatuses in domain.ts missing in Dart',
  missingIn(disputeStatusesTs, dartDispute),
);

failed |= report(
  'WORKER_ACTIVE_JOB_STATUSES missing in Dart WorkerJobStatus.activeStatuses',
  missingIn(workerActiveTs, dartWorkerActive),
);
failed |= report(
  'Dart WorkerJobStatus.activeStatuses missing in WORKER_ACTIVE_JOB_STATUSES',
  missingIn(dartWorkerActive, workerActiveTs),
);

if (failed) {
  console.error('\nDomain drift detected. Align shared/src/domain.ts with Dart constants.');
  process.exit(1);
}

console.log('OK — no domain drift between domain.ts and Dart constants.');
process.exit(0);
