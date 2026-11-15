import { expect, test, type Page } from '@playwright/test';

const professionals = [
  {
    id_usuario: '11111111-1111-4111-8111-000000000101',
    profesion: 'Gasfíter',
    descripcion: 'Fugas y llaves.',
    calificacion: 4.8,
    tarifa_visita: 32000,
    categoria_servicio: 'plomeria',
    zona_trabajo: 'Puerto Montt',
    nombre: 'Mateo Oyarzo',
    ruta_foto_perfil: null,
    latitud_base: -41.4717,
    longitud_base: -72.9366,
    radio_servicio_km: 12,
    origen_base: 'mapa',
    trabajos_completados: 8,
  },
  {
    id_usuario: '11111111-1111-4111-8111-000000000102',
    profesion: 'Gasfíter',
    descripcion: 'Reparaciones de agua.',
    calificacion: 4.6,
    tarifa_visita: 31000,
    categoria_servicio: 'plomeria',
    zona_trabajo: 'Puerto Montt',
    nombre: 'Juana Colil',
    ruta_foto_perfil: null,
    latitud_base: -41.4682,
    longitud_base: -72.941,
    radio_servicio_km: 12,
    origen_base: 'mapa',
    trabajos_completados: 4,
  },
  {
    id_usuario: '11111111-1111-4111-8111-000000000103',
    profesion: 'Gasfíter',
    descripcion: 'Destapes y llaves.',
    calificacion: 4.5,
    tarifa_visita: 34000,
    categoria_servicio: 'plomeria',
    zona_trabajo: 'Puerto Montt',
    nombre: 'Pedro Nahuelpan',
    ruta_foto_perfil: null,
    latitud_base: -41.478,
    longitud_base: -72.928,
    radio_servicio_km: 12,
    origen_base: 'mapa',
    trabajos_completados: 4,
  },
];

const servicio = {
  id: 'svc-plomeria',
  nombre: 'Gasfitería y plomería',
  descripcion: 'Reparaciones de agua.',
  categoria: 'plomeria',
  activo: 1,
  modelo_precio: 'por_hora',
};

async function mockCatalog(page: Page) {
  await page.route('**/*', async (route) => {
    const url = route.request().url();
    const supabase = url.includes('/rest/v1/') || url.includes('/auth/v1/');
    if (!supabase) {
      await route.continue();
      return;
    }

    if (url.includes('/rpc/categorias_con_disponibles')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(['plomeria']),
      });
      return;
    }

    if (url.includes('/rpc/horarios_libres_profesional')) {
      const inicio = new Date(Date.now() + 24 * 60 * 60 * 1000);
      inicio.setMinutes(0, 0, 0);
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([{ inicio: inicio.toISOString() }]),
      });
      return;
    }

    if (url.includes('/rpc/listar_profesionales_catalogo')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(professionals),
      });
      return;
    }

    if (url.includes('/rest/v1/servicios')) {
      const accept = route.request().headers().accept ?? '';
      const body = accept.includes('vnd.pgrst.object')
        ? JSON.stringify(servicio)
        : JSON.stringify([servicio]);
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body,
      });
      return;
    }

    if (url.includes('/auth/v1/')) {
      await route.fulfill({
        status: 400,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'sin sesion de demo' }),
      });
      return;
    }

    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: '[]',
    });
  });
}

function boxesOverlap(
  a: { x: number; y: number; width: number; height: number },
  b: { x: number; y: number; width: number; height: number },
): boolean {
  return !(
    a.x + a.width <= b.x ||
    b.x + b.width <= a.x ||
    a.y + a.height <= b.y ||
    b.y + b.height <= a.y
  );
}

async function openPlumbingMap(page: Page, requests: string[]) {
  page.on('request', (request) => {
    requests.push(request.url());
  });
  await mockCatalog(page);
  await page.goto('/');
  await page.getByRole('button', { name: /buscar servicio/i }).click();
  await page.getByRole('button', { name: /plomería/i }).click();
  await expect(page.locator('.premium-search-map-leaflet')).toBeVisible({ timeout: 15_000 });
  await expect(page.locator('.premium-search-map-badge')).toContainText(/3 en el mapa · plomería/i);
  await expect(page.locator('.search-map-legend')).toContainText('Profesionales cerca');
  await expect(page.getByText(/api key required/i)).toHaveCount(0);
  await expect(page.locator('.leaflet-control-attribution')).toContainText(/OpenStreetMap/i);
  await expect.poll(() => requests.some((url) => url.includes('tiles.openfreemap.org')), {
    timeout: 20_000,
  }).toBe(true);
  // Espera a que el lienzo de MapLibre tenga píxeles (el estilo ya pintó).
  await expect
    .poll(async () => {
      return page.locator('.premium-search-map-leaflet canvas').evaluateAll((nodes) =>
        nodes.some((node) => {
          const canvas = node as HTMLCanvasElement;
          return canvas.width > 0 && canvas.height > 0;
        }),
      );
    }, { timeout: 20_000 })
    .toBe(true);
}

test('el mapa de búsqueda usa OpenFreeMap y la leyenda no tapa el recuento', async ({
  page,
}, testInfo) => {
  const requests: string[] = [];
  await openPlumbingMap(page, requests);

  const carto = requests.filter((url) => /cartocdn|carto\.com|VITE_CARTO|basemaps\.carto/i.test(url));
  expect(carto, `no debería pedir CARTO, se vieron: ${carto.join(', ')}`).toEqual([]);

  const badge = page.locator('.premium-search-map-badge');
  const legend = page.locator('.search-map-legend');
  const badgeBox = await badge.boundingBox();
  const legendBox = await legend.boundingBox();
  expect(badgeBox).toBeTruthy();
  expect(legendBox).toBeTruthy();
  expect(boxesOverlap(badgeBox!, legendBox!), 'la leyenda no debe tapar el recuento').toBe(false);
  await expect(badge).toBeVisible();
  await expect(legend).toBeVisible();

  const shot = testInfo.outputPath('mapa-openfreemap-desktop.png');
  await page.locator('.search-map-panel').screenshot({ path: shot });
  await page.screenshot({
    path: '/workspace/mwa_video/screens/web_mapa_openfreemap_desktop.png',
    fullPage: false,
  });
});

test('el mapa de búsqueda se ve bien en un teléfono y tampoco pide CARTO', async ({
  page,
}, testInfo) => {
  await page.setViewportSize({ width: 390, height: 844 });
  const requests: string[] = [];
  await openPlumbingMap(page, requests);

  const carto = requests.filter((url) => /cartocdn|carto\.com|basemaps\.carto/i.test(url));
  expect(carto).toEqual([]);

  const badge = page.locator('.premium-search-map-badge');
  const legend = page.locator('.search-map-legend');
  const badgeBox = await badge.boundingBox();
  const legendBox = await legend.boundingBox();
  expect(badgeBox).toBeTruthy();
  expect(legendBox).toBeTruthy();
  expect(boxesOverlap(badgeBox!, legendBox!), 'la leyenda no debe tapar el recuento en móvil').toBe(
    false,
  );

  const shot = testInfo.outputPath('mapa-openfreemap-mobile.png');
  await page.locator('.search-map-panel').screenshot({ path: shot });
  await page.screenshot({
    path: '/workspace/mwa_video/screens/web_mapa_openfreemap_mobile.png',
    fullPage: false,
  });
});
