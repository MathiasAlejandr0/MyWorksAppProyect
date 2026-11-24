import { useEffect, useState, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { collectPages, PAGE_SIZE } from '../lib/lists';
import { EmptyState, ErrorState, SkeletonRows } from '../ui/kit';
import { toCsv, downloadCsv } from '../lib/csv';
import { capturaActiva } from './premium/captura';
import { filasCaptura } from './premium/muestras';

export interface PageResult<T> {
  rows: T[];
  total: number;
}

export function PagedTable<T extends { id: string }>({
  queryKey,
  load,
  columns,
  empty,
  onRow,
  toolbar,
}: {
  queryKey: readonly unknown[];
  load: (page: number, search: string) => Promise<PageResult<T>>;
  columns: { key: string; header: string; cell: (row: T) => ReactNode; csv?: (row: T) => unknown }[];
  empty: string;
  onRow?: (row: T) => void;
  toolbar?: ReactNode;
}) {
  const [page, setPage] = useState(0);
  const [search, setSearch] = useState('');
  const [debounced, setDebounced] = useState('');
  const [exporting, setExporting] = useState(false);
  const [exportError, setExportError] = useState<string | null>(null);
  const pageSize = PAGE_SIZE;
  useEffect(() => {
    const timer = window.setTimeout(() => setDebounced(search.trim()), 300);
    return () => window.clearTimeout(timer);
  }, [search]);
  const query = useQuery({
    queryKey: [...queryKey, page, debounced],
    queryFn: () => {
      if (capturaActiva()) {
        const rows = filasCaptura(String(queryKey[0])).filter((row) => {
          if (!debounced) return true;
          return JSON.stringify(row).toLowerCase().includes(debounced.toLowerCase());
        }) as T[];
        return { rows: rows.slice(page * pageSize, page * pageSize + pageSize), total: rows.length };
      }
      return load(page, debounced);
    },
  });
  const rows = query.data?.rows ?? [];
  const total = query.data?.total ?? 0;
  const pages = Math.max(1, Math.ceil(total / pageSize));
  return (
    <section className="stack">
      <div className="spread">
        <label className="field">
          <span>Buscar</span>
          <input aria-label="Buscar en la tabla" value={search} onChange={(event) => { setSearch(event.target.value); setPage(0); }} />
        </label>
        <div className="row">
          {toolbar}
          <button
            type="button"
            className="btn btn-secondary"
            disabled={exporting}
            onClick={() => {
              setExporting(true);
              setExportError(null);
              void collectPages((nextPage) => load(nextPage, debounced), pageSize)
                .then((all) => {
                  const csv = toCsv(
                    columns.map((column) => column.header),
                    all.map((row) => columns.map((column) => column.csv ? column.csv(row) : '')),
                  );
                  downloadCsv('myworksapp.csv', csv);
                })
                .catch(() => setExportError('No se pudo exportar. Revisa la conexión e inténtalo de nuevo.'))
                .finally(() => setExporting(false));
            }}
          >
            {exporting ? 'Exportando…' : 'Exportar CSV'}
          </button>
        </div>
      </div>
      {exportError ? <p role="alert">{exportError}</p> : null}
      {query.isLoading ? <SkeletonRows /> : null}
      {query.isError ? (
        <ErrorState message="No se pudo cargar esta lista." onRetry={() => void query.refetch()} />
      ) : null}
      {!query.isLoading && !query.isError && rows.length === 0 ? <EmptyState title={empty} /> : null}
      {rows.length > 0 ? (
        <div className="table-wrap panel">
          <table className="data">
            <thead>
              <tr>{columns.map((column) => <th key={column.key}>{column.header}</th>)}</tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr
                  key={row.id}
                  className={onRow ? 'clickable' : undefined}
                  tabIndex={onRow ? 0 : undefined}
                  onClick={() => onRow?.(row)}
                  onKeyDown={(event) => {
                    if (!onRow) return;
                    if (event.key === 'Enter' || event.key === ' ') {
                      event.preventDefault();
                      onRow(row);
                    }
                  }}
                >
                  {columns.map((column) => <td key={column.key}>{column.cell(row)}</td>)}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : null}
      <div className="row">
        <button type="button" className="btn btn-secondary" disabled={page === 0} onClick={() => setPage((value) => value - 1)}>Anterior</button>
        <span className="nums muted">{page + 1} / {pages} · {total} registros</span>
        <button type="button" className="btn btn-secondary" disabled={page + 1 >= pages} onClick={() => setPage((value) => value + 1)}>Siguiente</button>
      </div>
    </section>
  );
}
