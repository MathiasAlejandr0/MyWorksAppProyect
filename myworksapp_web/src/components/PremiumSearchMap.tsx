import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import type { SearchWorker } from './SearchResultsView';

/** Vista inicial si ningún profesional tiene coordenada propia. */
export const SANTIAGO_CENTER: [number, number] = [-33.45, -70.66];

function mapBadge(workers: SearchWorker[], categoryLabel?: string): string {
  const placed = workers.filter((worker) => workerLatLng(worker)).length;
  if (!placed) return 'Ningún profesional tiene ubicación base todavía';
  return categoryLabel ? `${placed} en el mapa · ${categoryLabel}` : `${placed} en el mapa`;
}

export function workerLatLng(worker: SearchWorker): [number, number] | null {
  if (typeof worker.latitude !== 'number' || typeof worker.longitude !== 'number') return null;
  if (!Number.isFinite(worker.latitude) || !Number.isFinite(worker.longitude)) return null;
  return [worker.latitude, worker.longitude];
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

function workerPopup(name: string, profession: string, detail: string): HTMLElement {
  const root = document.createElement('div');
  root.className = 'mwa-map-popup';
  const title = document.createElement('strong');
  title.textContent = name;
  const role = document.createElement('span');
  role.textContent = profession;
  const meta = document.createElement('span');
  meta.textContent = detail;
  root.append(title, role, meta);
  return root;
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
 * Solo muestra profesionales con latitud y longitud guardadas.
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

    // CARTO pide llave desde agosto de 2026: sin ella cada tile sale con «API KEY REQUIRED».
    // Con VITE_CARTO_BASEMAPS_KEY se usa Voyager; si no, las tiles estándar de OpenStreetMap.
    const cartoKey = (import.meta.env.VITE_CARTO_BASEMAPS_KEY ?? '').trim();
    const osmAttribution =
      '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>';
    L.tileLayer(
      cartoKey
        ? `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png?key=${encodeURIComponent(cartoKey)}`
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      cartoKey
        ? {
            attribution: `${osmAttribution} · &copy; <a href="https://carto.com/">CARTO</a>`,
            subdomains: 'abcd',
            maxZoom: 19,
          }
        : { attribution: osmAttribution, maxZoom: 19 },
    ).addTo(map);

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
      if (!position) continue;
      positions.push(position);
      const price = Math.round(worker.pricePerVisit).toLocaleString('es-CL');
      const marker = L.marker(position, { icon: pinIcon });
      marker.bindPopup(
        workerPopup(worker.name, worker.profession, `★ ${worker.rating.toFixed(1)} · desde $${price}`),
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
          {mapBadge(workers, categoryLabel)}
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
