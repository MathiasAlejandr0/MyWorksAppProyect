#!/usr/bin/env node
/**
 * Lee shared/design-tokens.json y genera
 * myworksapp_app/lib/core/theme/generated_brand_colors.dart
 *
 * Uso: node scripts/generate-app-colors.mjs
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const jsonPath = path.join(root, 'shared', 'design-tokens.json');
const outPath = path.join(
  root,
  'myworksapp_app',
  'lib',
  'core',
  'theme',
  'generated_brand_colors.dart',
);

/** Keys requeridas en design-tokens.json → campos Dart. */
const REQUIRED_COLORS = [
  'brandOrange',
  'brandOrangeVibrant',
  'brandNavy',
  'emerald',
  'textMainDark',
  'textMutedDark',
  'bgDominantDark',
  'bgCanvasDarkAlt',
  'bgSurfaceDark',
  'bgElevatedDark',
  'crimsonError',
];

function hexToArgbConst(hex) {
  const m = /^#([0-9A-Fa-f]{6})$/.exec(String(hex).trim());
  if (!m) {
    throw new Error(`Color inválido "${hex}" (esperado #RRGGBB)`);
  }
  return `0xFF${m[1].toUpperCase()}`;
}

const tokens = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
const colors = tokens.color ?? {};

const missing = REQUIRED_COLORS.filter((k) => !(k in colors));
if (missing.length) {
  throw new Error(
    `Faltan color tokens en design-tokens.json: ${missing.join(', ')}`,
  );
}

const fields = REQUIRED_COLORS.map((key) => {
  const argb = hexToArgbConst(colors[key]);
  return `  static const Color ${key} = Color(${argb});`;
});

const dart = `// GENERATED CODE - do not edit by hand.
// Source: shared/design-tokens.json
// Regenerate: node scripts/generate-app-colors.mjs
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

/// Colores de marca generados desde design-tokens.json.
class GeneratedBrandColors {
  GeneratedBrandColors._();

${fields.join('\n')}
}
`;

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, dart, 'utf8');
console.log(`Wrote ${path.relative(root, outPath)}`);
