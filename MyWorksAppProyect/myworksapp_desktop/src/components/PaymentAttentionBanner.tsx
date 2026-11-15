import { useQuery } from '@tanstack/react-query';
import { supabase } from '../supabaseClient';

export function PaymentAttentionBanner() {
  const query = useQuery({
    queryKey: ['pagos-por-confirmar'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('pagos')
        .select('id, id_trabajo, estado, monto')
        .in('estado', ['pagado_por_confirmar', 'reembolsado_auto'])
        .limit(20);
      if (error) throw error;
      return data ?? [];
    },
  });

  const rows = query.data ?? [];
  if (rows.length === 0) return null;

  return (
    <section className="executive-subtitle" role="status">
      <strong>Cobros que requieren atención</strong>
      <ul>
        {rows.map((row) => (
          <li key={row.id}>
            {row.estado} · trabajo {row.id_trabajo} · ${Number(row.monto).toLocaleString('es-CL')}
          </li>
        ))}
      </ul>
    </section>
  );
}
