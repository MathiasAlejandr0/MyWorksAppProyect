import { expect, test } from '@playwright/test';

test.describe('Home smoke', () => {
  test('muestra hero y buscador de problema', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByText('My Works App').first()).toBeVisible();

    const search = page.getByPlaceholder(/fuga|describe/i);
    await expect(search).toBeVisible();
  });
});
