import { useEffect, useState } from 'react';
import { estimateEtaMinutes, haversineKm } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

export type LiveFix = {
  latitude: number;
  longitude: number;
  distanceKm: number | null;
  etaMinutes: number | null;
};

export function useLiveJobLocation(
  jobId: string | null,
  destinationLat?: number | null,
  destinationLng?: number | null,
): { fix: LiveFix | null; error: string | null } {
  const [fix, setFix] = useState<LiveFix | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!jobId) {
      setFix(null);
      return;
    }
    let cancelled = false;

    const apply = (row: { latitud?: number | null; longitud?: number | null } | null) => {
      if (cancelled) return;
      const latitude = row?.latitud == null ? null : Number(row.latitud);
      const longitude = row?.longitud == null ? null : Number(row.longitud);
      if (latitude == null || longitude == null || !Number.isFinite(latitude) || !Number.isFinite(longitude)) {
        setFix(null);
        return;
      }
      const hasDest = typeof destinationLat === 'number' && typeof destinationLng === 'number';
      const distanceKm = hasDest ? haversineKm(latitude, longitude, destinationLat, destinationLng) : null;
      setFix({
        latitude,
        longitude,
        distanceKm,
        etaMinutes: distanceKm == null ? null : estimateEtaMinutes(distanceKm),
      });
    };

    void supabase
      .from('ubicacion_en_vivo')
      .select('latitud, longitud')
      .eq('id_trabajo', jobId)
      .maybeSingle()
      .then(({ data, error: readError }) => {
        if (readError) setError('No hay canal de ubicación. Aplica la migración de GPS.');
        else {
          setError(null);
          apply(data);
        }
      });

    const channel = supabase
      .channel(`gps-${jobId}`)
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'ubicacion_en_vivo', filter: `id_trabajo=eq.${jobId}` },
        (payload) => {
          if (payload.eventType === 'DELETE') apply(null);
          else apply(payload.new as { latitud?: number; longitud?: number });
        },
      )
      .subscribe();

    return () => {
      cancelled = true;
      void supabase.removeChannel(channel);
    };
  }, [jobId, destinationLat, destinationLng]);

  return { fix, error };
}
