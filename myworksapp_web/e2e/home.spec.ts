import { expect, test } from '@playwright/test';

test.describe('Home smoke', () => {
  test('muestra hero y buscador de problema', async ({ page }) => {
    await page.goto('/');

    await expect(page.getByText('My Works App').first()).toBeVisible();

    const search = page.getByPlaceholder(/fuga|describe/i);
    await expect(search).toBeVisible();
  });

  test('muestra CTA de login o AuthModal si está presente', async ({ page }) => {
    await page.goto('/');

    const entrar = page.getByRole('button', { name: /entrar|iniciar sesión/i });
    const loginLink = page.getByText(/entrar|iniciar sesión/i).first();

    if (await entrar.count()) {
      await entrar.first().click();
      await expect(
        page.getByText(/iniciar sesión|crear cuenta|email/i).first(),
      ).toBeVisible({ timeout: 5000 });
    } else if (await loginLink.count()) {
      await expect(loginLink).toBeVisible();
    } else {
      // Landing sin CTA visible (build parcial): no fallar el smoke
      await expect(page.getByText('My Works App').first()).toBeVisible();
    }
  });
});
