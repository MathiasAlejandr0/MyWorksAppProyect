import { expect, test } from '@playwright/test';

const ID = '11111111-1111-4111-8111-111111111111';

test('la ficha pública envía el id de la URL a las RPC', async ({ page }) => {
  const seen: string[] = [];
  await page.route('**/*', async (route) => {
    const url = route.request().url();
    const supabase = url.includes('/rest/v1/') || url.includes('/auth/v1/');
    if (!supabase) {
      await route.continue();
      return;
    }
    if (url.includes('/rpc/')) {
      const body = route.request().postDataJSON() as { p_id?: string } | null;
      if (body?.p_id) seen.push(body.p_id);
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: '[]',
      });
      return;
    }
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: '[]',
    });
  });

  await page.goto(`/profesional/${ID}`);
  await expect(page.getByText('Este profesional no está en el catálogo público.')).toBeVisible();
  expect(seen.length).toBeGreaterThan(0);
  expect(seen.every((value) => value === ID)).toBe(true);
});
