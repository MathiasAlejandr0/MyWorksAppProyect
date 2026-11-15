import { useState, useEffect } from 'react';
import { Calendar, X } from 'lucide-react';

export interface BookingSlotOption {
  iso: string;
  label: string;
}

interface QuickBookingBarProps {
  workerName: string;
  profession: string;
  pricePerHour: number;
  transportExtraClp?: number;
  radarHint?: string;
  slots: BookingSlotOption[];
  loadingSlots?: boolean;
  onContinue: (scheduledAt: string) => void;
  onClose: () => void;
}

export function QuickBookingBar({
  workerName,
  profession,
  pricePerHour,
  transportExtraClp = 0,
  radarHint,
  slots,
  loadingSlots = false,
  onContinue,
  onClose,
}: QuickBookingBarProps) {
  const [selectedIso, setSelectedIso] = useState(slots[0]?.iso ?? '');

  useEffect(() => {
    if (slots.some((slot) => slot.iso === selectedIso)) return;
    setSelectedIso(slots[0]?.iso ?? '');
  }, [slots, selectedIso]);

  const hasSlots = slots.length > 0;
  const canContinue = hasSlots && Boolean(selectedIso) && !loadingSlots;

  return (
    <div className="quick-booking-bar modal-rise" role="region" aria-label="Reserva rápida">
      <button type="button" className="quick-booking-close" onClick={onClose} aria-label="Cerrar">
        <X size={18} />
      </button>

      <div className="quick-booking-inner">
        <div className="quick-booking-copy">
          <p className="quick-booking-kicker">RESERVA RÁPIDA</p>
          <h3>¿Cuándo necesitas el servicio?</h3>
          <p className="quick-booking-hint">
            {loadingSlots
              ? 'Cargando horarios del profesional…'
              : hasSlots
                ? 'Elige una hora publicada por el profesional. Cada bloque aparece una sola vez.'
                : 'Este profesional aún no publica horarios de atención.'}
          </p>
        </div>

        <div className="quick-booking-datetime">
          <Calendar size={18} className="quick-booking-cal-icon" aria-hidden />
          <select
            className="quick-booking-select"
            value={selectedIso}
            aria-label="Fecha y hora"
            disabled={!hasSlots || loadingSlots}
            onChange={(event) => setSelectedIso(event.target.value)}
          >
            {hasSlots ? (
              slots.map((slot) => (
                <option key={slot.iso} value={slot.iso}>
                  {slot.label}
                </option>
              ))
            ) : (
              <option value="">Sin horarios disponibles</option>
            )}
          </select>
        </div>

        <div className="quick-booking-worker">
          <strong>{workerName}</strong>
          <span>{profession}</span>
          <span className="quick-booking-price">
            ${pricePerHour.toLocaleString('es-CL')} / visita
            {transportExtraClp > 0
              ? ` + $${transportExtraClp.toLocaleString('es-CL')} traslado`
              : ''}
          </span>
          {radarHint ? <span className="quick-booking-radar">{radarHint}</span> : null}
        </div>

        <button
          type="button"
          className="btn-primary quick-booking-cta"
          disabled={!canContinue}
          onClick={() => {
            if (!canContinue) return;
            onContinue(selectedIso);
          }}
        >
          Continuar con la reserva →
        </button>
      </div>
    </div>
  );
}
