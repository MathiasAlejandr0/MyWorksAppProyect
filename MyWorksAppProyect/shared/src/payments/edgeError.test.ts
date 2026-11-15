import assert from 'node:assert/strict';
import { test } from 'node:test';
import { edgeFunctionErrorMessage } from './edgeError.ts';

test('usa el error en español del cuerpo de la función', async () => {
  const context = new Response(
    JSON.stringify({ error: 'Este profesional todavía no está verificado para cobrar' }),
    { status: 400 },
  );
  const msg = await edgeFunctionErrorMessage(
    { message: 'Edge Function returned a non-2xx status code', context },
    'No se pudo iniciar Webpay',
  );
  assert.equal(msg, 'Este profesional todavía no está verificado para cobrar');
});

test('sin cuerpo JSON no muestra el texto en inglés de supabase-js', async () => {
  const msg = await edgeFunctionErrorMessage(
    { message: 'Edge Function returned a non-2xx status code', context: new Response('x', { status: 500 }) },
    'No se pudo iniciar Webpay',
  );
  assert.equal(msg, 'No se pudo iniciar Webpay');
});

test('conserva otros mensajes de red', async () => {
  const msg = await edgeFunctionErrorMessage({ message: 'Failed to fetch' }, 'fallback');
  assert.equal(msg, 'Failed to fetch');
});
