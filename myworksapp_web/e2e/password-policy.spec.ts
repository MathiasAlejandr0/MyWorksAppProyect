import { expect, test } from '@playwright/test';

async function openRegister(page: import('@playwright/test').Page) {
  await page.goto('/');
  const entrar = page.getByRole('button', { name: /ingresar|entrar|iniciar sesión/i });
  await expect(entrar.first()).toBeVisible({ timeout: 15_000 });
  await entrar.first().click();
  await page.getByRole('button', { name: /regístrate/i }).click();
  await expect(page.getByRole('heading', { name: 'Crear cuenta' })).toBeVisible();
}

test('el registro web exige 8 caracteres, una letra y un número', async ({ page }) => {
  await openRegister(page);

  await expect(page.getByText(/mínimo 8 caracteres, con al menos una letra y un número/i)).toBeVisible();

  await page.getByPlaceholder('Nombre completo').fill('Camila Soto');
  await page.getByPlaceholder('Email').fill('nueva.cliente@demo.myworksapp.cl');

  const password = page.getByPlaceholder('Contraseña');
  const submit = page.getByRole('button', { name: 'Registrarme' });

  await password.fill('abc12');
  await submit.click();
  await expect(page.getByRole('alert')).toHaveText(
    'La contraseña debe tener al menos 8 caracteres',
  );

  await password.fill('abcdefgh');
  await submit.click();
  await expect(page.getByRole('alert')).toHaveText('Incluye al menos un número');

  await password.fill('12345678');
  await submit.click();
  await expect(page.getByRole('alert')).toHaveText('Incluye al menos una letra');

  let signupCalls = 0;
  await page.route('**/auth/v1/signup**', async (route) => {
    signupCalls += 1;
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({
        user: { id: '22222222-2222-4222-8222-222222222222', email: 'nueva.cliente@demo.myworksapp.cl' },
        session: null,
      }),
    });
  });

  await password.fill('Demo2026!');
  await submit.click();
  await expect.poll(() => signupCalls).toBe(1);
});

test('el login reenvía la confirmación si el correo no está confirmado', async ({ page }) => {
  await page.route('**/auth/v1/token**', async (route) => {
    await route.fulfill({
      status: 400,
      contentType: 'application/json',
      body: JSON.stringify({
        error: 'email_not_confirmed',
        error_description: 'Email not confirmed',
        msg: 'Email not confirmed',
      }),
    });
  });

  let resendCalls = 0;
  await page.route('**/auth/v1/resend**', async (route) => {
    resendCalls += 1;
    const body = route.request().postDataJSON() as { type?: string; email?: string };
    if (body.type !== 'signup' || body.email !== 'invitado@demo.myworksapp.cl') {
      await route.fulfill({ status: 400, body: '{}' });
      return;
    }
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: '{}',
    });
  });

  await page.goto('/');
  const entrar = page.getByRole('button', { name: /ingresar|entrar|iniciar sesión/i });
  await expect(entrar.first()).toBeVisible({ timeout: 15_000 });
  await entrar.first().click();
  await expect(page.getByRole('heading', { name: 'Iniciar sesión' })).toBeVisible();

  await page.getByPlaceholder('Email').fill('invitado@demo.myworksapp.cl');
  await page.getByPlaceholder('Contraseña').fill('Demo2026!');
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('alert')).toContainText(/confirma tu correo/i);
  await page.getByRole('button', { name: 'Reenviar correo de confirmación' }).click();
  await expect.poll(() => resendCalls).toBe(1);
  await expect(page.getByRole('status')).toHaveText('Te enviamos un correo para confirmar.');
});
