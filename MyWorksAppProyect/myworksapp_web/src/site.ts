/** Dominio que responde hoy. myworksapp.cl no se usa hasta que resuelva. */
export const PUBLIC_SITE_URL = String(
  import.meta.env.VITE_PUBLIC_SITE_URL || 'https://myworksapp-cl.vercel.app',
).replace(/\/$/, '');

export const APP_COMMIT = String(import.meta.env.VITE_APP_COMMIT || 'dev');
