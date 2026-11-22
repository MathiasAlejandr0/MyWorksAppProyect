/** Solo existe en el servidor de desarrollo. El build de producción lo deja en falso. */
export function capturaActiva(): boolean {
  return import.meta.env.DEV
    && typeof window !== 'undefined'
    && new URLSearchParams(window.location.search).get('captura') === 'local';
}
