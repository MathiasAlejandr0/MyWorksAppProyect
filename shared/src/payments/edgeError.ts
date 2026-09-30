/**
 * supabase-js pone en `error.message` «Edge Function returned a non-2xx status code».
 * El texto en español que devolvió la función viene en el cuerpo (`error.context`).
 */
export async function edgeFunctionErrorMessage(
  error: { message?: string; context?: unknown } | null | undefined,
  fallback: string,
): Promise<string> {
  const ctx = error?.context as { json?: () => Promise<unknown>; clone?: () => { json: () => Promise<unknown> } } | undefined;
  try {
    const reader = typeof ctx?.clone === 'function' ? ctx.clone() : ctx;
    const body = typeof reader?.json === 'function' ? await reader.json() : null;
    if (body && typeof body === 'object' && 'error' in body) {
      const msg = (body as { error?: unknown }).error;
      if (typeof msg === 'string' && msg.trim()) return msg;
    }
  } catch {
    // cuerpo vacío, ya leído o no JSON
  }
  const raw = error?.message || '';
  if (!raw || /non-2xx status code/i.test(raw)) return fallback;
  return raw;
}
