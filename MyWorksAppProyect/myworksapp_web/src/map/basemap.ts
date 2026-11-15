import L from 'leaflet';

const CARTO =
  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

/** Teléfono o puntero táctil: ahí el zoom animado pide varios niveles de baldosas y se pega. */
export function isCoarseMap(): boolean {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return false;
  return window.matchMedia('(max-width: 900px), (pointer: coarse)').matches;
}

/**
 * Capa base rápida. Sin `{r}` (retina cuadruplica los píxeles) y sin pedir
 * baldosas mientras el dedo todavía se mueve.
 */
export function addFastBasemap(map: L.Map): L.TileLayer {
  const cartoKey = (import.meta.env.VITE_CARTO_BASEMAPS_KEY ?? '').trim();
  const keyQuery = cartoKey ? `?key=${encodeURIComponent(cartoKey)}` : '';
  return L.tileLayer(`${CARTO}${keyQuery}`, {
    subdomains: 'abcd',
    maxZoom: 19,
    updateWhenIdle: true,
    updateWhenZooming: false,
    keepBuffer: 0,
    detectRetina: false,
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> · &copy; <a href="https://carto.com/">CARTO</a>',
  }).addTo(map);
}

export function fastMapOptions(): L.MapOptions {
  const phone = isCoarseMap();
  return {
    fadeAnimation: false,
    markerZoomAnimation: false,
    zoomAnimation: !phone,
    zoomSnap: phone ? 1 : 0.25,
    zoomDelta: phone ? 1 : 0.5,
    inertia: !phone,
    minZoom: 4,
    maxZoom: 18,
  };
}
