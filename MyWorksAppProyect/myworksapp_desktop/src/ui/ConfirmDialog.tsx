import { useEffect, useRef, useState } from 'react';
import { Button, Dialog } from './kit';

export function ConfirmDialog({
  title,
  summary,
  irreversible = false,
  requireTotp = false,
  busy = false,
  onCancel,
  onConfirm,
}: {
  title: string;
  summary: string;
  irreversible?: boolean;
  requireTotp?: boolean;
  busy?: boolean;
  onCancel: () => void;
  onConfirm: (motivo: string, code: string) => void;
}) {
  const [motivo, setMotivo] = useState('');
  const [code, setCode] = useState('');
  const locked = useRef(false);
  const ready = motivo.trim().length >= 10 && (!requireTotp || code.trim().length >= 6);
  useEffect(() => {
    if (!busy) locked.current = false;
  }, [busy]);
  return (
    <Dialog title={title} onClose={() => { if (!busy) onCancel(); }}>
      <p>{summary}</p>
      {irreversible ? <p className="muted">Esta acción no se deshace desde la consola.</p> : null}
      <label className="field">
        <span>Motivo (mínimo 10 caracteres)</span>
        <textarea value={motivo} onChange={(event) => setMotivo(event.target.value)} required disabled={busy} />
      </label>
      {requireTotp ? (
        <label className="field">
          <span>Código de la aplicación de autenticación</span>
          <input
            inputMode="numeric"
            autoComplete="one-time-code"
            value={code}
            disabled={busy}
            onChange={(event) => setCode(event.target.value)}
          />
        </label>
      ) : null}
      <div className="row">
        <Button variant="secondary" onClick={onCancel} disabled={busy}>Cancelar</Button>
        <Button
          variant="danger"
          busy={busy}
          disabled={!ready || busy}
          onClick={() => {
            if (busy || locked.current) return;
            locked.current = true;
            onConfirm(motivo.trim(), code.trim());
          }}
        >
          Confirmar
        </Button>
      </div>
    </Dialog>
  );
}
