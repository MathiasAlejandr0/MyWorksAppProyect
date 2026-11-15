import L from 'leaflet';
import { setWorkerUrl } from 'maplibre-gl';
import { MaplibreGL, maplibreGL } from '@maplibre/maplibre-gl-leaflet';
import workerUrl from 'maplibre-gl/dist/maplibre-gl-worker.mjs?worker&url';
import 'maplibre-gl/dist/maplibre-gl.css';

setWorkerUrl(workerUrl);

type GuardedLayer = {
  _map: L.Map | null;
  _glMap: { jumpTo: (o: object) => void; once: (e: string, f: () => void) => void; _actualCanvas: HTMLElement } | null;
  _resizeContainer: () => void;
  _zoomEnd: () => void;
};

/**
 * El plugin programa trabajo con requestAnimationFrame y en `moveend`.
 * Si el mapa se desmonta antes (cambio de vista, StrictMode), `_map` ya es
 * null y lanzaba «Cannot read properties of null (reading 'getZoom')».
 * Aquí cada paso diferido revisa que la capa siga montada.
 */
function guardDeferredLayerWork(): void {
  const proto = (MaplibreGL as unknown as { prototype: Record<string, unknown> }).prototype;
  if (proto.__mwaGuarded) return;
  proto.__mwaGuarded = true;
  const alive = (layer: GuardedLayer) => Boolean(layer._map && layer._glMap);
  for (const name of ['_update', '_zoomEnd', '_pinchZoom', '_animateZoom', '_resize']) {
    const original = proto[name] as ((this: GuardedLayer, ...args: unknown[]) => unknown) | undefined;
    if (typeof original !== 'function') continue;
    proto[name] = function guarded(this: GuardedLayer, ...args: unknown[]) {
      if (!alive(this)) return undefined;
      return original.apply(this, args);
    };
  }
  proto._transitionEnd = function transitionEnd(this: GuardedLayer) {
    L.Util.requestAnimFrame(() => {
      const map = this._map;
      const gl = this._glMap;
      if (!map || !gl) return;
      const zoom = map.getZoom();
      const center = map.getCenter();
      const offset = map.latLngToContainerPoint(map.getBounds().getNorthWest());
      this._resizeContainer();
      L.DomUtil.setTransform(gl._actualCanvas, offset, 1);
      gl.once('moveend', () => {
        if (alive(this)) this._zoomEnd();
      });
      gl.jumpTo({ center, zoom: zoom - 1 });
    });
  };
}

guardDeferredLayerWork();

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
