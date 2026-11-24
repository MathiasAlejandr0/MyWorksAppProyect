/** Dominio canónico. myworksapp-cl.vercel.app sigue como alias del mismo despliegue. */
export const PUBLIC_SITE_URL = String(
  import.meta.env.VITE_PUBLIC_SITE_URL || 'https://myworksapp.cl',
).replace(/\/$/, '');

export const APP_COMMIT = String(import.meta.env.VITE_APP_COMMIT || 'dev');
