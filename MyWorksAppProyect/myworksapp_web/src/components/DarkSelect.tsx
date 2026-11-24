import { useEffect, useId, useRef, useState } from 'react';
import { ChevronDown } from 'lucide-react';

export interface DarkSelectOption {
  value: string;
  label: string;
}

/**
 * Menú oscuro. El select nativo abre una lista clara del sistema y no se
 * puede pintar; este control usa los mismos colores del sitio.
 */
export function DarkSelect({
  id,
  label,
  value,
  options,
  onChange,
  block = false,
  align = 'start',
}: {
  id?: string;
  label: string;
  value: string;
  options: readonly DarkSelectOption[];
  onChange: (value: string) => void;
  block?: boolean;
  align?: 'start' | 'end';
}) {
  const [open, setOpen] = useState(false);
  const wrapRef = useRef<HTMLDivElement>(null);
  const listId = useId();
  const selected = options.find((option) => option.value === value);

  useEffect(() => {
    if (!open) return;
    const onPointerDown = (event: PointerEvent) => {
      const target = event.target;
      if (target instanceof Node && wrapRef.current?.contains(target)) return;
      setOpen(false);
    };
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') setOpen(false);
    };
    document.addEventListener('pointerdown', onPointerDown);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('pointerdown', onPointerDown);
      document.removeEventListener('keydown', onKey);
    };
  }, [open]);

  return (
    <div className={block ? 'dark-select is-block' : 'dark-select'} ref={wrapRef}>
      <button
        id={id}
        type="button"
        className="dark-select-trigger"
        aria-label={label}
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-controls={open ? listId : undefined}
        onClick={() => setOpen((current) => !current)}
      >
        <span>{selected?.label ?? 'Elige una opción'}</span>
        <ChevronDown size={16} aria-hidden />
      </button>
      {open ? (
        <ul
          id={listId}
          className={align === 'end' ? 'dark-select-menu align-end' : 'dark-select-menu'}
          role="listbox"
          aria-label={label}
        >
          {options.map((option) => (
            <li key={option.value} role="presentation">
              <button
                type="button"
                role="option"
                className="dark-select-option"
                aria-selected={option.value === value}
                onClick={() => {
                  onChange(option.value);
                  setOpen(false);
                }}
              >
                {option.label}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
