import { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { consolePermissions } from '../authAccess';
import { useAuth } from '../context/auth-store';
import { describeLoadError, friendlyError } from '../lib/errors';
import { formatDateTime } from '../lib/format';
import { agruparSenalesResena, type SenalResenaFila } from '../lib/senalesResena';
import { supabase } from '../supabaseClient';
import { ConfirmDialog } from '../ui/ConfirmDialog';
import { Badge, Button, EmptyState, ErrorState } from '../ui/kit';
import { useToast } from '../ui/toast-store';

function asPromise<T>(value: PromiseLike<T>): Promise<T> {
  return Promise.resolve(value);
}

export function ColaResenasDudosas() {
  const { profile } = useAuth();
  const permissions = consolePermissions(profile?.role ?? '');
  const toast = useToast();
  const client = useQueryClient();
  const [target, setTarget] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const query = useQuery({
    queryKey: ['senales-resena'],
    enabled: permissions.moderateReviews,
    queryFn: async () => {
      const { data, error } = await supabase.rpc('listar_senales_resena', {
        p_estado: 'pendiente',
        p_limit: 80,
      });
      if (error) throw error;
      return agruparSenalesResena((data ?? []) as SenalResenaFila[]);
    },
  });

  if (!permissions.moderateReviews) return null;

  const filas = query.data ?? [];
  return (
    <section className="stack">
      <h2>Reseñas dudosas</h2>
      <p className="muted">Las marcó el registro de la calificación. Ocultar usa la misma moderación de reseñas.</p>
      {query.isLoading ? <p role="status">Cargando la cola…</p> : null}
      {query.isError ? (
        <ErrorState message={describeLoadError(query.error, 'No se pudo leer la cola.')} onRetry={() => void query.refetch()} />
      ) : null}
      {!query.isLoading && !query.isError && filas.length === 0 ? (
        <EmptyState title="No hay reseñas marcadas." />
      ) : null}
      {filas.map((fila) => (
        <article key={fila.idCalificacion} className="panel">
          <strong>{fila.profesional}</strong>
          <p>{fila.cliente} · {fila.puntaje ?? '—'} · {fila.senales.join(', ')}</p>
          <p>{fila.comentario?.trim() || 'Sin comentario.'}</p>
          {fila.detalle ? <p className="muted">{fila.detalle}</p> : null}
          <p className="muted">{formatDateTime(fila.creadoEn)}</p>
          <Badge value={fila.estadoRevision} />
          {fila.estadoRevision === 'excluida' ? null : (
            <Button variant="secondary" onClick={() => setTarget(fila.idCalificacion)}>Ocultar</Button>
          )}
        </article>
      ))}
      {target ? (
        <ConfirmDialog
          title="Moderar reseña"
          summary="No se borra. Cambia el estado de revisión."
          busy={busy}
          onCancel={() => setTarget(null)}
          onConfirm={(motivo) => {
            setBusy(true);
            void asPromise(supabase.rpc('consola_moderar_resena', {
              p_id: target,
              p_estado: 'excluida',
              p_motivo: motivo,
            })).then(async ({ error }) => {
              if (error) {
                toast(friendlyError(error));
                return;
              }
              toast('Reseña actualizada.');
              await client.invalidateQueries({ queryKey: ['senales-resena'] });
              await client.invalidateQueries({ queryKey: ['resenas'] });
              setTarget(null);
            }).finally(() => setBusy(false));
          }}
        />
      ) : null}
    </section>
  );
}
