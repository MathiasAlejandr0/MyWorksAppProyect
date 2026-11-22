import { Area, AreaChart, Bar, BarChart, CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import type { SerieAnalitica } from './modelo';

const COLORES = ['#2E90FA', '#12B76A', '#F79009', '#7A5AF8', '#EE46BC', '#667085'];

function filas(serie: SerieAnalitica): Array<Record<string, string | number>> {
  return serie.puntos.map((punto) => {
    const fila: Record<string, string | number> = { x: punto.x };
    for (const valor of punto.valores) fila[valor.nombre] = valor.valor;
    return fila;
  });
}

function nombres(serie: SerieAnalitica): string[] {
  const vistos: string[] = [];
  for (const punto of serie.puntos) {
    for (const valor of punto.valores) {
      if (!vistos.includes(valor.nombre)) vistos.push(valor.nombre);
    }
  }
  return vistos;
}

export function Grafico({ serie }: { serie: SerieAnalitica }) {
  const data = filas(serie);
  const series = nombres(serie);
  const comun = (
    <>
      <CartesianGrid stroke="var(--line)" vertical={false} />
      <XAxis dataKey="x" tick={{ fill: 'var(--text-muted)', fontSize: 12 }} interval="preserveStartEnd" />
      <YAxis tick={{ fill: 'var(--text-muted)', fontSize: 12 }} width={48} />
      <Tooltip contentStyle={{ background: 'var(--bg-surface)', border: '1px solid var(--line)', borderRadius: 8 }} />
    </>
  );
  return (
    <article className="card chart-card">
      <header>
        <h3>{serie.titulo}</h3>
        <p className="muted">{serie.ayuda}</p>
      </header>
      {data.length === 0 ? (
        <p className="muted">No hay puntos en este período. Prueba un rango más amplio.</p>
      ) : (
        <div className="chart-frame" role="img" aria-label={serie.titulo}>
          <ResponsiveContainer width="100%" height={240}>
            {serie.tipo === 'linea' ? (
              <LineChart data={data}>
                {comun}
                {series.map((nombre, index) => (
                  <Line key={nombre} type="monotone" dataKey={nombre} stroke={COLORES[index % COLORES.length]} strokeWidth={2} dot={false} />
                ))}
              </LineChart>
            ) : serie.tipo === 'area' ? (
              <AreaChart data={data}>
                {comun}
                {series.map((nombre, index) => (
                  <Area key={nombre} type="monotone" dataKey={nombre} stroke={COLORES[index % COLORES.length]} fill={COLORES[index % COLORES.length]} fillOpacity={0.2} />
                ))}
              </AreaChart>
            ) : (
              <BarChart data={data}>
                {comun}
                {series.map((nombre, index) => (
                  <Bar key={nombre} dataKey={nombre} fill={COLORES[index % COLORES.length]} radius={4} />
                ))}
              </BarChart>
            )}
          </ResponsiveContainer>
        </div>
      )}
      <table className="sr-only">
        <caption>{serie.titulo}</caption>
        <thead>
          <tr>
            <th>Período</th>
            {series.map((nombre) => <th key={nombre}>{nombre}</th>)}
          </tr>
        </thead>
        <tbody>
          {data.map((fila) => (
            <tr key={String(fila.x)}>
              <td>{fila.x}</td>
              {series.map((nombre) => <td key={nombre}>{fila[nombre] ?? 0}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </article>
  );
}
