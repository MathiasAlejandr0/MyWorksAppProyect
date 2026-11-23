import { useEffect, useId, useRef, useState, type KeyboardEvent as ReactKeyboardEvent } from 'react';
import { Calendar, ChevronDown, X } from 'lucide-react';

export interface BookingSlotOption {
  iso: string;
  label: string;
}

interface QuickBookingBarProps {
  workerName: string;
  profession: string;
  pricePerHour: number;
  radarHint?: string;
  slots: BookingSlotOption[];
  loadingSlots?: boolean;
  onContinue: (scheduledAt: string) => void;
  onClose: () => void;
}

function scrollOptionIntoView(list: HTMLElement | null, option: HTMLElement | null) {
  if (!list || !option) return;
  const top = option.offsetTop;
  const bottom = top + option.offsetHeight;
  if (top < list.scrollTop) {
    list.scrollTop = top;
  } else if (bottom > list.scrollTop + list.clientHeight) {
    list.scrollTop = bottom - list.clientHeight;
  }
}

function slotListKey(slots: BookingSlotOption[]): string {
  return slots.map((slot) => slot.iso).join('|');
}

export function QuickBookingBar({
  workerName,
  profession,
  pricePerHour,
  radarHint,
  slots,
  loadingSlots = false,
  onContinue,
  onClose,
}: QuickBookingBarProps) {
  const [selectedIso, setSelectedIso] = useState(slots[0]?.iso ?? '');
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const [trackedSlotKey, setTrackedSlotKey] = useState(() => slotListKey(slots));
  const wrapRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const listRef = useRef<HTMLUListElement>(null);
  const listId = useId();

  const slotKey = slotListKey(slots);
  if (slotKey !== trackedSlotKey) {
    setTrackedSlotKey(slotKey);
    setOpen(false);
  }

  const hasSlots = slots.length > 0;
  const selectedStillThere = slots.some((slot) => slot.iso === selectedIso);
  const effectiveIso = selectedStillThere ? selectedIso : (slots[0]?.iso ?? '');
  const canContinue = hasSlots && Boolean(effectiveIso) && !loadingSlots;
  const pickerDisabled = !hasSlots || loadingSlots;
  const menuOpen = open && hasSlots && !loadingSlots;
  const selectedLabel =
    slots.find((slot) => slot.iso === effectiveIso)?.label
    ?? (loadingSlots ? 'Cargando horarios…' : 'Sin horarios disponibles');

  useEffect(() => {
    if (!menuOpen) return;
    const frame = window.requestAnimationFrame(() => {
      const option = listRef.current?.querySelector<HTMLButtonElement>(
        `[data-index="${activeIndex}"]`,
      );
      option?.focus({ preventScroll: true });
      scrollOptionIntoView(listRef.current, option ?? null);
    });
    const onPointerDown = (event: PointerEvent) => {
      const target = event.target;
      if (!(target instanceof Node)) return;
      if (!wrapRef.current?.contains(target)) setOpen(false);
    };
    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key !== 'Escape') return;
      event.preventDefault();
      setOpen(false);
      triggerRef.current?.focus();
    };
    document.addEventListener('pointerdown', onPointerDown);
    document.addEventListener('keydown', onKeyDown);
    return () => {
      window.cancelAnimationFrame(frame);
      document.removeEventListener('pointerdown', onPointerDown);
      document.removeEventListener('keydown', onKeyDown);
    };
  }, [menuOpen, activeIndex]);

  function choose(iso: string) {
    setSelectedIso(iso);
    setOpen(false);
    triggerRef.current?.focus();
  }

  function openMenu() {
    const index = Math.max(0, slots.findIndex((slot) => slot.iso === effectiveIso));
    setActiveIndex(index);
    setOpen(true);
  }

  function focusIndex(index: number) {
    const next = Math.max(0, Math.min(slots.length - 1, index));
    setActiveIndex(next);
  }

  function onPickerKeyDown(event: ReactKeyboardEvent) {
    if (pickerDisabled) return;
    if (!menuOpen) {
      if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
        event.preventDefault();
        openMenu();
      }
      return;
    }
    if (event.key === 'Escape') {
      event.preventDefault();
      event.stopPropagation();
      setOpen(false);
      triggerRef.current?.focus();
      return;
    }
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      focusIndex(activeIndex + 1);
      return;
    }
    if (event.key === 'ArrowUp') {
      event.preventDefault();
      focusIndex(activeIndex - 1);
      return;
    }
    if (event.key === 'Home') {
      event.preventDefault();
      focusIndex(0);
      return;
    }
    if (event.key === 'End') {
      event.preventDefault();
      focusIndex(slots.length - 1);
      return;
    }
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      const slot = slots[activeIndex];
      if (slot) choose(slot.iso);
    }
  }

  return (
    <div className="quick-booking-bar modal-rise" role="region" aria-label="Reserva rápida">
      <button type="button" className="quick-booking-close" onClick={onClose} aria-label="Cerrar">
        <X size={18} />
      </button>

      <div className="quick-booking-inner">
        <div className="quick-booking-copy">
          <p className="quick-booking-kicker">RESERVA RÁPIDA</p>
          <h2>¿Cuándo necesitas el servicio?</h2>
          <p className="quick-booking-hint">
            {loadingSlots
              ? 'Cargando horarios del profesional…'
              : hasSlots
                ? 'Elige una hora publicada por el profesional. Cada bloque aparece una sola vez.'
                : 'Este profesional aún no publica horarios de atención.'}
          </p>
        </div>

        <div className="quick-booking-datetime" ref={wrapRef}>
          <Calendar size={18} className="quick-booking-cal-icon" aria-hidden />
          <button
            ref={triggerRef}
            type="button"
            className="quick-booking-select"
            aria-label="Fecha y hora"
            aria-haspopup="listbox"
            aria-expanded={menuOpen}
            aria-controls={menuOpen ? listId : undefined}
            disabled={pickerDisabled}
            onClick={() => {
              if (pickerDisabled) return;
              if (menuOpen) setOpen(false);
              else openMenu();
            }}
            onKeyDown={onPickerKeyDown}
          >
            <span className="quick-booking-select-label">{selectedLabel}</span>
            <ChevronDown size={16} className="quick-booking-chevron" aria-hidden />
          </button>
          {menuOpen ? (
            <ul
              id={listId}
              ref={listRef}
              className="quick-booking-menu"
              role="listbox"
              aria-label="Horas publicadas por el profesional"
              onKeyDown={onPickerKeyDown}
            >
              {slots.map((slot, index) => (
                <li key={slot.iso} role="presentation">
                  <button
                    type="button"
                    role="option"
                    data-index={index}
                    className={
                      index === activeIndex
                        ? 'quick-booking-option is-active'
                        : 'quick-booking-option'
                    }
                    aria-selected={slot.iso === effectiveIso}
                    tabIndex={index === activeIndex ? 0 : -1}
                    onMouseEnter={() => setActiveIndex(index)}
                    onClick={() => choose(slot.iso)}
                  >
                    {slot.label}
                  </button>
                </li>
              ))}
            </ul>
          ) : null}
        </div>

        <div className="quick-booking-worker">
          <strong>{workerName}</strong>
          <span>{profession}</span>
          <span className="quick-booking-price">
            ${pricePerHour.toLocaleString('es-CL')} / visita
          </span>
          {radarHint ? <span className="quick-booking-radar">{radarHint}</span> : null}
        </div>

        <button
          type="button"
          className="btn-primary quick-booking-cta"
          disabled={!canContinue}
          onClick={() => {
            if (!canContinue) return;
            onContinue(effectiveIso);
          }}
        >
          Continuar con la reserva →
        </button>
      </div>
    </div>
  );
}
