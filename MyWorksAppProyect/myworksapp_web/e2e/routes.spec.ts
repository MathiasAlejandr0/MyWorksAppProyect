import { test, expect } from '@playwright/test';

test.describe('rutas', () => {
  test('el atrás vuelve a la vista anterior y /xyz es un 404', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('link', { name: /servicios/i }).first().click().catch(async () => {
      await page.getByRole('button', { name: /ver todas/i }).click();
    });
    await page.goBack();
    await expect(page).toHaveURL(/\/$/);
    await page.goto('/xyz');
    await expect(page.getByRole('heading', { name: /no encontramos esa página/i })).toBeVisible();
    await expect(page.locator('meta[name="robots"]')).toHaveAttribute('content', /noindex/);
  });
});
