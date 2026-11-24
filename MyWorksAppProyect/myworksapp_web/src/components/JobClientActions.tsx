import { useEffect, useMemo, useState } from 'react';
import { CalendarClock, Star, XCircle } from 'lucide-react';
import {
  canClientCancel,
  canClientRate,
  canProposeReschedule,
  canRespondReschedule,
  cancelJobAsClient,
  fetchClientRatingForJob,
  fetchRescheduleHistory,
  fetchWorkerFreeSlots,
  formatBookingSlotLabel,
  proposeReschedule,
  rateJobAsClient,
  rescheduleSlotOptions,
  rescheduleStatusLabel,
  respondReschedule,
  withdrawReschedule,
  type RescheduleProposal,
} from '@myworksapp/shared';
import { DarkSelect } from './DarkSelect';
import { supabase } from '../supabaseClient';

interface JobClientActionsProps {
  jobId: string;
  status: string | null | undefined;
  scheduledAt: string | null | undefined;
  workerId: string | null | undefined;
  workerName: string;
  userId: string;
  /** Disputa abierta, si la hay. Sin ella no se ofrece cancelar un trabajo en marcha. */
  disputeOpen?: boolean;
  disputeOpenedBy?: string | null;
  /** Recarga el pedido tras cancelar o reagendar. */
  onChanged: () => void;
}

/**
 * Cancelar, reagendar y calificar desde el seguimiento web. Las reglas viven
 * en la base (transicionar_trabajo, proponer/responder_reprogramacion, RLS
 * de calificaciones); aquí solo se ofrecen cuando aplican.
 */
export function JobClientActions({
  jobId,
  status,
  scheduledAt,
  workerId,
  workerName,
  userId,
  disputeOpen = false,
  disputeOpenedBy = null,
  onChanged,
}: JobClientActionsProps) {
  const [history, setHistory] = useState<RescheduleProposal[]>([]);
  const [slots, setSlots] = useState<string[]>([]);
  const [slot, setSlot] = useState('');
  const [reason, setReason] = useState('');
  const [cancelReason, setCancelReason] = useState('');
  const [confirmCancel, setConfirmCancel] = useState(false);
  const [rating, setRating] = useState<{ score: number; comment: string | null } | null>(null);
  const [ratingLoaded, setRatingLoaded] = useState(false);
  const [ratingError, setRatingError] = useState(false);
  const [ratingTry, setRatingTry] = useState(0);
  const [score, setScore] = useState(0);
  const [comment, setComment] = useState('');
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<{ kind: 'ok' | 'error'; text: string } | null>(null);

  const reschedulable = canProposeReschedule({
    status: status ?? '',
    scheduledAt: scheduledAt ?? null,
    workerId: workerId ?? null,
  });
  const pending = history.find((item) => item.status === 'pendiente') ?? null;
  const mustRespond = canRespondReschedule(pending, userId);
  const options = useMemo(
    () => (reschedulable ? rescheduleSlotOptions(slots, scheduledAt ?? null) : []),
    [reschedulable, slots, scheduledAt],
  );

  useEffect(() => {
    let cancelled = false;
    void fetchRescheduleHistory(supabase, jobId)
      .then((rows) => {
        if (!cancelled) setHistory(rows);
      })
      .catch(() => {
        if (!cancelled) setHistory([]);
      });
    return () => {
      cancelled = true;
    };
  }, [jobId, scheduledAt, status]);

  useEffect(() => {
    if (!reschedulable || !workerId) return;
    let cancelled = false;
    void fetchWorkerFreeSlots(supabase, workerId, 21)
      .then((rows) => {
        if (!cancelled) setSlots(rows);
      })
      .catch(() => {
        if (!cancelled) setSlots([]);
      });
    return () => {
      cancelled = true;
    };
  }, [reschedulable, workerId, scheduledAt]);

  useEffect(() => {
    if (status !== 'completado') return;
    let cancelled = false;
    void fetchClientRatingForJob(supabase, jobId, userId).then((row) => {
      if (cancelled) return;
      setRatingError(false);
      if (cancelled) return;
      setRating(row);
      setRatingLoaded(true);
    }).catch(() => {
      if (cancelled) return;
      setRating(null);
      setRatingLoaded(true);
      setRatingError(true);
    });
    return () => {
      cancelled = true;
    };
  }, [jobId, userId, status, ratingTry]);

  const run = async (task: () => Promise<string>) => {
    setBusy(true);
    setNote(null);
    try {
      const text = await task();
      setNote({ kind: 'ok', text });
      setHistory(await fetchRescheduleHistory(supabase, jobId).catch(() => history));
      onChanged();
    } catch (error) {
      setNote({ kind: 'error', text: error instanceof Error ? error.message : 'No se pudo completar la acción.' });
    } finally {
      setBusy(false);
    }
  };

  const showCancel = canClientCancel(status, {
    disputeOpen,
    disputeOpenedBy,
    userId,
  });
  const showRate = ratingLoaded && canClientRate(status, rating !== null);
  const showReschedule = reschedulable || history.length > 0;

  if (!showCancel && !showReschedule && !(status === 'completado' && ratingLoaded)) {
    return note ? <p className="tracking-status-detail" role="status">{note.text}</p> : null;
  }

  return (
    <div className="job-client-actions">
      {showReschedule ? (
        <section className="tracking-escrow-card" aria-labelledby="reagendar-titulo">
          <CalendarClock size={22} className="tracking-escrow-icon" aria-hidden />
          <div>
            <strong id="reagendar-titulo">{reschedulable || pending ? 'Cambiar la hora' : 'Cambios de hora'}</strong>
            {scheduledAt && (reschedulable || pending) ? (
              <p>Hora actual: {formatBookingSlotLabel(scheduledAt)}.</p>
            ) : null}
            {pending ? (
              <div className="reschedule-pending">
                <p>
                  {pending.proposedBy === userId ? 'Propusiste' : `${workerName} propone`} mover la visita al{' '}
                  <strong>{formatBookingSlotLabel(pending.proposedAt)}</strong>.
                  {pending.reason ? ` Motivo: ${pending.reason}.` : ''}
                </p>
                {mustRespond ? (
                  <div className="reschedule-actions">
                    <button
                      type="button"
                      className="btn-primary"
                      disabled={busy}
                      onClick={() => void run(async () => {
                        const row = await respondReschedule(supabase, pending.id, true);
                        return row.status === 'aceptada'
                          ? 'Listo: la visita quedó en la nueva hora.'
                          : 'La propuesta venció porque el trabajo cambió.';
                      })}
                    >
                      Aceptar nueva hora
                    </button>
                    <button
                      type="button"
                      className="btn-ghost"
                      disabled={busy}
                      onClick={() => void run(async () => {
                        await respondReschedule(supabase, pending.id, false);
                        return 'Rechazaste el cambio. Se mantiene la hora original.';
                      })}
                    >
                      Rechazar
                    </button>
                  </div>
                ) : (
                  <button
                    type="button"
                    className="btn-ghost"
                    disabled={busy}
                    onClick={() => void run(async () => {
                      await withdrawReschedule(supabase, pending.id);
                      return 'Retiraste tu propuesta.';
                    })}
                  >
                    Retirar mi propuesta
                  </button>
                )}
              </div>
            ) : reschedulable ? (
              <form
                onSubmit={(event) => {
                  event.preventDefault();
                  if (!slot) return;
                  void run(async () => {
                    await proposeReschedule(supabase, jobId, slot, reason);
                    setSlot('');
                    setReason('');
                    return `Propuesta enviada. ${workerName} debe aceptarla; el pago sigue retenido.`;
                  });
                }}
              >
                <p>Elige otra hora publicada por {workerName}. La otra parte debe aceptarla y el pago retenido no cambia.</p>
                {options.length === 0 ? (
                  <p>No hay otras horas libres en las próximas tres semanas.</p>
                ) : (
                  <>
                    <label htmlFor="reagendar-hora">Nueva hora</label>
                    <DarkSelect
                      id="reagendar-hora"
                      block
                      label="Nueva hora"
                      value={slot}
                      onChange={setSlot}
                      options={[
                        { value: '', label: 'Elige una hora' },
                        ...options.map((iso) => ({ value: iso, label: formatBookingSlotLabel(iso) })),
                      ]}
                    />
                    <label htmlFor="reagendar-motivo">Motivo (opcional)</label>
                    <input
                      id="reagendar-motivo"
                      value={reason}
                      maxLength={300}
                      onChange={(event) => setReason(event.target.value)}
                    />
                    <button type="submit" className="btn-primary" disabled={busy || !slot}>
                      {busy ? 'Enviando…' : 'Proponer nueva hora'}
                    </button>
                  </>
                )}
              </form>
            ) : null}
            {history.filter((item) => item.status !== 'pendiente').length > 0 ? (
              <details className="reschedule-history">
                <summary>Historial de cambios de hora</summary>
                <ul>
                  {history
                    .filter((item) => item.status !== 'pendiente')
                    .map((item) => (
                      <li key={item.id}>
                        {formatBookingSlotLabel(item.previousAt)} → {formatBookingSlotLabel(item.proposedAt)} ·{' '}
                        {item.proposerRole === 'cliente' ? 'propuesta tuya' : 'propuesta del profesional'} ·{' '}
                        {rescheduleStatusLabel(item.status)}
                      </li>
                    ))}
                </ul>
              </details>
            ) : null}
          </div>
        </section>
      ) : null}

      {showCancel ? (
        <section className="tracking-escrow-card" aria-labelledby="cancelar-titulo">
          <XCircle size={22} className="tracking-escrow-icon" aria-hidden />
          <div>
            <strong id="cancelar-titulo">Cancelar la solicitud</strong>
            <p>
              {disputeOpen && disputeOpenedBy === userId
                ? 'Abriste esta disputa. Cancelar devuelve a tu tarjeta el pago principal, la orden de cambio y las horas extra, y cierra la disputa.'
                : status === 'esperando_aprobacion_cliente'
                  ? 'Si no estás conforme, puedes cancelar. Se devuelven a tu tarjeta todos los cobros que sigan retenidos.'
                  : 'Puedes cancelar mientras el profesional no la acepte. Si ya pagaste, los cobros retenidos se devuelven a tu tarjeta antes de cancelar.'}
            </p>
            {confirmCancel ? (
              <form
                onSubmit={(event) => {
                  event.preventDefault();
                  void run(async () => {
                    await cancelJobAsClient(supabase, {
                      jobId,
                      userId,
                      workerId: workerId ?? null,
                      reason: cancelReason,
                    });
                    setConfirmCancel(false);
                    return 'Solicitud cancelada. Si había un cobro retenido, se devolvió a tu tarjeta.';
                  });
                }}
              >
                <label htmlFor="cancelar-motivo">¿Por qué cancelas?</label>
                <input
                  id="cancelar-motivo"
                  value={cancelReason}
                  maxLength={500}
                  required
                  onChange={(event) => setCancelReason(event.target.value)}
                />
                <div className="reschedule-actions">
                  <button type="submit" className="btn-danger" disabled={busy || !cancelReason.trim()}>
                    {busy ? 'Cancelando…' : 'Sí, cancelar'}
                  </button>
                  <button type="button" className="btn-ghost" onClick={() => setConfirmCancel(false)}>
                    No, volver
                  </button>
                </div>
              </form>
            ) : (
              <button type="button" className="btn-ghost" onClick={() => setConfirmCancel(true)}>
                Cancelar solicitud
              </button>
            )}
          </div>
        </section>
      ) : null}

      {status === 'completado' && ratingLoaded ? (
        <section className="tracking-escrow-card" aria-labelledby="calificar-titulo">
          <Star size={22} className="tracking-escrow-icon" aria-hidden />
          <div>
            <strong id="calificar-titulo">Califica a {workerName}</strong>
            {ratingError ? (
              <p role="alert">
                No se pudo cargar la valoración.
                <button type="button" onClick={() => setRatingTry((n) => n + 1)}>Reintentar</button>
              </p>
            ) : null}
            {rating ? (
              <p>
                Calificaste este trabajo con {rating.score} {rating.score === 1 ? 'estrella' : 'estrellas'}.
                {rating.comment ? ` «${rating.comment}»` : ''}
              </p>
            ) : showRate ? (
              <form
                onSubmit={(event) => {
                  event.preventDefault();
                  void run(async () => {
                    await rateJobAsClient(supabase, {
                      jobId,
                      userId,
                      workerId: workerId ?? '',
                      score,
                      comment,
                    });
                    setRating({ score, comment: comment.trim() || null });
                    return '¡Gracias! Tu calificación quedó registrada.';
                  });
                }}
              >
                <div className="rating-stars" role="radiogroup" aria-label="Puntaje">
                  {[1, 2, 3, 4, 5].map((value) => (
                    <button
                      key={value}
                      type="button"
                      role="radio"
                      aria-checked={score === value}
                      aria-label={`${value} ${value === 1 ? 'estrella' : 'estrellas'}`}
                      className={value <= score ? 'rating-star active' : 'rating-star'}
                      onClick={() => setScore(value)}
                    >
                      ★
                    </button>
                  ))}
                </div>
                <label htmlFor="calificar-comentario">Comentario (opcional)</label>
                <textarea
                  id="calificar-comentario"
                  rows={3}
                  maxLength={500}
                  value={comment}
                  onChange={(event) => setComment(event.target.value)}
                />
                <button type="submit" className="btn-primary" disabled={busy || score === 0}>
                  {busy ? 'Enviando…' : 'Enviar calificación'}
                </button>
              </form>
            ) : null}
          </div>
        </section>
      ) : null}

      {note ? (
        <p className={note.kind === 'error' ? 'tracking-status-detail tracking-error' : 'tracking-status-detail'} role={note.kind === 'error' ? 'alert' : 'status'}>
          {note.text}
        </p>
      ) : null}
    </div>
  );
}
