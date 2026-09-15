import { Calendar, X } from 'lucide-react';

interface QuickBookingBarProps {
  workerName: string;
  profession: string;
  pricePerHour: number;
  onContinue: () => void;
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
          <select className="quick-booking-select" defaultValue="slot1" aria-label="Fecha y hora">
            <option value="slot1">{dateLabel} | 10:00 AM</option>
            <option value="slot2">{dateLabel} | 14:00 PM</option>
            <option value="slot3">{dateLabel} | 18:00 PM</option>
          </select>
        </div>

        <div className="quick-booking-worker">
          <strong>{workerName}</strong>
          <span>{profession}</span>
          <span className="quick-booking-price">${pricePerHour.toLocaleString('es-CL')} / hora</span>
        </div>

        <button type="button" className="btn-primary quick-booking-cta" onClick={onContinue}>
          Continuar con la reserva →
        </button>
      </div>
    </div>
  );
}
