interface SkeletonProps {
  width?: string | number;
  height?: string | number;
  borderRadius?: string | number;
  className?: string;
}

export function Skeleton({ width = '100%', height = 14, borderRadius = 8, className = '' }: SkeletonProps) {
  return (
    <div
      className={`skeleton-block ${className}`.trim()}
      style={{ width, height, borderRadius }}
      aria-hidden
    />
  );
}

export function SessionLoadingShell() {
  return (
    <div className="session-loading-shell" role="status" aria-live="polite" aria-label="Cargando sesión">
      <aside className="session-loading-sidebar">
        <Skeleton width={140} height={18} borderRadius={6} />
        <Skeleton width="100%" height={36} borderRadius={8} />
        <Skeleton width="100%" height={36} borderRadius={8} />
        <Skeleton width="100%" height={36} borderRadius={8} />
      </aside>
      <main className="session-loading-main">
        <div className="loading-inline">
          <span className="loading-spinner" aria-hidden />
          <span className="loading-label">Verificando sesión…</span>
        </div>
      </main>
    </div>
  );
}

export function KpiCardsSkeleton({ count = 4 }: { count?: number }) {
  return (
    <div
      className="kpi-skeleton-grid"
      role="status"
      aria-live="polite"
      aria-label="Cargando métricas"
    >
      {Array.from({ length: count }).map((_, index) => (
        <div key={index} className="card-3d kpi-skeleton-card">
          <Skeleton width="55%" height={12} />
          <Skeleton width="45%" height={28} />
          <Skeleton width="38%" height={11} />
        </div>
      ))}
    </div>
  );
}

export function TableRowsSkeleton({ rows = 5, columns = 6 }: { rows?: number; columns?: number }) {
  return (
    <div role="status" aria-live="polite" aria-label="Cargando datos">
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <div
          key={rowIndex}
          className="table-skeleton-row"
          style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}
        >
          {Array.from({ length: columns }).map((__, colIndex) => (
            <Skeleton
              key={colIndex}
              width={colIndex === 0 ? '72%' : colIndex === columns - 1 ? '58%' : '86%'}
              height={12}
            />
          ))}
        </div>
      ))}
    </div>
  );
}

export function LoadingInline({ label }: { label: string }) {
  return (
    <div className="loading-inline loading-inline--compact" role="status" aria-live="polite">
      <span className="loading-spinner" aria-hidden />
      <span className="loading-label">{label}</span>
    </div>
  );
}
