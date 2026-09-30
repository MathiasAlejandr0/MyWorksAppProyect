import { expect, test } from '@playwright/test';

const pedro = {
  id_usuario: '11111111-1111-4111-8111-000000000101',
  profesion: 'Gasfíter',
  descripcion: 'Fugas y llaves en Providencia.',
  calificacion: 4.8,
  tarifa_visita: 35000,
  categoria_servicio: 'plomeria',
  zona_trabajo: 'Providencia',
  nombre: 'Pedro Rojas',
  ruta_foto_perfil: null,
  latitud_base: -33.4314,
  longitud_base: -70.6093,
  radio_servicio_km: 12,
  origen_base: 'mapa',
  trabajos_completados: 5,
};

async function mockCatalog(page: import('@playwright/test').Page) {
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
    if (url.includes('/rpc/listar_profesionales_catalogo')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([pedro]),
      });
      return;
    }
    if (url.includes('/rest/v1/servicios')) {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          id: 'svc-plomeria',
          nombre: 'Gasfitería y plomería',
          descripcion: 'Reparaciones de agua.',
          categoria: 'plomeria',
          activo: 1,
          modelo_precio: 'por_hora',
        }),
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

test('a 1280 la barra de reserva queda dentro de la ventana', async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 800 });
  await mockCatalog(page);
  await page.goto('/');
  await expect(page.getByRole('button', { name: 'Ingresar' })).toHaveCount(1);
  await page.getByRole('button', { name: /buscar servicio/i }).click();
  await page.getByRole('button', { name: /plomería/i }).click();
  await page.locator('.pro-card', { hasText: 'Pedro Rojas' }).click();
  const bar = page.getByRole('region', { name: 'Reserva rápida' });
  await expect(bar).toBeVisible();
  await expect(bar).toBeInViewport();
  const box = await bar.boundingBox();
  expect(box).not.toBeNull();
  expect(box!.x).toBeGreaterThanOrEqual(0);
  expect(box!.x + box!.width).toBeLessThanOrEqual(1280);
});

test('Ingresar queda dentro de la ventana a 1280 y a 390', async ({ page }) => {
  for (const viewport of [
    { width: 1280, height: 800 },
    { width: 390, height: 844 },
  ]) {
    await page.setViewportSize(viewport);
    await page.goto('/');
    await page.getByRole('button', { name: 'Ingresar' }).click();
    const dialog = page.getByRole('dialog', { name: /iniciar sesión/i });
    await expect(dialog).toBeVisible();
    const box = await dialog.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.x).toBeGreaterThanOrEqual(-1);
    expect(box!.y).toBeGreaterThanOrEqual(-1);
    expect(box!.x + box!.width).toBeLessThanOrEqual(viewport.width + 1);
    expect(box!.y + box!.height).toBeLessThanOrEqual(viewport.height + 1);
    const title = dialog.getByRole('heading', { name: 'Iniciar sesión' });
    await expect(title).toBeInViewport();
    const titleBox = await title.boundingBox();
    expect(titleBox).not.toBeNull();
    expect(titleBox!.y).toBeGreaterThanOrEqual(0);
    expect(titleBox!.y + titleBox!.height).toBeLessThanOrEqual(viewport.height);
  }
});

test('a 390 la portada muestra Ingresar y Registrarse', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await expect(page.getByRole('button', { name: 'Ingresar' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Registrarse' })).toBeVisible();
});

test('Ver mi pedido rellena el correo del invitado', async ({ page }) => {
  await page.addInitScript(() => {
    sessionStorage.setItem('mwa-guest-email', 'invitada@correo.cl');
  });
  await page.goto('/?pago=ok&invitado=1&alta=token-demo');
  await page.getByRole('button', { name: 'Ver mi pedido' }).click();
  const email = page.getByRole('dialog').locator('input[type="email"]');
  await expect(email).toHaveValue('invitada@correo.cl');
  await page.getByRole('button', { name: 'Cerrar' }).click();
  await page.getByRole('button', { name: 'Ingresar' }).click();
  await expect(page.getByRole('dialog').locator('input[type="email"]')).toHaveValue('');
});

const trackingUserId = '22222222-2222-4222-8222-222222222222';
const trackingWorkerId = '11111111-1111-4111-8111-000000000101';
const trackingJobId = '33333333-3333-4333-8333-333333333333';

async function mockSignedInTracking(page: import('@playwright/test').Page) {
  await page.addInitScript(
    ({ userId, jobId }) => {
      const session = JSON.stringify({
        access_token: 'demo-access-token',
        token_type: 'bearer',
        expires_in: 3600,
        expires_at: Math.floor(Date.now() / 1000) + 3600,
        refresh_token: 'demo-refresh-token',
        user: {
          id: userId,
          aud: 'authenticated',
          role: 'authenticated',
          email: 'camila.soto@demo.myworksapp.cl',
          app_metadata: { provider: 'email', providers: ['email'] },
          user_metadata: {},
          created_at: '2026-01-01T00:00:00.000Z',
        },
      });
      const original = Storage.prototype.getItem;
      Storage.prototype.getItem = function (key) {
        if (key.startsWith('sb-') && key.endsWith('-auth-token')) return session;
        return original.call(this, key);
      };
      sessionStorage.setItem('mwa-active-job', jobId);
    },
    { userId: trackingUserId, jobId: trackingJobId },
  );

  await page.route('**/*', async (route) => {
    const url = route.request().url();
    const supabase = url.includes('/rest/v1/') || url.includes('/auth/v1/');
    if (!supabase) {
      await route.continue();
      return;
    }
    const accept = route.request().headers().accept ?? '';
    const asObject = accept.includes('application/vnd.pgrst.object+json');
    const json = (body: unknown) =>
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify(body),
      });

    if (url.includes('/auth/v1/')) {
      await json({ id: trackingUserId, email: 'camila.soto@demo.myworksapp.cl' });
      return;
    }
    if (url.includes('/rest/v1/perfiles')) {
      await json({
        id: trackingUserId,
        nombre: 'Camila Soto',
        correo: 'camila.soto@demo.myworksapp.cl',
        rol: 'usuario',
        estado_cuenta: 'activo',
        ruta_foto_perfil: null,
        creado_en: '2026-01-01T00:00:00.000Z',
      });
      return;
    }
    if (url.includes('/rest/v1/trabajos')) {
      await json({
        id: trackingJobId,
        estado: 'en_camino',
        estado_pago: 'retenido',
        direccion: 'Av. Providencia 123',
        descripcion: 'Fuga en la llave',
        latitud: -33.4314,
        longitud: -70.6093,
        id_trabajador: trackingWorkerId,
        id_usuario: trackingUserId,
      });
      return;
    }
    if (url.includes('/rest/v1/trabajadores')) {
      await json({
        id_usuario: trackingWorkerId,
        profesion: 'Gasfíter',
        calificacion: 4.8,
        tarifa_visita: 35000,
        categoria_servicio: 'plomeria',
        perfiles: { nombre: 'Pedro Rojas', ruta_foto_perfil: null },
      });
      return;
    }
    if (url.includes('/rest/v1/ubicacion_en_vivo')) {
      await json(asObject ? null : []);
      return;
    }
    if (url.includes('/rpc/listar_profesionales_catalogo')) {
      await json([]);
      return;
    }
    await json(asObject ? null : []);
  });
}

test('el chat del seguimiento no queda bajo el mapa a 1280 y a 390', async ({ page }) => {
  await mockSignedInTracking(page);
  for (const viewport of [
    { width: 1280, height: 800 },
    { width: 390, height: 844 },
  ]) {
    await page.setViewportSize(viewport);
    await page.goto('/');
    await page.getByRole('button', { name: 'Abrir chat' }).click();
    const chat = page.locator('.chat-widget');
    const map = page.locator('.leaflet-container');
    await expect(chat).toBeVisible();
    await expect(map).toBeVisible();
    const covered = await page.evaluate(() => {
      const chatEl = document.querySelector('.chat-widget');
      const mapEl = document.querySelector('.leaflet-container');
      if (!chatEl || !mapEl) return { overlap: false, ok: false, hits: [] };
      const chatBox = chatEl.getBoundingClientRect();
      const mapBox = mapEl.getBoundingClientRect();
      const left = Math.max(chatBox.left, mapBox.left);
      const right = Math.min(chatBox.right, mapBox.right);
      const top = Math.max(chatBox.top, mapBox.top);
      const bottom = Math.min(chatBox.bottom, mapBox.bottom);
      if (right - left < 8 || bottom - top < 8) return { overlap: false, ok: false, hits: [] };
      const samples = [
        [left + 4, top + 4],
        [(left + right) / 2, (top + bottom) / 2],
        [right - 4, bottom - 4],
      ];
      const hits = samples.map(([x, y]) => {
        const el = document.elementFromPoint(x, y);
        return {
          x,
          y,
          onChat: Boolean(el && (el === chatEl || chatEl.contains(el))),
        };
      });
      return { overlap: true, ok: hits.every((hit) => hit.onChat), hits };
    });
    expect(covered.overlap, `el chat y el mapa se solapan a ${viewport.width}`).toBe(true);
    expect(covered.ok, JSON.stringify(covered.hits)).toBe(true);
    await page.getByRole('button', { name: 'Cerrar chat' }).click();
  }
});

test('a 390 el formulario de invitado no corta el monto', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await mockCatalog(page);
  await page.goto('/');
  await page.getByRole('button', { name: /buscar servicio/i }).click();
  await page.getByRole('button', { name: /plomería/i }).click();
  await page.locator('.pro-card', { hasText: 'Pedro Rojas' }).click();
  await page.getByRole('button', { name: /continuar con la reserva/i }).dispatchEvent('click');
  const dialog = page.getByRole('dialog');
  await expect(dialog).toBeVisible();
  await expect(dialog.getByText('Pedido sin sesión')).toBeVisible();
  const amount = dialog.getByText('35.000 CLP');
  await expect(amount).toBeVisible();
  const box = await amount.boundingBox();
  expect(box).not.toBeNull();
  expect(box!.x).toBeGreaterThanOrEqual(0);
  expect(box!.x + box!.width).toBeLessThanOrEqual(390);
});
