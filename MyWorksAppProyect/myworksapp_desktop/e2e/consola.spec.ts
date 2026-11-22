import { createHmac } from 'node:crypto';
import { mkdir } from 'node:fs/promises';
import { expect, test } from '@playwright/test';

const OUT = '/opt/cursor/artifacts/consola';

const RUTAS = [
  ['/resumen', 'inicio'],
  ['/pedidos', 'pedidos'],
  ['/disputas', 'disputas'],
  ['/tickets', 'tickets'],
  ['/reportes', 'reportes'],
  ['/usuarios', 'clientes'],
  ['/profesionales', 'profesionales'],
  ['/pagos', 'pagos'],
  ['/liquidaciones', 'liquidaciones'],
  ['/reembolsos', 'reembolsos'],
  ['/conciliacion', 'conciliacion'],
  ['/finanzas', 'finanzas'],
  ['/resenas', 'resenas'],
  ['/catalogo', 'catalogo'],
  ['/notificaciones', 'notificaciones'],
  ['/equipo', 'equipo'],
  ['/auditoria', 'auditoria'],
  ['/ajustes', 'ajustes'],
  ['/seguridad', 'seguridad'],
  ['/salud', 'salud'],
  ['/errores', 'errores'],
  ['/cuenta', 'cuenta'],
] as const;

test('la consola entra, muestra cada módulo y ejecuta pruebas y respaldo', async ({ page }) => {
  await mkdir(OUT, { recursive: true });
  let secreto = '';
  page.on('response', async (response) => {
    if (!response.url().includes('/factors') || response.request().method() !== 'POST') return;
    const body = await response.json().catch(() => null) as { totp?: { secret?: string } } | null;
    if (body?.totp?.secret) secreto = body.totp.secret;
  });

  await page.goto('/');
  await page.locator('#login-email').fill('admin.consola@local.test');
  await page.locator('#login-password').fill('Admin1234');
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('heading', { name: 'Segundo factor' })).toBeVisible();
  await expect.poll(() => secreto, { timeout: 10_000 }).not.toBe('');
  await page.getByLabel('Código de 6 dígitos').fill(codigoTotp(secreto));
  await page.getByRole('button', { name: 'Entrar' }).click();
  await expect(page.getByRole('heading', { name: 'Inicio' })).toBeVisible();
  await page.screenshot({ path: `${OUT}/00-inicio-numeros.png`, fullPage: true });

  for (const [ruta, nombre] of RUTAS) {
    await page.goto(ruta);
    await page.locator('h1').first().waitFor();
    await page.screenshot({ path: `${OUT}/${nombre}.png`, fullPage: true });
  }

  await page.goto('/ajustes');
  await expect(page.getByText('demo_modo').first()).toBeVisible();
  await page.goto('/disputas');
  await expect(page.getByText('Trabajo incompleto')).toBeVisible();
  await page.goto('/seguridad');
  await expect(page.getByRole('link', { name: 'Seguridad' })).toBeVisible();
  for (const nombre of ['Resumen', 'Actividad', 'Pruebas', 'Defensa', 'Respaldos', 'Umbrales']) {
    await page.getByRole('tab', { name: nombre }).click();
    await page.screenshot({ path: `${OUT}/seguridad-${nombre.toLowerCase()}.png`, fullPage: true });
  }
  await page.getByRole('tab', { name: 'Pruebas' }).click();
  await page.getByRole('button', { name: 'RLS' }).click();
  await expect(page.getByText(/RLS|tablas|política|politica/i).first()).toBeVisible();

  await page.getByRole('tab', { name: 'Defensa' }).click();
  await expect(page.getByRole('button', { name: 'Modo bloqueo total' })).toBeVisible();
  await expect(page.getByRole('switch', { name: 'Solo lectura' })).toBeVisible();

  await page.getByRole('tab', { name: 'Respaldos' }).click();
  await page.getByRole('button', { name: 'Crear respaldo' }).click();
  await page.getByLabel('Motivo (mínimo 10 caracteres)').fill('Respaldo de la prueba local de la consola');
  await page.getByRole('button', { name: 'Confirmar' }).click();
  await expect(page.getByText('Listo.')).toBeVisible({ timeout: 30_000 });
  await expect(page.getByText(/KB|MB|B de/).first()).toBeVisible();
  await expect(page.getByText('Listo.')).toBeHidden({ timeout: 10_000 });
  await page.screenshot({ path: `${OUT}/seguridad-respaldo.png`, fullPage: true });
  await page.getByRole('button', { name: 'Restaurar' }).first().click();
  await page.getByLabel('Frase de confirmación').fill('RESTAURAR');
  await page.getByLabel('Motivo (mínimo 10 caracteres)').fill('Restauracion de la prueba local');
  await page.getByRole('button', { name: 'Confirmar' }).click();
  await expect(page.getByRole('dialog')).toBeHidden({ timeout: 30_000 });
  await expect(page.getByText('Listo.')).toBeVisible();
  await page.screenshot({ path: `${OUT}/seguridad-restauracion.png`, fullPage: true });
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
