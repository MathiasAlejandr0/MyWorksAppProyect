import { expect, test } from '@playwright/test';

test.describe('Encuesta de testing (SUS)', () => {
  test('el enlace /encuesta abre las 10 afirmaciones SUS', async ({ page }) => {
    await page.goto('/encuesta');
    await expect(
      page.getByRole('heading', { name: /cómo te fue probando myworksapp/i }),
    ).toBeVisible({ timeout: 15_000 });
    await expect(page.locator('.survey-sus li')).toHaveCount(10);
    await expect(page.getByRole('button', { name: /enviar encuesta/i })).toBeVisible();
  });

  test('no envía si faltan afirmaciones por responder', async ({ page }) => {
    await page.goto('/?encuesta');
    await page.getByRole('button', { name: /enviar encuesta/i }).click();
    await expect(page.getByRole('alert')).toContainText(/10 afirmaciones/);
  });
});
