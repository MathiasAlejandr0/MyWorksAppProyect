import { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { EVENTOS_USO, profilePhotoOrInitials, type ProfesionalParecido } from '@myworksapp/shared';
import { registrarEventoUso } from '../analytics/registrarEvento';
import { SiteFooter } from '../components/SiteFooter';
import { StarScore } from '../components/StarScore';
import { leerProfesionalesParecidos, leerResumenResenas } from '../data/fichaPublica';
import { usePageMeta } from '../hooks/usePageMeta';
import { supabase } from '../supabaseClient';
import type { SearchWorker } from '../components/SearchResultsView';

type ProfileRow = {
  id_usuario: string;
  nombre: string | null;
  profesion: string | null;
  descripcion: string | null;
  zona_trabajo: string | null;
  radio_servicio_km: number | null;
  tarifa_visita: number | null;
  ruta_foto_perfil: string | null;
  verificado: boolean | null;
  calificacion: number | null;
  n_calificaciones: number | null;
  trabajos_completados: number | null;
  es_elite: boolean | null;
  categoria: string | null;
};

type Review = {
  nota: number;
  comentario: string | null;
  fecha: string | null;
  nombre_corto: string | null;
};

type Slot = { dia_semana: number; hora_inicio: string; hora_fin: string };

const DAYS = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

type Loose = {
  rpc: (fn: string, args: Record<string, unknown>) => Promise<{
    data: unknown;
    error: { message: string } | null;
  }>;
};

export function ProfessionalProfilePage({
  onReserve,
}: {
  onReserve: (worker: SearchWorker) => void;
}) {
  const { pathname } = useLocation();
  const id = decodeURIComponent(pathname.match(/^\/profesional\/([^/?#]+)/)?.[1] ?? '');
  const [row, setRow] = useState<ProfileRow | null>(null);
  const [hours, setHours] = useState<Slot[]>([]);
  const [reviews, setReviews] = useState<Review[]>([]);
  const [resumen, setResumen] = useState<string | null>(null);
  const [parecidos, setParecidos] = useState<ProfesionalParecido[]>([]);
  const [status, setStatus] = useState<'loading' | 'ready' | 'empty' | 'error'>('loading');

  useEffect(() => {
    let cancelled = false;
    setResumen(null);
    setParecidos([]);
    const db = supabase as unknown as Loose;
    void Promise.all([
      db.rpc('perfil_publico_profesional', { p_id: id }),
      db.rpc('horario_publico_profesional', { p_id: id }),
      db.rpc('resenas_publicas_profesional', { p_id: id }),
    ]).then(([profile, schedule, notes]) => {
      if (cancelled) return;
      if (profile.error || schedule.error || notes.error) {
        setStatus('error');
        return;
      }
      const found = Array.isArray(profile.data) ? profile.data[0] as ProfileRow | undefined : null;
      if (!found) {
        setRow(null);
        setStatus('empty');
        return;
      }
      setRow(found);
      setHours(Array.isArray(schedule.data) ? schedule.data as Slot[] : []);
      setReviews(Array.isArray(notes.data) ? notes.data as Review[] : []);
      setStatus('ready');
      registrarEventoUso(EVENTOS_USO.vioFicha, { id_profesional: id });
      void Promise.all([leerResumenResenas(id), leerProfesionalesParecidos(id)]).then(([texto, lista]) => {
        if (cancelled) return;
        setResumen(texto);
        setParecidos(lista);
      });
    }).catch(() => {
      if (!cancelled) setStatus('error');
    });
    return () => {
      cancelled = true;
    };
  }, [id]);

  const name = row?.nombre?.trim() || 'Profesional';
  usePageMeta(
    status === 'ready' ? name : 'Profesional',
    status === 'ready'
      ? `${name}, ${row?.profesion || 'oficio'}.`
      : 'Ficha pública de un profesional de MyWorksApp.',
    status !== 'ready',
  );

  const reserve = () => {
    if (!row) return;
    onReserve({
      id: row.id_usuario,
      name,
      profession: row.profesion || 'Oficio',
      category: row.categoria || '',
      rating: Number(row.calificacion ?? 0),
      jobsDone: Number(row.trabajos_completados ?? 0),
      photoUrl: profilePhotoOrInitials(row.ruta_foto_perfil, name, row.id_usuario),
      pricePerVisit: Number(row.tarifa_visita ?? 0),
    });
  };

  return (
    <div className="min-h-screen app-shell">
      <main className="container legal-page">
        <Link to="/servicios">Volver a servicios</Link>
        {status === 'loading' ? <p role="status">Cargando la ficha…</p> : null}
        {status === 'error' ? <p role="alert">No se pudo leer la ficha. Inténtalo de nuevo.</p> : null}
        {status === 'empty' ? <p role="status">Este profesional no está en el catálogo público.</p> : null}
        {status === 'ready' && row ? (
          <article className="profile-public">
            <img
              src={profilePhotoOrInitials(row.ruta_foto_perfil, name, row.id_usuario)}
              alt=""
              width={96}
              height={96}
            />
            <h1>{name}</h1>
            <p>{row.profesion || 'Sin dato de oficio'}</p>
            {row.es_elite ? <p>Élite</p> : null}
            {row.verificado ? <p>Verificado</p> : null}
            <p>{row.descripcion?.trim() || 'Sin descripción.'}</p>
            <p>Zona: {row.zona_trabajo?.trim() || 'Sin dato'}</p>
            <p>
              Radio: {row.radio_servicio_km == null ? 'Sin dato' : `${row.radio_servicio_km} km`}
            </p>
            <p>
              Tarifa de visita: {row.tarifa_visita == null ? 'Sin dato' : `$${Number(row.tarifa_visita).toLocaleString('es-CL')}`}
            </p>
            {Number(row.n_calificaciones ?? 0) > 0 ? (
              <p>
                <StarScore rating={Number(row.calificacion ?? 0)} /> {Number(row.calificacion).toFixed(1)} · {row.n_calificaciones} reseñas · {row.trabajos_completados ?? 0} trabajos
              </p>
            ) : (
              <p>Nuevo · sin reseñas aún</p>
            )}
            {resumen ? (
              <>
                <h2>Resumen de reseñas</h2>
                <p>{resumen}</p>
              </>
            ) : null}
            <h2>Horario</h2>
            {hours.length === 0 ? <p>Sin horario publicado.</p> : (
              <ul>
                {hours.map((slot) => (
                  <li key={`${slot.dia_semana}-${slot.hora_inicio}`}>
                    {DAYS[slot.dia_semana] || 'Día'} {slot.hora_inicio}–{slot.hora_fin}
                  </li>
                ))}
              </ul>
            )}
            <h2>Reseñas</h2>
            {reviews.length === 0 ? <p>Sin reseñas publicadas.</p> : (
              <ul>
                {reviews.map((review, index) => (
                  <li key={`${review.fecha}-${index}`}>
                    <StarScore rating={Number(review.nota)} />
                    <span> {review.nombre_corto || 'Cliente'}</span>
                    {review.fecha ? <time dateTime={review.fecha}> · {review.fecha.slice(0, 10)}</time> : null}
                    {review.comentario ? <p>{review.comentario}</p> : null}
                  </li>
                ))}
              </ul>
            )}
            {parecidos.length > 0 ? (
              <>
                <h2>Profesionales parecidos</h2>
                <ul>
                  {parecidos.map((item) => (
                    <li key={item.id}>
                      <Link to={`/profesional/${item.id}`}>{item.nombre}</Link>
                      <span> · {item.profesion}</span>
                      {item.calificacion == null ? null : (
                        <span> · {item.calificacion.toFixed(1)}</span>
                      )}
                    </li>
                  ))}
                </ul>
              </>
            ) : null}
            <button type="button" className="btn-primary" onClick={reserve}>Reservar</button>
          </article>
        ) : null}
      </main>
      <SiteFooter />
    </div>
  );
}
