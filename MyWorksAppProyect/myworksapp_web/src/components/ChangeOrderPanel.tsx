import { useEffect, useState } from 'react';
import { chargeSavedCard, createWebpaySession, getSavedCard } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

type Order = {
  id: string;
  titulo: string;
  descripcion: string;
  monto_clp: number;
  estado: string;
};

type Loose = {
  from: (table: string) => {
    select: (columns: string) => {
      eq: (column: string, value: string) => Promise<{ data: Order[] | null; error: { message: string } | null }>;
    };
  };
  rpc: (fn: string, args?: Record<string, unknown>) => Promise<{ data: unknown; error: { message: string } | null }>;
};

export function ChangeOrderPanel({ jobId }: { jobId: string }) {
  const [orders, setOrders] = useState<Order[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const load = () => {
    const db = supabase as unknown as Loose;
    void db.from('ordenes_cambio').select('id, titulo, descripcion, monto_clp, estado').eq('id_trabajo', jobId)
      .then(({ data, error: readError }) => {
        if (readError) {
          setOrders([]);
          return;
        }
        setOrders((data ?? []).filter((order) => order.estado === 'pendiente_cliente'));
      });
  };

  useEffect(() => {
    const db = supabase as unknown as Loose;
    void db.from('ordenes_cambio').select('id, titulo, descripcion, monto_clp, estado').eq('id_trabajo', jobId)
      .then(({ data, error: readError }) => {
        if (readError) {
          setOrders([]);
          return;
        }
        setOrders((data ?? []).filter((order) => order.estado === 'pendiente_cliente'));
      });
  }, [jobId]);

  if (orders.length === 0 && !error) return null;

  const approve = async (order: Order) => {
    setBusy(true);
    setError(null);
    try {
      const db = supabase as unknown as Loose;
      const quote = await db.rpc('monto_a_cobrar_orden_cambio', { p_id: order.id });
      if (quote.error || typeof quote.data !== 'number') {
        setError('No pudimos calcular el cobro adicional.');
        return;
      }
      const card = await getSavedCard(supabase).catch(() => null);
      if (card?.enrolled) {
        await chargeSavedCard(supabase, {
          jobId,
          amountClp: quote.data,
          changeOrderId: order.id,
        });
        setError(null);
        load();
        return;
      }
      const session = await createWebpaySession(supabase, {
        jobId,
        amountClp: quote.data,
        changeOrderId: order.id,
        presentMode: 'redirect',
      });
      window.location.assign(session.redirectUrl);
    } catch {
      setError('No se pudo pagar el cobro adicional.');
    } finally {
      setBusy(false);
    }
  };

  const reject = async (order: Order) => {
    setBusy(true);
    setError(null);
    const db = supabase as unknown as Loose;
    const { error: rpcError } = await db.rpc('rechazar_orden_cambio', { p_id: order.id });
    setBusy(false);
    if (rpcError) {
      setError('No se pudo rechazar el cobro adicional.');
      return;
    }
    load();
  };

  return (
    <section className="tracking-escrow-card" aria-labelledby="cobro-extra-titulo">
      <div>
        <strong id="cobro-extra-titulo">Cobro adicional</strong>
        {orders.map((order) => (
          <div key={order.id}>
            <p>{order.titulo}</p>
            <p>{order.descripcion}</p>
            <p>Base ${Number(order.monto_clp).toLocaleString('es-CL')}. El total lo confirma el servidor al pagar.</p>
            <button type="button" disabled={busy} onClick={() => void approve(order)}>Aprobar y pagar</button>
            <button type="button" disabled={busy} onClick={() => void reject(order)}>Rechazar</button>
          </div>
        ))}
        {error ? <p role="alert">{error}</p> : null}
      </div>
    </section>
  );
}
