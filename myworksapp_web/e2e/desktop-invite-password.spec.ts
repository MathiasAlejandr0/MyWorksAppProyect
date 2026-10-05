import { expect, test } from '@playwright/test';

/**
 * El preview del escritorio se levanta aparte en 4174.
 * Sin DESKTOP_PREVIEW el resto de la suite web no depende de ese proceso.
 */
test.skip(!process.env.DESKTOP_PREVIEW, 'requiere el preview del escritorio en 4174');

test('la invitación de RRHH exige la misma política de contraseña', async ({ page }) => {
  await page.goto('http://127.0.0.1:4174/#type=invite');

  await expect(page.getByRole('heading', { name: 'Activa tu acceso' })).toBeVisible({
    timeout: 20_000,
  });
  await expect(page.getByText(/al menos 8 caracteres, con una letra y un número/i)).toBeVisible();

  const password = page.getByLabel('NUEVA CONTRASEÑA');
  const confirm = page.getByLabel('CONFIRMAR CONTRASEÑA');
  const submit = page.getByRole('button', { name: 'Guardar contraseña' });

  await password.fill('abc12');
  await confirm.fill('abc12');
  await submit.click();
  await expect(page.getByRole('alert')).toHaveText(
    'La contraseña debe tener al menos 8 caracteres',
  );

  await password.fill('abcdefgh');
  await confirm.fill('abcdefgh');
  await submit.click();
  await expect(page.getByRole('alert')).toHaveText('Incluye al menos un número');

  await password.fill('12345678');
  await confirm.fill('12345678');
  await submit.click();
  await expect(page.getByRole('alert')).toHaveText('Incluye al menos una letra');

  await password.fill('Demo2026!');
  await confirm.fill('Otra2026!');
  await submit.click();
  await expect(page.getByRole('alert')).toHaveText('Las contraseñas no coinciden');
});
