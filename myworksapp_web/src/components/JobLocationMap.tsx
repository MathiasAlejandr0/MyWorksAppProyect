import { useEffect, useRef } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const pinIcon = L.divIcon({
  className: 'mwa-map-pin mwa-map-pin--active',
  html: '<span class="mwa-map-pin-dot"></span>',
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

/** Mapa del domicilio del trabajo. No simula el movimiento del profesional. */
export function JobLocationMap({
  latitude,
  longitude,
  label,
}: {
  latitude: number;
  longitude: number;
  label: string;
}) {
  const host = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const node = host.current;
    if (!node) return;
    const map = L.map(node, { zoomControl: true }).setView([latitude, longitude], 15);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap',
    }).addTo(map);
    L.marker([latitude, longitude], { icon: pinIcon }).addTo(map).bindPopup(label);
    const frame = window.requestAnimationFrame(() => map.invalidateSize());
    return () => {
      window.cancelAnimationFrame(frame);
      map.remove();
    };
  }, [latitude, longitude, label]);

  return <div ref={host} className="job-location-map" role="region" aria-label="Mapa del domicilio" />;
}
