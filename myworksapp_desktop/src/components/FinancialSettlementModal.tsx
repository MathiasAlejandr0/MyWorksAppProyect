import { useEffect, useState } from 'react';
import { DollarSign, CheckCircle2, X, Loader2, Landmark } from 'lucide-react';
import {
  getPayoutProviderStatus,
  listHeldPayments,
  releaseEscrowManual,
  type HeldPaymentRow,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

interface FinancialSettlementModalProps {
  onClose: () => void;
}

export function FinancialSettlementModal({ onClose }: FinancialSettlementModalProps) {
  const [held, setHeld] = useState<HeldPaymentRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [transferRef, setTransferRef] = useState('');
  const [notes, setNotes] = useState('');
  const [busy, setBusy] = useState(false);
  const [doneMsg, setDoneMsg] = useState<string | null>(null);

  const manual = getPayoutProviderStatus('manual');
  const khipu = getPayoutProviderStatus('khipu');
  const fintoc = getPayoutProviderStatus('fintoc');

  const refresh = async () => {
    setLoading(true);
    setError(null);
    try {
      const rows = await listHeldPayments(supabase);
      setHeld(rows);
      if (rows.length && !selectedId) setSelectedId(rows[0].id);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'No se pudieron cargar pagos retenidos');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void refresh();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const selected = held.find((h) => h.id === selectedId) ?? null;

  const handleRelease = async () => {
    if (!selected) return;
    if (transferRef.trim().length < 4) {
      setError('Ingresa la referencia de transferencia (mín. 4 caracteres).');
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const result = await releaseEscrowManual(supabase, {
        paymentId: selected.id,
        transferRef: transferRef.trim(),
        notes: notes.trim() || undefined,
        confirmExternal: true,
        provider: 'manual',
      });
      setDoneMsg(
        `Escrow liberado (${result.paymentId.slice(0, 8)}…). Liquidación ${result.liquidacionId?.slice(0, 8) ?? 'ok'} registrada.`,
      );
      setTransferRef('');
      setNotes('');
      await refresh();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'No se pudo liberar');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        backgroundColor: 'rgba(0,0,0,0.85)',
        backdropFilter: 'blur(12px)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 600,
        padding: '20px',
      }}
    >
      <div
        className="card-3d"
        style={{
          maxWidth: '640px',
          width: '100%',
          border: '2px solid #34C759',
          position: 'relative',
          maxHeight: '90vh',
          overflowY: 'auto',
        }}
      >
        <button
          type="button"
          onClick={onClose}
          style={{
            position: 'absolute',
            right: '16px',
            top: '16px',
            background: 'none',
            border: 'none',
            color: '#98989D',
            cursor: 'pointer',
          }}
          aria-label="Cerrar"
        >
          <X size={20} />
        </button>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            color: '#34C759',
            marginBottom: '10px',
          }}
        >
          <DollarSign size={24} />
          <h3 style={{ fontSize: '18px', fontWeight: 900 }}>Liquidación manual</h3>
        </div>

        <p style={{ fontSize: '13px', color: '#98989D', marginBottom: '14px' }}>
          {manual.message} Khipu: {khipu.ready ? 'listo' : 'pendiente'}. Fintoc:{' '}
          {fintoc.ready ? 'listo' : 'pendiente'}.
        </p>

        {doneMsg ? (
          <p
            style={{
              fontSize: '13px',
              color: '#34C759',
              marginBottom: '12px',
              display: 'flex',
              alignItems: 'center',
              gap: 8,
            }}
          >
            <CheckCircle2 size={16} /> {doneMsg}
          </p>
        ) : null}

        {error ? (
          <p style={{ fontSize: '13px', color: '#FF3B30', marginBottom: '12px' }} role="alert">
            {error}
          </p>
        ) : null}

        {loading ? (
          <div style={{ padding: 24, textAlign: 'center', color: '#98989D' }}>
            <Loader2 size={22} className="spin" /> Cargando pagos retenidos…
          </div>
        ) : held.length === 0 ? (
          <p style={{ fontSize: '14px', color: '#98989D', padding: '12px 0 20px' }}>
            No hay pagos en estado retenido/autorizado. Cuando un Webpay quede retenido,
            aparecerá aquí para liquidar.
          </p>
        ) : (
          <>
            <label style={{ display: 'block', fontSize: 12, color: '#98989D', marginBottom: 6 }}>
              Pago retenido
            </label>
            <select
              value={selectedId ?? ''}
              onChange={(e) => setSelectedId(e.target.value)}
              style={{
                width: '100%',
                marginBottom: 14,
                padding: '10px 12px',
                borderRadius: 8,
                border: '1px solid rgba(255,255,255,0.12)',
                background: 'rgba(255,255,255,0.04)',
                color: 'white',
              }}
            >
              {held.map((h) => (
                <option key={h.id} value={h.id}>
                  {h.amountClp.toLocaleString('es-CL')} CLP · trabajo {h.jobId.slice(0, 8)}… ·{' '}
                  {h.status}
                </option>
              ))}
            </select>

            {selected ? (
              <div
                style={{
                  backgroundColor: 'rgba(255,255,255,0.03)',
                  border: '1px solid rgba(255,255,255,0.08)',
                  borderRadius: 12,
                  padding: 14,
                  marginBottom: 14,
                  fontSize: 13.5,
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ color: '#98989D' }}>Monto a liquidar</span>
                  <strong style={{ color: '#34C759' }}>
                    ${selected.amountClp.toLocaleString('es-CL')} CLP
                  </strong>
                </div>
              </div>
            ) : null}

            <label style={{ display: 'block', fontSize: 12, color: '#98989D', marginBottom: 6 }}>
              <Landmark size={12} style={{ display: 'inline', marginRight: 4 }} />
              Referencia transferencia bancaria
            </label>
            <input
              value={transferRef}
              onChange={(e) => setTransferRef(e.target.value)}
              placeholder="Nº comprobante / ID transferencia"
              disabled={busy}
              style={{
                width: '100%',
                marginBottom: 12,
                padding: '10px 12px',
                borderRadius: 8,
                border: '1px solid rgba(255,255,255,0.12)',
                background: 'rgba(255,255,255,0.04)',
                color: 'white',
              }}
            />
            <label style={{ display: 'block', fontSize: 12, color: '#98989D', marginBottom: 6 }}>
              Notas (opcional)
            </label>
            <input
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Banco, titular, etc."
              disabled={busy}
              style={{
                width: '100%',
                marginBottom: 16,
                padding: '10px 12px',
                borderRadius: 8,
                border: '1px solid rgba(255,255,255,0.12)',
                background: 'rgba(255,255,255,0.04)',
                color: 'white',
              }}
            />

            <button
              type="button"
              className="btn-primary"
              disabled={busy || !selected}
              onClick={() => void handleRelease()}
              style={{ width: '100%', backgroundColor: '#34C759', padding: 12 }}
            >
              {busy ? (
                <>
                  <Loader2 size={16} /> Liberando…
                </>
              ) : (
                <>
                  <CheckCircle2 size={16} /> Confirmar transferencia y liberar escrow
                </>
              )}
            </button>
          </>
        )}
      </div>
    </div>
  );
}
