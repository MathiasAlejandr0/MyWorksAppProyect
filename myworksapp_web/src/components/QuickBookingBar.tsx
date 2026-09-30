import { useState } from 'react';
import { visitSlotIso } from '@myworksapp/shared';
import { Calendar, X } from 'lucide-react';

interface QuickBookingBarProps {
  workerName: string;
  profession: string;
  pricePerHour: number;
  onContinue: (scheduledAt: string) => void;
  onClose: () => void;
}

export function QuickBookingBar({
  workerName,
  profession,
  pricePerHour,
  onContinue,
  onClose,
}: QuickBookingBarProps) {
  const now = new Date();
  const friday = new Date(now);
  friday.setDate(now.getDate() + ((5 - now.getDay() + 7) % 7 || 7));

  const dateLabel = friday.toLocaleDateString('es-CL', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  });
  const [hour, setHour] = useState<'10' | '14' | '18'>('10');

  return (
    <div className="quick-booking-bar modal-rise" role="region" aria-label="Reserva rápida">
      <button type="button" className="quick-booking-close" onClick={onClose} aria-label="Cerrar">
        <X size={18} />
      </button>

      <div className="quick-booking-inner">
        <div className="quick-booking-copy">
          <p className="quick-booking-kicker">RESERVA RÁPIDA</p>
          <h3>¿Cuándo necesitas el servicio?</h3>
          <p className="quick-booking-hint">Elige fecha y hora para continuar.</p>
        </div>

        <div className="quick-booking-datetime">
          <Calendar size={18} className="quick-booking-cal-icon" aria-hidden />
          <select
            className="quick-booking-select"
            value={hour}
            aria-label="Fecha y hora"
            onChange={(event) => setHour(event.target.value as '10' | '14' | '18')}
          >
            <option value="10">{dateLabel} | 10:00</option>
            <option value="14">{dateLabel} | 14:00</option>
            <option value="18">{dateLabel} | 18:00</option>
          </select>
        </div>

        <div className="quick-booking-worker">
          <strong>{workerName}</strong>
          <span>{profession}</span>
          <span className="quick-booking-price">${pricePerHour.toLocaleString('es-CL')} / visita</span>
        </div>

        <button
          type="button"
          className="btn-primary quick-booking-cta"
          onClick={() => onContinue(visitSlotIso(hour))}
        >
          Continuar con la reserva →
        </button>
      </div>
    </div>
  );
}
