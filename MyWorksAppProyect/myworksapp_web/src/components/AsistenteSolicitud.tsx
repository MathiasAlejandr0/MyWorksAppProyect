import { useState } from 'react';
import { AVISO_SUGERENCIA, sugerenciaDesdeTexto, type SugerenciaSolicitud } from '@myworksapp/shared';
import { supabase } from '../supabaseClient';

export function AsistenteSolicitud({ texto, fija }: { texto: string; fija?: SugerenciaSolicitud | null }) {
  const [sugerencia, setSugerencia] = useState<SugerenciaSolicitud | null>(fija ?? null);
  const [aviso, setAviso] = useState(fija ? AVISO_SUGERENCIA : '');
  const [error, setError] = useState('');

  const pedir = async () => {
    setError('');
    if (fija) {
      setSugerencia(fija);
      setAviso(AVISO_SUGERENCIA);
      return;
    }
    const { data, error: fallo } = await supabase.functions.invoke('asistente-solicitud', {
      body: { modo: 'solicitud', texto },
    });
    if (fallo || !data || data.error) {
      const local = sugerenciaDesdeTexto(texto);
      setSugerencia(local);
      setAviso('Sugerencia local de la IA, sin salir de este navegador. Tú confirmas el pedido.');
      setError(data?.error ? String(data.error) : '');
      return;
    }
    setSugerencia(data as SugerenciaSolicitud);
    setAviso(String(data.aviso ?? AVISO_SUGERENCIA));
  };

  return (
    <section className="asistente-ia" aria-label="Asistente de la solicitud">
      <button type="button" className="btn-outline-orange" onClick={() => void pedir()}>
        Sugerir con IA
      </button>
      {sugerencia ? (
        <div className="asistente-ia-card" role="status">
          <strong>Sugerencia de la IA</strong>
          <p>{aviso}</p>
          <p>Categoría: {sugerencia.categoria}. Urgencia: {sugerencia.urgencia}.</p>
          <p>Rango orientativo: ${sugerencia.precio_min_clp.toLocaleString('es-CL')} a ${sugerencia.precio_max_clp.toLocaleString('es-CL')}.</p>
          {sugerencia.preguntas.length > 0 ? (
            <ul>{sugerencia.preguntas.map((pregunta) => <li key={pregunta}>{pregunta}</li>)}</ul>
          ) : null}
          {error ? <p>{error}</p> : null}
        </div>
      ) : null}
    </section>
  );
}
