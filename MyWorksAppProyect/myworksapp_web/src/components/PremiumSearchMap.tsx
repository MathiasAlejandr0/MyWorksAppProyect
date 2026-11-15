import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  resolveServiceRadiusKm,
  transportSurcharge,
} from '@myworksapp/shared';
import type { SearchWorker } from './SearchResultsView';
import { addFastBasemap, fastMapOptions, isCoarseMap } from '../map/basemap';

/** Vista inicial si ningún profesional tiene coordenada propia (demo Puerto Montt). */
const DEMO_CENTER: [number, number] = [-41.4717, -72.9366];

export type ClientMapLocation = {
  latitude: number;
  longitude: number;
};

function mapBadge(workers: SearchWorker[], categoryLabel?: string): string {
  const placed = workers.filter((worker) => workerLatLng(worker)).length;
  if (!placed) return 'Ningún profesional tiene ubicación base todavía';
  return categoryLabel ? `${placed} en el mapa · ${categoryLabel}` : `${placed} en el mapa`;
}

function workerLatLng(worker: SearchWorker): [number, number] | null {
  if (typeof worker.latitude !== 'number' || typeof worker.longitude !== 'number') return null;
  if (!Number.isFinite(worker.latitude) || !Number.isFinite(worker.longitude)) return null;
  return [worker.latitude, worker.longitude];
}

function clp(amount: number): string {
  return Math.round(amount).toLocaleString('es-CL');
}

const pinIcon = L.divIcon({
  className: 'mwa-map-pin',
  html: '<span class="mwa-map-pin-dot"></span>',
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

const pinIconElite = L.divIcon({
  className: 'mwa-map-pin mwa-map-pin--elite',
  html: '<span class="mwa-map-pin-dot"></span>',
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

const pinIconActive = L.divIcon({
  className: 'mwa-map-pin mwa-map-pin--active',
  html: '<span class="mwa-map-pin-dot"></span>',
  iconSize: [36, 36],
  iconAnchor: [18, 18],
});

const clientIcon = L.divIcon({
  className: 'mwa-map-pin mwa-map-pin--client',
  html: '<span class="mwa-map-pin-dot"></span>',
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

function workerPopup(
  worker: SearchWorker,
  clientLocation: ClientMapLocation | null,
): HTMLElement {
  const root = document.createElement('div');
  root.className = 'mwa-map-popup';
  const title = document.createElement('strong');
  title.textContent = worker.name;
  const role = document.createElement('span');
  role.textContent = worker.isElite ? `${worker.profession} · Élite` : worker.profession;
  const meta = document.createElement('span');
  const price = clp(worker.pricePerVisit);
  meta.textContent = `★ ${worker.rating.toFixed(1)} · desde $${price}`;
  const radar = document.createElement('span');
  radar.className = 'mwa-map-radar';
  const radiusKm = resolveServiceRadiusKm(worker.serviceRadiusKm);
  const quote = transportSurcharge({
    workerLat: worker.latitude,
    workerLng: worker.longitude,
    jobLat: clientLocation?.latitude,
    jobLng: clientLocation?.longitude,
    radiusKm,
  });
  if (quote.insideRadar === true) {
    radar.classList.add('is-near');
    radar.textContent = `Dentro de ${radiusKm} km: sin extra de traslado`;
  } else if (quote.insideRadar === false) {
    radar.classList.add('is-extra');
    const km = quote.distanceKm?.toFixed(1) ?? '?';
    radar.textContent = `Fuera del área (${km} km): +$${clp(quote.extraClp)} de traslado`;
  } else {
    radar.textContent = `Hasta ${radiusKm} km cubre sin extra de traslado`;
  }
  root.append(title, role, meta, radar);
  return root;
}

/**
 * El recuento y la leyenda tapan la franja superior y la búsqueda de
 * dirección la inferior: los globos se acomodan dentro del espacio libre.
 */
const POPUP_OPTIONS: L.PopupOptions = {
  autoPanPaddingTopLeft: L.point(16, 150),
  autoPanPaddingBottomRight: L.point(16, 130),
  maxWidth: 240,
};

type PremiumSearchMapProps = {
  workers: SearchWorker[];
  selectedWorkerId: string | null;
  onSelectWorker: (worker: SearchWorker) => void;
  categoryLabel?: string;
  clientLocation?: ClientMapLocation | null;
  onPickClientLocation?: (location: ClientMapLocation) => void;
};

type StampedEl = HTMLElement & { _leaflet_id?: number };

/**
 * Mapa realista (OpenFreeMap Positron vía MapLibre) — sin API key.
 * Al elegir un profesional muestra su punto y el radar de trabajo cercano.
 */
export function PremiumSearchMap({
  workers,
  selectedWorkerId,
  onSelectWorker,
  categoryLabel,
  clientLocation = null,
  onPickClientLocation,
}: PremiumSearchMapProps) {
  const hostRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<string, L.Marker>>(new Map());
  const eliteRef = useRef<Set<string>>(new Set());
  const radarRef = useRef<L.Circle | null>(null);
  const clientMarkerRef = useRef<L.Marker | null>(null);
  const onSelectRef = useRef(onSelectWorker);
  const selectedIdRef = useRef(selectedWorkerId);
  const clientLocRef = useRef(clientLocation);
  const onPickRef = useRef(onPickClientLocation);
  onSelectRef.current = onSelectWorker;
  selectedIdRef.current = selectedWorkerId;
  clientLocRef.current = clientLocation;
  onPickRef.current = onPickClientLocation;

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    const stamped = host as StampedEl;
    if (stamped._leaflet_id != null) delete stamped._leaflet_id;

    const map = L.map(host, {
      scrollWheelZoom: true,
      zoomControl: true,
      ...fastMapOptions(),
    }).setView(DEMO_CENTER, 13);
    mapRef.current = map;
    const markers = markersRef.current;

    // Las baldosas se piden después de que los otros efectos dejen el encuadre
    // final. Si se agregan antes, el teléfono descarga dos niveles de zoom.
    let tilesAdded = false;
    const addTiles = () => {
      if (tilesAdded || mapRef.current !== map) return;
      tilesAdded = true;
      addFastBasemap(map);
    };
    queueMicrotask(addTiles);

    let resizeTimer = 0;
    const resize = () => {
      window.clearTimeout(resizeTimer);
      resizeTimer = window.setTimeout(() => {
        map.invalidateSize({ animate: false, pan: false });
      }, 160);
    };
    const timer = window.setTimeout(resize, 0);
    window.addEventListener('resize', resize);
    const observer = new ResizeObserver(resize);
    observer.observe(host);

    const onMapClick = (event: L.LeafletMouseEvent) => {
      if (!onPickRef.current) return;
      const target = event.originalEvent.target;
      if (
        target instanceof Element &&
        target.closest('.leaflet-marker-icon, .leaflet-popup, .mwa-map-pin')
      ) {
        return;
      }
      onPickRef.current({
        latitude: event.latlng.lat,
        longitude: event.latlng.lng,
      });
    };
    map.on('click', onMapClick);

    return () => {
      window.clearTimeout(timer);
      window.clearTimeout(resizeTimer);
      window.removeEventListener('resize', resize);
      observer.disconnect();
      map.off('click', onMapClick);
      markers.clear();
      radarRef.current = null;
      clientMarkerRef.current = null;
      mapRef.current = null;
      try {
        map.remove();
      } catch {
        if (stamped._leaflet_id != null) delete stamped._leaflet_id;
      }
    };
  }, []);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    for (const marker of markersRef.current.values()) marker.remove();
    markersRef.current.clear();
    eliteRef.current = new Set(workers.filter((worker) => worker.isElite).map((worker) => worker.id));

    const positions: L.LatLngExpression[] = [];
    for (const worker of workers) {
      const position = workerLatLng(worker);
      if (!position) continue;
      positions.push(position);
      const elite = worker.isElite === true;
      const marker = L.marker(position, {
        icon: elite ? pinIconElite : pinIcon,
        title: worker.name,
        keyboard: true,
      });
      marker.on('add', () => {
        marker
          .getElement()
          ?.setAttribute('aria-label', `${worker.name}, ${worker.profession}. Ver en el mapa`);
      });
      marker.bindPopup(workerPopup(worker, clientLocRef.current), POPUP_OPTIONS);
      marker.on('click', () => onSelectRef.current(worker));
      marker.addTo(map);
      markersRef.current.set(worker.id, marker);
    }

    map.invalidateSize({ animate: false, pan: false });
    if (selectedIdRef.current) return;

    if (!positions.length) {
      map.setView(DEMO_CENTER, 13, { animate: false });
    } else if (positions.length === 1) {
      map.setView(positions[0], 14, { animate: false });
    } else {
      map.fitBounds(L.latLngBounds(positions).pad(0.25), { animate: false, maxZoom: 14 });
    }
  }, [workers]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    for (const [id, marker] of markersRef.current) {
      const elite = eliteRef.current.has(id);
      marker.setIcon(
        id === selectedWorkerId ? pinIconActive : elite ? pinIconElite : pinIcon,
      );
    }

    radarRef.current?.remove();
    radarRef.current = null;

    const selected = workers.find((worker) => worker.id === selectedWorkerId);
    const position = selected ? workerLatLng(selected) : null;
    if (selected && position) {
      const radiusKm = resolveServiceRadiusKm(selected.serviceRadiusKm);
      const circle = L.circle(position, {
        radius: radiusKm * 1000,
        color: '#ff5e03',
        weight: 2,
        fillColor: '#ff5e03',
        fillOpacity: 0.12,
        className: 'mwa-map-radar-circle',
      }).addTo(map);
      radarRef.current = circle;
      const marker = markersRef.current.get(selected.id);
      marker?.setPopupContent(workerPopup(selected, clientLocRef.current));
      if (!isCoarseMap()) marker?.openPopup();
      map.invalidateSize({ animate: false, pan: false });
      map.fitBounds(circle.getBounds().pad(0.18), { animate: false, maxZoom: 14 });
      return;
    }

    const timer = window.setTimeout(() => map.invalidateSize(), 50);
    return () => window.clearTimeout(timer);
  }, [selectedWorkerId, workers]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    clientMarkerRef.current?.remove();
    clientMarkerRef.current = null;
    if (!clientLocation) return;
    const selected = workers.find((worker) => worker.id === selectedWorkerId);
    const quote = selected
      ? transportSurcharge({
          workerLat: selected.latitude,
          workerLng: selected.longitude,
          jobLat: clientLocation.latitude,
          jobLng: clientLocation.longitude,
          radiusKm: selected.serviceRadiusKm,
        })
      : null;
    let clientText = 'Tu trabajo. Arrástralo si quieres corregirlo.';
    if (quote?.insideRadar === true) {
      clientText = 'Estás dentro del área: sin extra de traslado';
    } else if (quote?.insideRadar === false) {
      const km = quote.distanceKm?.toFixed(1) ?? '?';
      clientText = `Fuera del área (${km} km): +$${clp(quote.extraClp)} de traslado`;
    }
    const marker = L.marker([clientLocation.latitude, clientLocation.longitude], {
      icon: clientIcon,
      draggable: true,
      zIndexOffset: 400,
      title: 'Ubicación de tu trabajo',
    });
    marker.on('add', () => {
      marker.getElement()?.setAttribute('aria-label', 'Ubicación de tu trabajo (se puede arrastrar)');
    });
    marker.bindPopup(clientText, POPUP_OPTIONS);
    marker.on('dragend', () => {
      const point = marker.getLatLng();
      onPickRef.current?.({ latitude: point.lat, longitude: point.lng });
    });
    marker.addTo(map);
    clientMarkerRef.current = marker;
    const point = L.latLng(clientLocation.latitude, clientLocation.longitude);
    if (!map.getBounds().contains(point)) {
      map.panTo(point, { animate: false });
    }
    if (selected) {
      markersRef.current
        .get(selected.id)
        ?.setPopupContent(workerPopup(selected, clientLocation));
    }
  }, [clientLocation, selectedWorkerId, workers]);

  const selected = workers.find((worker) => worker.id === selectedWorkerId) ?? workers[0];

  return (
    <div className="premium-search-map">
      <div ref={hostRef} className="premium-search-map-leaflet" />

      <div className="premium-search-map-chrome">
        <div className="premium-search-map-badge">
          {mapBadge(workers, categoryLabel)}
        </div>
        {selected && (
          <button
            type="button"
            className="premium-search-map-card"
            onClick={() => onSelectWorker(selected)}
          >
            <img src={selected.photoUrl} alt="" width={44} height={44} />
            <div>
              <strong>{selected.name}</strong>
              <span>
                {selected.profession}
                {selected.id === selectedWorkerId
                  ? ` · ${resolveServiceRadiusKm(selected.serviceRadiusKm)} km sin extra`
                  : ''}
              </span>
            </div>
          </button>
        )}
      </div>
    </div>
  );
}
