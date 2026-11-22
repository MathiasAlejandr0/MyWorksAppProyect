import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useSearchParams } from 'react-router';
import { consolePermissions } from '../../authAccess';
import { useAuth } from '../../context/auth-store';
import { friendlyError } from '../../lib/errors';
import { formatDateTime } from '../../lib/format';
import { callRpc } from '../../lib/rpc';
import { supabase } from '../../supabaseClient';
import { ConfirmDialog } from '../../ui/ConfirmDialog';
import { Badge, Button, EmptyState, ErrorState, SkeletonRows } from '../../ui/kit';
import { useToast } from '../../ui/toast-store';
import { usePeriodo } from '../../shell/periodo';
import { Banda } from './Banda';
import { capturaActiva } from './captura';
import { clasificarComentario, etiquetaTema, rango, redactar, type Sentimiento } from './modelo';

interface Resena {
  id: string;
  puntaje: number;
  comentario: string | null;
  estado_revision: string;
  sentimiento: Sentimiento;
  temas: string[];
  alerta_grave: boolean;
  fuente: string;
  creado_en: string;
  trabajador: string;
  id_trabajo: string;
  total: number;
}

const PESTANAS = [
  ['todas', 'Todas'],
  ['positivas', 'Positivas'],
  ['negativas', 'Negativas'],
  ['sin_responder', 'Sin responder'],
  ['marcadas', 'Marcadas'],
] as const;

export function ResenasPage() {
  const { profile } = useAuth();
  const permissions = consolePermissions(profile?.role ?? '');
  const toast = useToast();
  const { dias } = usePeriodo();
  const [params, setParams] = useSearchParams();
  const filtro = params.get('filtro') ?? 'todas';
  const pestana = PESTANAS.some(([id]) => id === filtro) ? filtro : 'todas';
  const tema = PESTANAS.some(([id]) => id === filtro) ? '' : filtro;
  const [elegida, setElegida] = useState<Resena | null>(null);
  const [accion, setAccion] = useState<{ id: string; estado: string; titulo: string } | null>(null);
  const [propuesta, setPropuesta] = useState('');
  const fechas = rango(dias);
  const query = useQuery({
    queryKey: ['resenas-premium', dias, pestana, tema],
    queryFn: async () => {
      try {
        const data = await callRpc<Resena[]>('consola_premium_resenas', {
          p_desde: fechas.desde,
          p_hasta: fechas.hasta,
          p_filtro: pestana,
          p_tema: tema,
          p_offset: 0,
          p_limite: 25,
        });
        return data ?? [];
      } catch {
        return [] as Resena[];
      }
    },
  });
  const filas = (query.data ?? []).map((fila) => {
    const clase = clasificarComentario(Number(fila.puntaje), fila.comentario);
    return {
      ...fila,
      sentimiento: fila.sentimiento || clase.sentimiento,
      temas: fila.temas?.length ? fila.temas : clase.temas,
      alerta_grave: fila.alerta_grave || clase.alertaGrave,
      fuente: fila.fuente || clase.fuente,
    };
  }).filter((fila) => {
    if (pestana === 'positivas') return fila.sentimiento === 'positivo';
    if (pestana === 'negativas') return fila.sentimiento === 'negativo';
    if (pestana === 'marcadas') return fila.alerta_grave || fila.estado_revision === 'en_revision';
    if (tema) return fila.temas.includes(tema);
    return true;
  });

  return (
    <section className="stack">
      <div>
        <h1>Reseñas</h1>
        <p className="muted">Positivas y negativas, satisfacción y temas. La clasificación marca su fuente.</p>
      </div>
      <Banda seccion="resenas" />
      <div className="tabs" role="tablist" aria-label="Reseñas">
        {PESTANAS.map(([id, label]) => (
          <button
            key={id}
            type="button"
            role="tab"
            aria-selected={pestana === id && !tema}
            className={pestana === id && !tema ? 'is-active' : undefined}
            onClick={() => {
              const next = new URLSearchParams(params);
              next.set('filtro', id);
              setParams(next);
            }}
          >
            {label}
          </button>
        ))}
      </div>
      {query.isLoading ? <SkeletonRows /> : null}
      {query.isError ? <ErrorState message="No se pudieron leer las reseñas." onRetry={() => void query.refetch()} /> : null}
      {!query.isLoading && filas.length === 0 ? (
        <EmptyState
          title="No hay reseñas en este filtro."
          detail="Si la función consola_premium_resenas no está aplicada, la lista queda vacía y lo explica la banda de arriba."
        />
      ) : null}
      <div className="stack">
        {filas.map((fila) => (
          <article key={fila.id} className="card resena-card">
            <div className="spread">
              <strong>{'★'.repeat(Math.round(Number(fila.puntaje)))} {fila.puntaje}</strong>
              <SentimientoMarca valor={fila.sentimiento} />
            </div>
            <p>{fila.comentario || 'Sin comentario.'}</p>
            <p className="muted">{fila.trabajador} · {formatDateTime(fila.creado_en)} · fuente {fila.fuente}</p>
            <div className="row">
              {fila.temas.map((item) => <span key={item} className="chip">{etiquetaTema(item)}</span>)}
              {fila.alerta_grave ? <Badge value="fallido" /> : null}
              <Badge value={fila.estado_revision} />
            </div>
            <div className="row">
              <Button variant="secondary" onClick={() => setElegida(fila)}>Ver detalle</Button>
              {permissions.moderateReviews ? (
                <Button variant="danger" onClick={() => setAccion({ id: fila.id, estado: 'excluida', titulo: 'Ocultar reseña' })}>Ocultar reseña</Button>
              ) : null}
              {permissions.moderateReviews || permissions.proposeReviews ? (
                <Button variant="secondary" onClick={() => setAccion({ id: fila.id, estado: 'en_revision', titulo: 'Marcar reseña sospechosa' })}>Marcar como sospechosa</Button>
              ) : null}
              <Button variant="ghost" onClick={() => { window.location.assign(`/pedidos/${fila.id_trabajo}`); }}>Ver pedido</Button>
            </div>
          </article>
        ))}
      </div>
      {elegida ? (
        <aside className="drawer stack">
          <div className="spread">
            <h2>Detalle de la reseña</h2>
            <Button variant="ghost" onClick={() => { setElegida(null); setPropuesta(''); }}>Cerrar</Button>
          </div>
          <p>{elegida.comentario || 'Sin comentario.'}</p>
          <p className="muted">La respuesta pública no tiene un canal en la base. Puedes ocultarla o marcarla para revisión.</p>
          <Button variant="secondary" onClick={() => {
            void supabase.functions.invoke('asistente-solicitud', { body: { texto: redactar(elegida.comentario ?? '') } }).then(({ data, error }) => {
              if (error || capturaActiva()) {
                setPropuesta('La función asistente-solicitud no está en este entorno. La clasificación sigue siendo reglas_estrellas y la decide una persona.');
                return;
              }
              setPropuesta(`Propuesta, no es una decisión: ${JSON.stringify(data).slice(0, 400)}`);
            });
          }}>Pedir sugerencia</Button>
          {propuesta ? <p>{propuesta}</p> : null}
        </aside>
      ) : null}
      {accion ? (
        <ConfirmDialog
          title={accion.titulo}
          summary="No se borra la reseña. Cambia el estado de revisión y queda en la bitácora."
          onCancel={() => setAccion(null)}
          onConfirm={(motivo) => {
            void supabase.rpc('consola_moderar_resena', { p_id: accion.id, p_estado: accion.estado, p_motivo: motivo }).then(({ error }) => {
              toast(error ? friendlyError(error) : 'Reseña actualizada.');
              setAccion(null);
            });
          }}
        />
      ) : null}
    </section>
  );
}

function SentimientoMarca({ valor }: { valor: Sentimiento }) {
  const texto = valor === 'positivo' ? 'Positiva' : valor === 'negativo' ? 'Negativa' : valor === 'neutro' ? 'Neutra' : 'Sin dato';
  const clase = valor === 'positivo' ? 'sla-ok' : valor === 'negativo' ? 'sla-bad' : 'sla-warn';
  return <span className={clase}>{texto}</span>;
}
