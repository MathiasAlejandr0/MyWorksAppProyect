export type GeocodedSite = {
  latitude: number;
  longitude: number;
  label: string;
};

type PhotonFeature = {
  geometry?: { coordinates?: number[] };
  properties?: {
    name?: string;
    street?: string;
    housenumber?: string;
    city?: string;
    district?: string;
    state?: string;
    country?: string;
    countrycode?: string;
  };
};

type NominatimHit = {
  lat?: string;
  lon?: string;
  display_name?: string;
};

function featureLabel(feature: PhotonFeature, fallback: string): string {
  const p = feature.properties ?? {};
  const street = [p.street, p.housenumber].filter(Boolean).join(' ');
  const parts = [p.name, street, p.district, p.city, p.state].filter(
    (part, index, all) => Boolean(part) && all.indexOf(part) === index,
  );
  return parts.join(', ') || fallback;
}

function inChile(feature: PhotonFeature): boolean {
  const country = String(feature.properties?.country ?? '');
  const code = String(feature.properties?.countrycode ?? '');
  return /chile/i.test(country) || /^cl$/i.test(code);
}

function asSite(
  latitude: number,
  longitude: number,
  label: string,
): GeocodedSite | null {
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;
  return { latitude, longitude, label };
}

function fromPhoton(
  payload: { features?: PhotonFeature[] } | null,
  fallback: string,
): GeocodedSite | null {
  const features = payload?.features ?? [];
  const hit = features.find(inChile) ?? features[0];
  const coords = hit?.geometry?.coordinates;
  if (!coords || coords.length < 2) return null;
  return asSite(Number(coords[1]), Number(coords[0]), featureLabel(hit, fallback));
}

function fromNominatim(hits: NominatimHit[] | null, fallback: string): GeocodedSite | null {
  const hit = hits?.[0];
  if (!hit) return null;
  return asSite(Number(hit.lat), Number(hit.lon), hit.display_name?.trim() || fallback);
}

async function fetchJson(url: string): Promise<unknown | null> {
  try {
    const response = await fetch(url, { headers: { Accept: 'application/json' } });
    if (!response.ok) return null;
    return await response.json();
  } catch {
    return null;
  }
}

/** Dirección o barrio en Chile → GPS. Sirve en PCs sin ubicación del navegador. */
export async function geocodeChileAddress(query: string): Promise<GeocodedSite | null> {
  const trimmed = query.trim();
  if (trimmed.length < 3) return null;
  const search = /chile/i.test(trimmed) ? trimmed : `${trimmed}, Chile`;
  const q = encodeURIComponent(search);

  const photon = fromPhoton(
    (await fetchJson(`https://photon.komoot.io/api/?q=${q}&limit=8`)) as {
      features?: PhotonFeature[];
    } | null,
    search,
  );
  if (photon) return photon;

  return fromNominatim(
    (await fetchJson(
      `https://nominatim.openstreetmap.org/search?format=jsonv2&q=${q}&limit=5&countrycodes=cl`,
    )) as NominatimHit[] | null,
    search,
  );
}
