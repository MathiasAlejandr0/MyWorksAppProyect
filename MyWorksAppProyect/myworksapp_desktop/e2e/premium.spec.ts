import { mkdir } from 'node:fs/promises';
import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';

const DIR = '/agent/repos/MyWorksAppProyect/MyWorksAppProyect/docs/pruebas/consola-premium/capturas';

const SECCIONES = [
  ['/resumen?captura=local', 'inicio'],
  ['/pedidos?captura=local', 'pedidos'],
  ['/disputas?captura=local', 'disputas'],
  ['/resenas?captura=local', 'resenas'],
  ['/usuarios?captura=local', 'clientes'],
  ['/profesionales?captura=local', 'trabajadores'],
  ['/verificaciones?captura=local', 'verificaciones'],
  ['/pagos?captura=local', 'pagos'],
  ['/tickets?captura=local', 'soporte'],
  ['/notificaciones?captura=local', 'notificaciones'],
  ['/seguridad?captura=local', 'seguridad'],
  ['/informes?captura=local', 'reportes'],
  ['/auditoria?captura=local', 'auditoria'],
  ['/ajustes?captura=local', 'configuracion'],
] as const;

test.use({ video: 'off', viewport: { width: 1440, height: 900 } });

for (const tema of ['light', 'dark'] as const) {
  test(`cada sección carga, filtra y confirma en tema ${tema}`, async ({ page }) => {
    await mkdir(DIR, { recursive: true });
    await page.addInitScript((nombre) => {
      localStorage.setItem('mwa-tema', nombre);
    }, tema);

    for (const [ruta, nombre] of SECCIONES) {
      await page.goto(ruta);
      await expect(page.locator('h1').first()).toBeVisible();
      await expect(page.getByText('¿Qué mide esto?').first()).toBeVisible();
      await page.screenshot({ path: `${DIR}/${nombre}-${tema}.png`, fullPage: true });
      const axe = await new AxeBuilder({ page }).analyze();
      const criticos = axe.violations.filter((item) => item.impact === 'critical');
      expect(criticos, criticos.map((item) => item.id).join(', ')).toEqual([]);
    }

    await page.goto('/pedidos?captura=local');
    await page.getByLabel('Buscar en la tabla').fill('prueba');
    await expect(page.getByText('Calle de prueba 10')).toBeVisible();

    await page.goto('/disputas?captura=local');
    await expect(page.getByText('Trabajo incompleto')).toBeVisible();
    await page.getByRole('button', { name: 'Devolver a la tarjeta' }).click();
    await page.getByLabel('Motivo (mínimo 10 caracteres)').fill('Prueba local sin mover dinero');
    await page.getByLabel('Frase de confirmación').fill('REEMBOLSAR');
    await page.getByLabel('Código de la aplicación de autenticación').fill('000000');
    await page.getByRole('button', { name: 'Confirmar' }).click();
    await expect(page.getByText('Captura local: no se envió dinero.')).toBeVisible();

    await page.goto('/resenas?captura=local');
    await page.getByRole('tab', { name: 'Negativas', exact: true }).click();
    await expect(page).toHaveURL(/filtro=negativas/);
    await expect(page.getByText('Llegó puntual')).toHaveCount(0);
    await page.getByRole('button', { name: 'Ver detalle' }).click();
    await expect(page.getByRole('heading', { name: 'Detalle de la reseña' })).toBeVisible();
    await page.getByRole('button', { name: 'Pedir sugerencia' }).click();
    await expect(page.getByText('La función asistente-solicitud no está en este entorno.')).toBeVisible();
    await page.getByRole('button', { name: 'Marcar como sospechosa' }).click();
    await page.getByLabel('Motivo (mínimo 10 caracteres)').fill('Marca de prueba, no es una sanción');
    await page.getByRole('button', { name: 'Cancelar' }).click();
    await expect(page.getByRole('dialog')).toBeHidden();

    await page.goto('/sistema-diseno?captura=local');
    await expect(page.getByText(/10\.000 filas\. En pantalla hay/)).toBeVisible();
    const pintadas = await page.locator('.virtual-row').count();
    expect(pintadas).toBeLessThan(40);
    await page.locator('.virtual-scroll').evaluate((node) => {
      node.scrollTop = node.scrollHeight;
    });
    await expect(page.getByText('Fila 10000')).toBeVisible();
    await page.screenshot({ path: `${DIR}/sistema-diseno-${tema}.png`, fullPage: false });
  });
}
