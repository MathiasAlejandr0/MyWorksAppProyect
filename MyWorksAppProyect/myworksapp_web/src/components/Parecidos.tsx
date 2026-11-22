import { useEffect, useState } from 'react';
import { supabase } from '../supabaseClient';

interface Parecido {
  id: string;
  nombre: string;
  profesion: string;
  calificacion: string;
}

export function Parecidos({ workerId, fija }: { workerId: string | null; fija?: Parecido[] }) {
  const [filas, setFilas] = useState<Parecido[]>(fija ?? []);

  useEffect(() => {
    if (fija) {
      setFilas(fija);
      return;
    }
    if (!workerId) return;
    let cancelado = false;
    const cliente = supabase as unknown as {
      rpc: (nombre: string, args: Record<string, unknown>) => Promise<{ data: unknown }>;
    };
    void cliente.rpc('profesionales_parecidos', { p_id: workerId, p_limite: 3 }).then((respuesta) => {
      if (cancelado || !Array.isArray(respuesta.data)) return;
      setFilas(respuesta.data.map((row) => {
        const item = row as Record<string, unknown>;
        return {
          id: String(item.id_usuario),
          nombre: String(item.nombre ?? 'Profesional'),
          profesion: String(item.profesion ?? ''),
          calificacion: item.calificacion == null ? 'sin nota' : String(item.calificacion),
        };
      }));
    }).catch(() => {
      if (!cancelado) setFilas([]);
    });
    return () => {
      cancelado = true;
    };
  }, [workerId, fija]);

  if (filas.length === 0) return null;
  return (
    <aside className="parecidos" aria-label="Trabajadores parecidos">
      <h2>Trabajadores parecidos</h2>
      <ul>
        {filas.map((fila) => (
          <li key={fila.id}>{fila.nombre} · {fila.profesion} · {fila.calificacion}</li>
        ))}
      </ul>
    </aside>
  );
}
