import { useEffect, useId, useRef, type ReactNode } from 'react';
import { statusLabel } from '../lib/format';

export function Button({
  children,
  variant = 'primary',
  type = 'button',
  busy = false,
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'secondary' | 'ghost' | 'danger';
  busy?: boolean;
}) {
  const className = ['btn', variant === 'primary' ? '' : `btn-${variant}`, props.className]
    .filter(Boolean)
    .join(' ');
  return (
    <button {...props} className={className} type={type} disabled={props.disabled || busy} aria-busy={busy}>
      {busy ? 'Trabajando…' : children}
    </button>
  );
}

export function IconButton({ label, children, ...props }: React.ButtonHTMLAttributes<HTMLButtonElement> & { label: string }) {
  return (
    <button {...props} type={props.type ?? 'button'} className={`icon-btn ${props.className ?? ''}`} aria-label={label}>
      {children}
    </button>
  );
}

export function Badge({ value }: { value: string | null | undefined }) {
  const label = statusLabel(value);
  const tone = value === 'liberado' || value === 'verificado' || value === 'activo' || value === 'resuelta'
    ? 'badge-ok'
    : value === 'rechazado' || value === 'fallido' || value === 'suspendido'
      ? 'badge-bad'
      : value === 'retenido' || value === 'en_revision' || value === 'requiere_humano'
        ? 'badge-warn'
        : '';
  return <span className={`badge ${tone}`}>{label}</span>;
}

export function EmptyState({ title, detail }: { title: string; detail?: string }) {
  return (
    <div className="empty">
      <strong>{title}</strong>
      {detail ? <p className="muted">{detail}</p> : null}
    </div>
  );
}

export function SkeletonRows() {
  return (
    <div className="stack" aria-hidden>
      <div className="skeleton" />
      <div className="skeleton" />
      <div className="skeleton" />
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="error-box">
      <p>{message}</p>
      <Button variant="secondary" onClick={onRetry}>Reintentar</Button>
    </div>
  );
}

export function Dialog({
  title,
  children,
  onClose,
}: {
  title: string;
  children: ReactNode;
  onClose: () => void;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const titleId = useId();
  useEffect(() => {
    const node = ref.current;
    const previous = document.activeElement as HTMLElement | null;
    const focusable = node?.querySelectorAll<HTMLElement>('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
    focusable?.[0]?.focus();
    const onKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
      if (event.key !== 'Tab' || !focusable?.length) return;
      const list = [...focusable];
      const first = list[0];
      const last = list[list.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('keydown', onKey);
      previous?.focus();
    };
  }, [onClose]);
  return (
    <div className="dialog-backdrop" onMouseDown={onClose}>
      <div
        className="dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        ref={ref}
        onMouseDown={(event) => event.stopPropagation()}
      >
        <h2 id={titleId}>{title}</h2>
        {children}
      </div>
    </div>
  );
}

export function CopyId({ value }: { value: string }) {
  return (
    <button
      type="button"
      className="btn btn-ghost"
      onClick={() => void navigator.clipboard.writeText(value)}
    >
      {value.slice(0, 8)} · copiar
    </button>
  );
}
