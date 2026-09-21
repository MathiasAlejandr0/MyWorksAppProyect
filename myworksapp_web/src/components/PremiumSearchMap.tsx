import { useEffect, useMemo } from 'react';
import {
  MapContainer,
  TileLayer,
  Marker,
  Popup,
  Circle,
  useMap,
} from 'react-leaflet';
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
  html: `<span class="mwa-map-pin-dot"></span>`,
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

const pinIconActive = L.divIcon({
  className: 'mwa-map-pin mwa-map-pin--active',
  html: `<span class="mwa-map-pin-dot"></span>`,
  iconSize: [36, 36],
  iconAnchor: [18, 18],
});

function FitWorkers({
  positions,
}: {
  positions: [number, number][];
}) {
  const map = useMap();
  useEffect(() => {
    if (!positions.length) {
      map.setView(SANTIAGO_CENTER, 13);
      return;
    }
    if (positions.length === 1) {
      map.setView(positions[0], 14);
      return;
    }
    const bounds = L.latLngBounds(positions.map((p) => L.latLng(p[0], p[1])));
    map.fitBounds(bounds.pad(0.25));
  }, [map, positions]);
  return null;
}

type PremiumSearchMapProps = {
  workers: SearchWorker[];
  selectedWorkerId: string | null;
  onSelectWorker: (worker: SearchWorker) => void;
  categoryLabel?: string;
};

/**
 * Mapa realista (OpenStreetMap + estilo Carto Voyager) — sin API key.
 * Posiciones ilustrativas alrededor de Las Condes para la demo.
 */
export function PremiumSearchMap({
  workers,
  selectedWorkerId,
  onSelectWorker,
  categoryLabel,
}: PremiumSearchMapProps) {
  const markers = useMemo(
    () =>
      workers.map((w) => ({
        worker: w,
        position: workerLatLng(w),
      })),
    [workers],
  );

  const positions = markers.map((m) => m.position);

  return (
    <div className="premium-search-map">
      <MapContainer
        center={SANTIAGO_CENTER}
        zoom={13}
        className="premium-search-map-leaflet"
        scrollWheelZoom
        zoomControl
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> · &copy; <a href="https://carto.com/">CARTO</a>'
          url="https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png"
          subdomains="abcd"
          maxZoom={19}
        />
        <Circle
          center={SANTIAGO_CENTER}
          radius={2200}
          pathOptions={{
            color: '#FF5E03',
            fillColor: '#FF5E03',
            fillOpacity: 0.06,
            weight: 1.5,
            dashArray: '6 8',
          }}
        />
        <FitWorkers positions={positions} />
        {markers.map(({ worker, position }) => (
          <Marker
            key={worker.id}
            position={position}
            icon={worker.id === selectedWorkerId ? pinIconActive : pinIcon}
            eventHandlers={{
              click: () => onSelectWorker(worker),
            }}
          >
            <Popup>
              <div className="mwa-map-popup">
                <strong>{worker.name}</strong>
                <span>{worker.profession}</span>
                <span>
                  ★ {worker.rating.toFixed(1)} · desde $
                  {Math.round(worker.pricePerVisit).toLocaleString('es-CL')}
                </span>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>

      <div className="premium-search-map-chrome">
        <div className="premium-search-map-badge">
          {categoryLabel
            ? `Cerca · ${categoryLabel}`
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
