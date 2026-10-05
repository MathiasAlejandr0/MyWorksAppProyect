import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const homeIcon = L.divIcon({
  className: 'mwa-map-pin mwa-map-pin--active',
  html: '<span class="mwa-map-pin-dot"></span>',
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

const workerIcon = L.divIcon({
  className: 'mwa-map-pin mwa-map-pin--worker',
  html: '<span class="mwa-map-pin-dot"></span>',
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

type Point = { latitude: number; longitude: number; label: string };

function textPopup(text: string): HTMLElement {
  const node = document.createElement('div');
  node.textContent = text;
  return node;
}

/** Domicilio del pedido y, si existe, el pin en vivo del profesional. */
export function JobLocationMap({
  latitude,
  longitude,
  label,
  worker,
}: {
  latitude: number;
  longitude: number;
  label: string;
  worker?: Point | null;
}) {
  const host = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const homeRef = useRef<L.Marker | null>(null);
  const workerRef = useRef<L.Marker | null>(null);

  useEffect(() => {
    const node = host.current;
    if (!node) return;
    const map = L.map(node, { zoomControl: true }).setView([latitude, longitude], 15);
    mapRef.current = map;
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap',
    }).addTo(map);
    homeRef.current = L.marker([latitude, longitude], { icon: homeIcon }).addTo(map).bindPopup(textPopup(label));
    const frame = window.requestAnimationFrame(() => map.invalidateSize());
    return () => {
      window.cancelAnimationFrame(frame);
      workerRef.current = null;
      homeRef.current = null;
      mapRef.current = null;
      map.remove();
    };
  }, [latitude, longitude, label]);

  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;
    if (!worker) {
      workerRef.current?.remove();
      workerRef.current = null;
      return;
    }
    const at: L.LatLngExpression = [worker.latitude, worker.longitude];
    if (!workerRef.current) {
      workerRef.current = L.marker(at, { icon: workerIcon }).addTo(map).bindPopup(textPopup(worker.label));
    } else {
      workerRef.current.setLatLng(at);
      workerRef.current.setPopupContent(textPopup(worker.label));
    }
    const bounds = L.latLngBounds([
      [latitude, longitude],
      [worker.latitude, worker.longitude],
    ]);
    map.fitBounds(bounds.pad(0.3));
  }, [worker, latitude, longitude]);

  return <div ref={host} className="job-location-map" role="region" aria-label="Mapa del domicilio" />;
}
