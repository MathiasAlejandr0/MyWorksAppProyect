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
};

const servicio = {
  id: 'svc-plomeria',
  nombre: 'Gasfitería y plomería',
  descripcion: 'Reparaciones de agua.',
  categoria: 'plomeria',
  activo: 1,
  modelo_precio: 'por_hora',
};

test('demo web: catálogo con coordenada real y pedido sin tarjeta en el sitio', async ({
  page,
}) => {
  await page.route('**/*', async (route) => {
    const url = route.request().url();
    const supabase = url.includes('/rest/v1/') || url.includes('/auth/v1/');
    if (!supabase) {
      await route.continue();
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

  await page.goto('/');
  await page.getByRole('button', { name: /buscar servicio/i }).click();
  await page.getByRole('button', { name: /plomería/i }).click();

  const card = page.locator('.pro-card', { hasText: 'Pedro Rojas' });
  await expect(card).toBeVisible({ timeout: 15_000 });
  await expect(page.locator('.mwa-map-pin')).toHaveCount(1);

  await card.click();
  const reserve = page.getByRole('button', { name: /continuar con la reserva/i });
  await expect(reserve).toBeVisible();
  // La barra queda fija al borde inferior y Playwright no siempre puede desplazarla.
  await reserve.dispatchEvent('click');

  await expect(page.getByRole('dialog')).toBeVisible();
  await expect(page.getByText(/pedido sin sesión/i)).toBeVisible();
  await expect(page.locator('input[autocomplete="cc-number"]')).toHaveCount(0);
  await expect(page.getByLabel(/dirección/i)).toBeVisible();
});
