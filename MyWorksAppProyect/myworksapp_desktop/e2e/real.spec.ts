import { createHmac } from 'node:crypto';
import { mkdir } from 'node:fs/promises';
import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const DIR = '/agent/repos/MyWorksAppProyect/MyWorksAppProyect/docs/pruebas/consola-premium/capturas';

const SECCIONES = [
  ['/resumen', 'inicio'],
  ['/pedidos', 'pedidos'],
  ['/disputas', 'disputas'],
  ['/resenas', 'resenas'],
  ['/usuarios', 'clientes'],
  ['/profesionales', 'trabajadores'],
  ['/verificaciones', 'verificaciones'],
  ['/pagos', 'pagos'],
  ['/tickets', 'soporte'],
  ['/notificaciones', 'notificaciones'],
  ['/seguridad', 'seguridad'],
  ['/informes', 'reportes'],
  ['/auditoria', 'auditoria'],
  ['/ajustes', 'configuracion'],
  ['/sistema-diseno', 'sistema-diseno'],
] as const;

test.use({ video: 'off', viewport: { width: 1440, height: 900 } });

test('la sesión real con aal2 recorre reseñas, pedidos, disputas y pagos', async ({ page }) => {
  await mkdir(DIR, { recursive: true });
  let secreto = '';
  page.on('response', async (response) => {
    if (!response.url().includes('/factors') || response.request().method() !== 'POST') return;
    const body = await response.json().catch(() => null) as { totp?: { secret?: string } } | null;
    if (body?.totp?.secret) secreto = body.totp.secret;
  });

  await page.goto('/');
  await expect(page).not.toHaveURL(/captura=local/);
  await page.locator('#login-email').fill('admin.consola@local.test');
  await page.locator('#login-password').fill('Admin1234');
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('heading', { name: 'Segundo factor' })).toBeVisible();
  await expect.poll(() => secreto, { timeout: 15_000 }).not.toBe('');
  await page.getByLabel('Código de 6 dígitos').fill(codigoTotp(secreto));
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('heading', { name: 'Inicio' })).toBeVisible();
  await expect(page.getByText('Muestra local de desarrollo')).toHaveCount(0);

  for (const tema of ['dark', 'light'] as const) {
    if (tema === 'light') {
      await page.getByRole('button', { name: /Admin de prueba/ }).click();
      await page.getByRole('button', { name: 'Tema claro' }).click();
    }
    for (const [ruta, nombre] of SECCIONES) {
      await page.goto(ruta);
      await expect(page.locator('h1').first()).toBeVisible();
      await expect(page).not.toHaveURL(/captura/);
      await page.screenshot({ path: `${DIR}/${nombre}-${tema}.png`, fullPage: true });
    }
  }

  await page.goto('/resenas');
  await page.getByRole('tab', { name: 'Negativas', exact: true }).click();
  await expect(page).toHaveURL(/filtro=negativas/);
  await expect(page.getByText('No llegó y el trato fue una amenaza')).toBeVisible();
  await page.getByRole('button', { name: 'Ver detalle' }).click();
  await expect(page.getByRole('heading', { name: 'Detalle de la reseña' })).toBeVisible();
  await page.getByRole('button', { name: 'Cerrar' }).click();

  await page.goto('/pedidos');
  await page.getByLabel('Buscar en la tabla').fill('prueba');
  await expect(page.getByText('Calle de prueba 10')).toBeVisible();

  await page.goto('/disputas');
  await expect(page.getByRole('strong').filter({ hasText: 'Trabajo incompleto' })).toBeVisible();
  await page.getByRole('button', { name: 'Devolver a la tarjeta' }).first().click();
  await page.getByLabel('Motivo (mínimo 10 caracteres)').fill('Prueba local sin pasarela de dinero');
  await page.getByLabel('Frase de confirmación').fill('REEMBOLSAR');
  await page.getByRole('button', { name: 'Confirmar' }).click();
  await expect(page.getByText('Disputa actualizada.')).toHaveCount(0);
  await expect(page.getByText(/No se pudo|no está|Failed|fetch/i).first()).toBeVisible();
  await page.getByRole('button', { name: 'Cancelar' }).click();

  await page.goto('/pagos');
  await expect(page.getByRole('heading', { name: 'Pagos y comisiones' })).toBeVisible();
  const liberar = page.getByRole('button', { name: 'Liberar' });
  if (await liberar.count()) {
    await liberar.first().click();
    await page.getByLabel('Motivo (mínimo 10 caracteres)').fill('Prueba local sin liberar dinero');
    await page.getByLabel('Frase de confirmación').fill('LIBERAR');
    await page.getByRole('button', { name: 'Cancelar' }).click();
    await expect(page.getByText('Pago liberado.')).toHaveCount(0);
  }

  const axe = await new AxeBuilder({ page }).analyze();
  expect(axe.violations.filter((item) => item.impact === 'critical')).toEqual([]);
});

function codigoTotp(secret: string): string {
  const alfabeto = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  const limpio = secret.replace(/=+$/g, '').toUpperCase().replace(/[^A-Z2-7]/g, '');
  let bits = '';
  for (const caracter of limpio) bits += alfabeto.indexOf(caracter).toString(2).padStart(5, '0');
  const bytes: number[] = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) bytes.push(Number.parseInt(bits.slice(i, i + 8), 2));
  const contador = Buffer.alloc(8);
  contador.writeBigUInt64BE(BigInt(Math.floor(Date.now() / 30_000)));
  const hmac = createHmac('sha1', Buffer.from(bytes)).update(contador).digest();
  const offset = hmac[hmac.length - 1] & 0xf;
  const codigo = ((hmac[offset] & 0x7f) << 24 | hmac[offset + 1] << 16 | hmac[offset + 2] << 8 | hmac[offset + 3]) % 1_000_000;
  return String(codigo).padStart(6, '0');
}
