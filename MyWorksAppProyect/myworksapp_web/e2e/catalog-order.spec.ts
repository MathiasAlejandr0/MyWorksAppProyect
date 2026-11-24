import { expect, test } from '@playwright/test';

// Orden único del catálogo: cercanía, luego nota, luego precio.
// Sin ubicación del cliente la cercanía no aplica: manda la nota y después el precio.
const base = {
  profesion: 'Gasfíter',
  descripcion: 'Gasfitería.',
  categoria_servicio: 'plomeria',
  zona_trabajo: 'Puerto Montt',
  ruta_foto_perfil: null,
  radio_servicio_km: 10,
  origen_base: 'mapa',
  trabajos_completados: 3,
};

// Llegan desordenados a propósito.
const pros = [
  { ...base, id_usuario: '11111111-1111-4111-8111-000000000003', nombre: 'Carla Barata', calificacion: 4.5, tarifa_visita: 20000, latitud_base: -41.47, longitud_base: -72.94 },
  { ...base, id_usuario: '11111111-1111-4111-8111-000000000001', nombre: 'Ana Nueva', calificacion: 0, tarifa_visita: 15000, latitud_base: -41.47, longitud_base: -72.94 },
  { ...base, id_usuario: '11111111-1111-4111-8111-000000000002', nombre: 'Bruno Top', calificacion: 4.9, tarifa_visita: 40000, latitud_base: -41.45, longitud_base: -72.81 },
  { ...base, id_usuario: '11111111-1111-4111-8111-000000000004', nombre: 'Diego Caro', calificacion: 4.5, tarifa_visita: 30000, latitud_base: -41.47, longitud_base: -72.94 },
];

const servicio = {
  id: 'svc-plomeria',
  nombre: 'Gasfitería y plomería',
  descripcion: 'Reparaciones de agua.',
  categoria: 'plomeria',
  activo: 1,
  modelo_precio: 'por_hora',
};

test('el catálogo web usa por defecto el orden cercanía, nota y precio', async ({ page }) => {
  let rpcBody: Record<string, unknown> | null = null;
  await page.route('**/*', async (route) => {
    const url = route.request().url();
    const supabase = url.includes('/rest/v1/') || url.includes('/auth/v1/');
    if (!supabase) {
      await route.continue();
      return;
    }
    if (url.includes('/rpc/categorias_con_disponibles')) {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(['plomeria']) });
      return;
    }
    if (url.includes('/rpc/listar_profesionales_catalogo')) {
      rpcBody = route.request().postDataJSON() as Record<string, unknown>;
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(pros) });
      return;
    }
    if (url.includes('/rest/v1/servicios')) {
      const accept = route.request().headers().accept ?? '';
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: accept.includes('vnd.pgrst.object') ? JSON.stringify(servicio) : JSON.stringify([servicio]),
      });
      return;
    }
    if (url.includes('/auth/v1/')) {
      await route.fulfill({ status: 400, contentType: 'application/json', body: JSON.stringify({ error: 'sin sesion' }) });
      return;
    }
    await route.fulfill({ status: 200, contentType: 'application/json', body: '[]' });
  });

  await page.goto('/');
  await page.getByRole('button', { name: /buscar servicio/i }).click();
  await page.getByRole('button', { name: /plomería/i }).click();

  const cards = page.locator('.pro-card');
  await expect(cards.first()).toBeVisible({ timeout: 15_000 });
  await expect(cards).toHaveCount(4);
  const names = async () =>
    (await cards.allTextContents()).map((text) =>
      ['Bruno Top', 'Carla Barata', 'Diego Caro', 'Ana Nueva'].find((name) => text.includes(name)),
    );

  // Nota 4.9 primero; empate en 4.5 lo gana la más barata; sin reseñas al final.
  expect(await names()).toEqual(['Bruno Top', 'Carla Barata', 'Diego Caro', 'Ana Nueva']);
  expect(rpcBody).toMatchObject({ p_categoria: 'plomeria', p_offset: 0, p_latitud: null, p_longitud: null });

  const orden = page.getByRole('button', { name: 'Ordenar por', exact: true });
  await orden.click();
  await page.getByRole('option', { name: 'Precio', exact: true }).click();
  expect(await names()).toEqual(['Ana Nueva', 'Carla Barata', 'Diego Caro', 'Bruno Top']);
});
