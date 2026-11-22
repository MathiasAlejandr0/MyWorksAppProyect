import { expect, test } from '@playwright/test';

test.use({ video: 'on', viewport: { width: 1440, height: 900 } });

test('recorre reseñas, pedidos y disputas', async ({ page }) => {
  await page.goto('/resenas?captura=local');
  await expect(page.getByRole('heading', { name: 'Reseñas' })).toBeVisible();
  await page.getByRole('tab', { name: 'Negativas', exact: true }).click();
  await page.goto('/pedidos?captura=local');
  await page.getByLabel('Buscar en la tabla').fill('prueba');
  await expect(page.getByText('Calle de prueba 10')).toBeVisible();
  await page.goto('/disputas?captura=local');
  await page.getByRole('button', { name: 'Devolver a la tarjeta' }).click();
  await page.getByRole('button', { name: 'Cancelar' }).click();
  await expect(page.getByRole('dialog')).toBeHidden();
});
