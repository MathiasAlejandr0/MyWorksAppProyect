import L from 'leaflet';
import { setWorkerUrl } from 'maplibre-gl';
import { maplibreGL } from '@maplibre/maplibre-gl-leaflet';
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url';
import 'maplibre-gl/dist/maplibre-gl.css';

setWorkerUrl(workerUrl);

/** Positron: fondo claro y neutro para que los pines naranja de la marca se lean bien. */
export const OPENFREEMAP_STYLE = 'https://tiles.openfreemap.org/styles/positron';

const ATTRIBUTION =
  '<a href="https://openfreemap.org" target="_blank" rel="noopener">OpenFreeMap</a> © <a href="https://www.openmaptiles.org/" target="_blank" rel="noopener">OpenMapTiles</a> © <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap contributors</a>';

/** Teléfono o puntero táctil: ahí el zoom animado pide varios niveles de baldosas y se pega. */
export function isCoarseMap(): boolean {
  if (typeof window === 'undefined' || typeof window.matchMedia !== 'function') return false;
  return window.matchMedia('(max-width: 900px), (pointer: coarse)').matches;
}

/**
 * Capa base vectorial de OpenFreeMap (sin API key). Leaflet sigue manejando
 * pines, círculos, popups y clics; MapLibre solo pinta el mapa.
 */
export function addFastBasemap(map: L.Map): L.Layer {
  return maplibreGL({
    style: OPENFREEMAP_STYLE,
    attributionControl: { compact: true, customAttribution: ATTRIBUTION },
    interactive: false,
    maplibreLogo: false,
    fadeDuration: 0,
    maxZoom: 19,
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
    maxZoom: 19,
  };
}
