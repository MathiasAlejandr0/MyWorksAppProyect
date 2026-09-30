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

test('a 390 la portada muestra Ingresar y Registrarse', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/');
  await expect(page.getByRole('button', { name: 'Ingresar' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Registrarse' })).toBeVisible();
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
