import { expect, test } from '@playwright/test';

const META =
  'Proyecto de título académico de Ingeniería en Informática, Duoc UC (sede Puerto Montt). Prototipo educativo de MyWorksApp: no es un servicio comercial. Los pagos se realizan con tarjetas de prueba de Transbank (ambiente de integración); no se cobra dinero real.';
const NOTE =
  'Sitio académico de demostración. Los pagos se realizan con tarjetas de prueba de Transbank (ambiente de integración); no se cobra dinero real. No ingreses datos de tarjetas reales.';

test.describe('aviso académico', () => {
  test('la franja se puede contraer y el indicador sigue visible', async ({ page }) => {
    await page.goto('/');
    const banner = page.getByRole('region', { name: 'Aviso de proyecto académico' });
    await expect(banner).toContainText('no es un servicio comercial');
    await expect(banner).toContainText('tarjetas de prueba de Transbank');
    await expect(banner).toContainText('no se cobra dinero real');
    await banner.getByRole('button', { name: 'Ocultar aviso' }).click();
    await expect(banner).toContainText('Proyecto de título académico — Duoc UC');
    await expect(banner).not.toContainText('no es un servicio comercial');
    await page.reload();
    await expect(banner).toBeVisible();
    await expect(banner).not.toContainText('no es un servicio comercial');
    await banner.getByRole('button', { name: 'Ver aviso' }).click();
    await expect(banner).toContainText('prototipo con fines educativos');
  });

  test('el footer enlaza al aviso legal y los metadatos no piden noindex', async ({ page }) => {
    await page.goto('/');
    await expect(page.locator('meta[name="description"]')).toHaveAttribute('content', META);
    await expect(page.locator('meta[property="og:description"]')).toHaveAttribute('content', META);
    await expect(page.locator('meta[name="robots"][content*="noindex"]')).toHaveCount(0);

    await page.getByRole('contentinfo').getByRole('link', { name: 'Aviso legal' }).first().click();
    await expect(page).toHaveURL(/\/aviso-legal$/);
    await expect(page.getByRole('heading', { level: 1, name: 'Aviso legal' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Sin empresa ni relación comercial' })).toBeVisible();
    await expect(page.getByText('Duoc UC no es responsable del contenido')).toBeVisible();
    await expect(page.getByText('ninguna transacción es real')).toBeVisible();
    await expect(page.getByRole('link', { name: 'tarjetas de prueba' })).toHaveAttribute(
      'href',
      /transbankdevelopers\.cl/,
    );
    await expect(page.locator('meta[name="robots"][content*="noindex"]')).toHaveCount(0);
  });

  test('términos y privacidad repiten el carácter académico', async ({ page }) => {
    await page.goto('/terminos');
    await expect(page.getByRole('heading', { level: 1, name: 'Términos y condiciones' })).toBeVisible();
    await expect(page.getByText('no es un servicio comercial').first()).toBeVisible();
    await expect(page.getByText('ninguna transacción es real')).toBeVisible();
    await expect(page.getByRole('link', { name: 'tarjetas de prueba' })).toHaveAttribute(
      'href',
      /transbankdevelopers\.cl/,
    );

    await page.goto('/privacidad');
    await expect(page.getByRole('heading', { level: 1, name: 'Política de privacidad' })).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Ley 19.628' })).toBeVisible();
    await expect(page.getByText('el equipo del proyecto de título MyWorksApp').first()).toBeVisible();
    await expect(page.getByText('Los datos de prueba se borran periódicamente.')).toBeVisible();
    await expect(page.getByText('ninguna transacción es real')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Abrir la encuesta de testing' })).toBeVisible();
  });

  test('el registro muestra la línea de demostración junto al botón', async ({ page }) => {
    await page.goto('/');
    await page.getByRole('button', { name: 'Registrarse' }).click();
    const dialog = page.getByRole('dialog');
    const note = dialog.getByTestId('academic-demo-note');
    const submit = dialog.getByRole('button', { name: 'Registrarme' });
    await expect(note).toHaveText(NOTE);
    await expect(note).toBeVisible();
    const noteBox = await note.boundingBox();
    const submitBox = await submit.boundingBox();
    expect(noteBox).not.toBeNull();
    expect(submitBox).not.toBeNull();
    expect(noteBox!.y).toBeLessThan(submitBox!.y);
  });
});
