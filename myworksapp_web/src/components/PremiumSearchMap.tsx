import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { SearchWorker } from './SearchResultsView';

/** Centro por defecto: Las Condes, Santiago de Chile. */
export const SANTIAGO_CENTER: [number, number] = [-33.4172, -70.5476];

function hashOffset(id: string, spread = 0.035): [number, number] {
  let h = 0;
  for (let i = 0; i < id.length; i++) h = (h * 31 + id.charCodeAt(i)) >>> 0;
  const lat = ((h % 1000) / 1000 - 0.5) * spread;
  const lng = (((h / 1000) % 1000) / 1000 - 0.5) * spread;
  return [lat, lng];
}

export function workerLatLng(worker: SearchWorker): [number, number] {
  const [dLat, dLng] = hashOffset(worker.id);
  return [SANTIAGO_CENTER[0] + dLat, SANTIAGO_CENTER[1] + dLng];
}

const pinIcon = L.divIcon({
  className: 'mwa-map-pin',
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

function escapeHtml(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');
}

type PremiumSearchMapProps = {
  workers: SearchWorker[];
  selectedWorkerId: string | null;
  onSelectWorker: (worker: SearchWorker) => void;
  categoryLabel?: string;
};

type StampedEl = HTMLElement & { _leaflet_id?: number };

/**
 * Mapa realista (OpenStreetMap + estilo Carto Voyager) — sin API key.
 * Posiciones ilustrativas alrededor de Las Condes para la demo.
 *
 * Leaflet se crea una sola vez. Elegir un profesional solo cambia el pin,
 * sin volver a montar el mapa (eso dejaba la página en negro).
 */
export function PremiumSearchMap({
  workers,
  selectedWorkerId,
  onSelectWorker,
  categoryLabel,
}: PremiumSearchMapProps) {
  const hostRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<string, L.Marker>>(new Map());
  const onSelectRef = useRef(onSelectWorker);
  onSelectRef.current = onSelectWorker;

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    const stamped = host as StampedEl;
    if (stamped._leaflet_id != null) delete stamped._leaflet_id;

    const map = L.map(host, { scrollWheelZoom: true, zoomControl: true }).setView(
      SANTIAGO_CENTER,
      13,
    );
    mapRef.current = map;

    L.tileLayer(
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
      {
        attribution:
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> · &copy; <a href="https://carto.com/">CARTO</a>',
        subdomains: 'abcd',
        maxZoom: 19,
      },
    ).addTo(map);

    L.circle(SANTIAGO_CENTER, {
      radius: 2200,
      color: '#FF5E03',
      fillColor: '#FF5E03',
      fillOpacity: 0.06,
      weight: 1.5,
      dashArray: '6 8',
    }).addTo(map);

    const resize = () => map.invalidateSize();
    const timer = window.setTimeout(resize, 0);
    window.addEventListener('resize', resize);

    return () => {
      window.clearTimeout(timer);
      window.removeEventListener('resize', resize);
      markersRef.current.clear();
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

    const positions: L.LatLngExpression[] = [];
    for (const worker of workers) {
      const position = workerLatLng(worker);
      positions.push(position);
      const price = Math.round(worker.pricePerVisit).toLocaleString('es-CL');
      const marker = L.marker(position, { icon: pinIcon });
      marker.bindPopup(
        `<div class="mwa-map-popup"><strong>${escapeHtml(worker.name)}</strong><span>${escapeHtml(worker.profession)}</span><span>★ ${worker.rating.toFixed(1)} · desde $${price}</span></div>`,
      );
      marker.on('click', () => onSelectRef.current(worker));
      marker.addTo(map);
      markersRef.current.set(worker.id, marker);
    }

    if (!positions.length) {
      map.setView(SANTIAGO_CENTER, 13);
    } else if (positions.length === 1) {
      map.setView(positions[0], 14);
    } else {
      map.fitBounds(L.latLngBounds(positions).pad(0.25));
    }
  }, [workers]);

  useEffect(() => {
    for (const [id, marker] of markersRef.current) {
      marker.setIcon(id === selectedWorkerId ? pinIconActive : pinIcon);
    }
    const timer = window.setTimeout(() => mapRef.current?.invalidateSize(), 50);
    return () => window.clearTimeout(timer);
  }, [selectedWorkerId]);

  return (
    <div className="premium-search-map">
      <div ref={hostRef} className="premium-search-map-leaflet" />

      <div className="premium-search-map-chrome">
        <div className="premium-search-map-badge">
          {categoryLabel
            ? `Referencia · ${categoryLabel}`
            : 'Mapa · Santiago (Las Condes)'}
        </div>
        {workers[0] && (
          <button
            type="button"
            className="premium-search-map-card"
            onClick={() => onSelectWorker(workers[0])}
          >
            <img src={workers[0].photoUrl} alt="" />
            <div>
              <strong>{workers[0].name}</strong>
              <span>{workers[0].profession}</span>
            </div>
          </button>
        )}
      </div>
    </div>
  );
}
