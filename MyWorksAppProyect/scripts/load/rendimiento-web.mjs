/**
 * Rendimiento del bundle Vite + timings de navegación en preview local.
 * No usa Lighthouse SaaS; mide archivos gzip y Navigation Timing / LCP.
 *
 * Uso (desde myworksapp_web, dist ya construido):
 *   node ../scripts/load/rendimiento-web.mjs
 */
import { spawn } from 'node:child_process';
import { createGzip } from 'node:zlib';
import { createReadStream, readdirSync, statSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve, relative } from 'node:path';
import { pathToFileURL } from 'node:url';
import { pipeline } from 'node:stream/promises';
import { Writable } from 'node:stream';

const webRoot = resolve(
  process.env.WEB_ROOT ||
    (process.cwd().endsWith('myworksapp_web') ? process.cwd() : 'myworksapp_web'),
);
const dist = join(webRoot, 'dist');
const outPath = resolve(
  process.env.OUT ||
    'docs/anexos/2026-11-08-rendimiento-carga/rendimiento/web-bundle-navegacion.json',
);
const previewPort = Number(process.env.PREVIEW_PORT || 4173);
const previewHost = process.env.PREVIEW_HOST || '127.0.0.1';

async function gzipSize(file) {
  let n = 0;
  const counter = new Writable({
    write(chunk, _enc, cb) {
      n += chunk.length;
      cb();
    },
  });
  await pipeline(createReadStream(file), createGzip({ level: 9 }), counter);
  return n;
}

function listFiles(dir, acc = []) {
  for (const name of readdirSync(dir)) {
    const p = join(dir, name);
    if (statSync(p).isDirectory()) listFiles(p, acc);
    else acc.push(p);
  }
  return acc;
}

async function bundleStats() {
  const files = listFiles(dist).filter((f) => !f.endsWith('.map'));
  const rows = [];
  for (const file of files) {
    const st = statSync(file);
    rows.push({
      path: relative(dist, file).replaceAll('\\', '/'),
      bytes: st.size,
      gzip_bytes: await gzipSize(file),
    });
  }
  rows.sort((a, b) => b.gzip_bytes - a.gzip_bytes);
  const js = rows.filter((r) => r.path.endsWith('.js'));
  const css = rows.filter((r) => r.path.endsWith('.css'));
  return {
    files: rows,
    js_bytes: js.reduce((a, b) => a + b.bytes, 0),
    js_gzip_bytes: js.reduce((a, b) => a + b.gzip_bytes, 0),
    css_bytes: css.reduce((a, b) => a + b.bytes, 0),
    css_gzip_bytes: css.reduce((a, b) => a + b.gzip_bytes, 0),
    total_bytes: rows.reduce((a, b) => a + b.bytes, 0),
    total_gzip_bytes: rows.reduce((a, b) => a + b.gzip_bytes, 0),
  };
}

function waitForHttp(url, timeoutMs = 30000) {
  const t0 = Date.now();
  return new Promise((resolveWait, reject) => {
    const tick = async () => {
      try {
        const res = await fetch(url, { method: 'GET' });
        if (res.ok || res.status === 404) {
          resolveWait(true);
          return;
        }
      } catch {
        /* preview aún no escucha */
      }
      if (Date.now() - t0 > timeoutMs) {
        reject(new Error(`timeout esperando ${url}`));
        return;
      }
      setTimeout(tick, 250);
    };
    tick();
  });
}

async function navigationTimings() {
  const { chromium } = await import(
    pathToFileURL(join(webRoot, 'node_modules/playwright/index.mjs')).href
  );
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1366, height: 768 } });
  const url = `http://${previewHost}:${previewPort}/`;
  await page.goto(url, { waitUntil: 'networkidle', timeout: 60000 });
  const lcpObserved = await page.evaluate(
    () =>
      new Promise((resolve) => {
        let latest = null;
        const finish = () => resolve(latest);
        try {
          const po = new PerformanceObserver((list) => {
            const entries = list.getEntries();
            if (entries.length) latest = entries[entries.length - 1].startTime;
          });
          po.observe({ type: 'largest-contentful-paint', buffered: true });
        } catch {
          finish();
          return;
        }
        setTimeout(finish, 2000);
      }),
  );
  const metrics = await page.evaluate((lcpHint) => {
    const nav = performance.getEntriesByType('navigation')[0];
    const paints = Object.fromEntries(
      performance.getEntriesByType('paint').map((p) => [p.name, p.startTime]),
    );
    const lcpEntries = performance.getEntriesByType('largest-contentful-paint');
    const lcp =
      lcpHint ??
      (lcpEntries.length ? lcpEntries[lcpEntries.length - 1].startTime : null);
    const resources = performance.getEntriesByType('resource').map((r) => ({
      name: r.name.split('?')[0],
      type: r.initiatorType,
      duration_ms: r.duration,
      transfer_bytes: r.transferSize || 0,
      encoded_bytes: r.encodedBodySize || 0,
    }));
    return {
      url: location.href,
      title: document.title,
      ttfb_ms: nav ? nav.responseStart - nav.requestStart : null,
      dcl_ms: nav ? nav.domContentLoadedEventEnd : null,
      load_ms: nav ? nav.loadEventEnd : null,
      fcp_ms: paints['first-contentful-paint'] ?? null,
      lcp_ms: lcp,
      transfer_bytes: nav ? nav.transferSize : null,
      resource_n: resources.length,
      resources: resources
        .filter((r) => r.encoded_bytes > 0 || r.duration_ms > 50)
        .sort((a, b) => b.encoded_bytes - a.encoded_bytes)
        .slice(0, 20),
    };
  }, lcpObserved);
  await browser.close();
  const round = (n) => (n == null ? null : Math.round(n * 10) / 10);
  return {
    ...metrics,
    ttfb_ms: round(metrics.ttfb_ms),
    dcl_ms: round(metrics.dcl_ms),
    load_ms: round(metrics.load_ms),
    fcp_ms: round(metrics.fcp_ms),
    lcp_ms: round(metrics.lcp_ms),
  };
}

const bundle = await bundleStats();
const preview = spawn('npx', ['vite', 'preview', '--host', previewHost, '--port', String(previewPort), '--strictPort'], {
  cwd: webRoot,
  stdio: 'pipe',
  shell: true,
});

let nav = null;
let navError = null;
try {
  await waitForHttp(`http://${previewHost}:${previewPort}/`);
  nav = await navigationTimings();
} catch (err) {
  navError = err instanceof Error ? err.message : String(err);
} finally {
  try {
    preview.kill('SIGTERM');
  } catch {
    /* ignore */
  }
  if (process.platform === 'win32' && preview.pid) {
    spawn('taskkill', ['/pid', String(preview.pid), '/T', '/F'], { shell: true });
  }
}

const report = {
  kind: 'rendimiento-web-bundle-navegacion',
  measured_at: new Date().toISOString(),
  git_sha: process.env.GIT_SHA || null,
  preview: `http://${previewHost}:${previewPort}/`,
  viewport: '1366x768',
  bundle,
  navegacion: nav,
  navegacion_error: navError,
};

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(report, null, 2), 'utf8');
console.log(
  JSON.stringify(
    {
      out: outPath,
      js_gzip_kb: Math.round(bundle.js_gzip_bytes / 102.4) / 10,
      css_gzip_kb: Math.round(bundle.css_gzip_bytes / 102.4) / 10,
      lcp_ms: nav?.lcp_ms ?? null,
      ttfb_ms: nav?.ttfb_ms ?? null,
      error: navError,
    },
    null,
    2,
  ),
);
process.exit(navError ? 1 : 0);
