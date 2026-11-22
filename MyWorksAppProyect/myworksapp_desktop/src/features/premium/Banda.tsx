import { useQuery } from '@tanstack/react-query';
import { useSearchParams } from 'react-router';
import { formatClp } from '../../lib/format';
import { callRpc } from '../../lib/rpc';
import { ErrorState, SkeletonRows } from '../../ui/kit';
import { usePeriodo } from '../../shell/periodo';
import { Grafico } from './graficos';
import { capturaActiva } from './captura';
import { muestraAnalitica } from './muestras';
import { comoAnalitica, rango, variacion, type Analitica, type KpiAnalitico } from './modelo';

function textoValor(kpi: KpiAnalitico): string {
  if (kpi.valor == null) return 'Sin dato';
  if (kpi.unidad === 'clp') return formatClp(kpi.valor);
  if (kpi.unidad === 'porcentaje') return `${kpi.valor.toLocaleString('es-CL')} %`;
  if (kpi.unidad === 'estrellas') return kpi.valor.toLocaleString('es-CL', { maximumFractionDigits: 2 });
  if (kpi.unidad === 'horas') return `${kpi.valor.toLocaleString('es-CL')} h`;
  return kpi.valor.toLocaleString('es-CL');
}

function textoVariacion(actual: number | null, anterior: number | null): string {
  const delta = variacion(actual, anterior);
  if (delta == null) return 'Sin comparación';
  const signo = delta > 0 ? '+' : '';
  return `${signo}${delta.toLocaleString('es-CL', { maximumFractionDigits: 1 })} % vs período anterior`;
}

export function Banda({ seccion }: { seccion: string }) {
  const { dias } = usePeriodo();
  const [params, setParams] = useSearchParams();
  const filtro = params.get('filtro');
  const query = useQuery({
    queryKey: ['premium', seccion, dias],
    queryFn: async () => {
      if (capturaActiva()) return { actual: muestraAnalitica(seccion), anterior: muestraAnalitica(seccion, 0.8) };
      const fechas = rango(dias);
      const actual = comoAnalitica(await callRpc('consola_premium_kpis', {
        p_seccion: seccion,
        p_desde: fechas.desde,
        p_hasta: fechas.hasta,
      }));
      if (!actual) throw new Error('La analítica no tiene el formato esperado.');
      let anterior: Analitica | null = null;
      try {
        anterior = comoAnalitica(await callRpc('consola_premium_kpis', {
          p_seccion: seccion,
          p_desde: fechas.anteriorDesde,
          p_hasta: fechas.anteriorHasta,
        }));
      } catch {
        anterior = null;
      }
      return { actual, anterior };
    },
  });

  if (query.isLoading) return <SkeletonRows />;
  if (query.isError) {
    const message = query.error instanceof Error ? query.error.message : '';
    const falta = /function|schema cache|PGRST202|Could not find/i.test(message);
    return (
      <ErrorState
        message={falta
          ? 'Falta la función consola_premium_kpis en esta base. La migración está en el repositorio y todavía no se aplica aquí.'
          : 'No se pudo calcular los indicadores. Reintenta en un momento.'}
        onRetry={() => void query.refetch()}
      />
    );
  }

  const actual = query.data?.actual;
  const anterior = query.data?.anterior;
  if (!actual) return null;
  const previos = new Map((anterior?.kpis ?? []).map((kpi) => [kpi.id, kpi.valor]));

  return (
    <div className="stack">
      {actual.nota ? <p className="muted">{actual.nota}</p> : null}
      {actual.sin_movimiento ? (
        <p className="empty">En este período no hay movimiento. Amplía el rango o revisa si la operación todavía no parte.</p>
      ) : null}
      <div className="kpi-grid">
        {actual.kpis.map((kpi) => (
          <button
            key={kpi.id}
            type="button"
            className={`card kpi${filtro === kpi.filtro && kpi.filtro ? ' is-active' : ''}`}
            aria-pressed={filtro === kpi.filtro && Boolean(kpi.filtro)}
            onClick={() => {
              if (!kpi.filtro) return;
              const next = new URLSearchParams(params);
              next.set('filtro', kpi.filtro);
              setParams(next);
            }}
          >
            <span className="muted">{kpi.etiqueta}</span>
            <strong className="kpi-valor">{textoValor(kpi)}</strong>
            <span className={variacion(kpi.valor, previos.get(kpi.id) ?? null) != null && (variacion(kpi.valor, previos.get(kpi.id) ?? null) ?? 0) < 0 ? 'delta delta-down' : 'delta'}>
              {textoVariacion(kpi.valor, previos.get(kpi.id) ?? null)}
            </span>
            <span className="muted kpi-ayuda" title={kpi.ayuda}>¿Qué mide esto? {kpi.ayuda}</span>
          </button>
        ))}
      </div>
      <div className="chart-grid">
        {actual.series.slice(0, 3).map((serie) => <Grafico key={serie.id} serie={serie} />)}
      </div>
      {actual.desgloses.map((desglose) => (
        <article key={desglose.id} className="card stack">
          <h3>{desglose.titulo}</h3>
          {desglose.filas.length === 0 ? <p className="muted">Sin desglose en este período.</p> : null}
          <div className="row">
            {desglose.filas.map((fila) => (
              <button
                key={fila.etiqueta}
                type="button"
                className="chip"
                onClick={() => {
                  if (!fila.filtro) return;
                  const next = new URLSearchParams(params);
                  next.set('filtro', fila.filtro);
                  setParams(next);
                }}
              >
                {fila.etiqueta} · {fila.valor.toLocaleString('es-CL')}
              </button>
            ))}
          </div>
        </article>
      ))}
      {actual.atencion.length > 0 ? (
        <article className="card stack">
          <h3>Necesita tu atención</h3>
          <ul className="timeline">
            {actual.atencion.map((item) => (
              <li key={item.ruta + item.etiqueta}>
                <a href={`${item.ruta}?dias=${dias}`}>{item.etiqueta}: {item.valor.toLocaleString('es-CL')}</a>
                <span className="muted"> {item.detalle}</span>
              </li>
            ))}
          </ul>
        </article>
      ) : null}
    </div>
  );
}
