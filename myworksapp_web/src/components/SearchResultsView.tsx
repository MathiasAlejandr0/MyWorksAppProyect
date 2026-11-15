import { lazy, Suspense, useMemo, useState } from 'react';
import {
  Bell,
  Star,
  ChevronLeft,
  X,
} from 'lucide-react';
import { BrandLogo } from './BrandLogo';
import { profileLabel } from '../profileLabel';

const PremiumSearchMap = lazy(() =>
  import('./PremiumSearchMap').then((m) => ({ default: m.PremiumSearchMap })),
);

export interface SearchWorker {
  id: string;
  name: string;
  profession: string;
  category: string;
  rating: number;
  jobsDone: number;
  photoUrl: string;
  pricePerVisit: number;
  availableNow?: boolean;
  latitude?: number | null;
  longitude?: number | null;
}

interface SearchResultsViewProps {
  query: string;
  workers: SearchWorker[];
  isLoading: boolean;
  profileName?: string;
  profilePhoto?: string;
  selectedWorkerId: string | null;
  onQueryChange: (q: string) => void;
  onSearch: (q: string) => void;
  onSelectWorker: (worker: SearchWorker) => void;
  onBack: () => void;
  onShowAuth: () => void;
  onOpenNotifications?: () => void;
  onLogout?: () => void;
  unreadCount?: number;
  hasMore?: boolean;
  isLoadingMore?: boolean;
  onLoadMore?: () => void;
}

function clp(amount: number): string {
  const value = Number.isFinite(amount) ? Math.round(amount) : 0;
  return value.toLocaleString('es-CL');
}

export function SearchResultsView({
  query,
  workers,
  isLoading,
  profileName,
  selectedWorkerId,
  onQueryChange,
  onSearch,
  onSelectWorker,
  onBack,
  onShowAuth,
  onOpenNotifications,
  onLogout,
  unreadCount = 0,
  hasMore = false,
  isLoadingMore = false,
  onLoadMore,
}: SearchResultsViewProps) {
  const displayQuery = query.trim() || 'profesionales';
  const [sort, setSort] = useState<'relevance' | 'price' | 'rating'>('relevance');
  const [minRating, setMinRating] = useState(0);
  const [onlyAvailable, setOnlyAvailable] = useState(false);
  const visibleWorkers = useMemo(() => {
    const filtered = workers.filter((worker) => {
      if (worker.rating < minRating) return false;
      if (onlyAvailable && worker.availableNow === false) return false;
      return true;
    });
    if (sort === 'price') {
      return [...filtered].sort((a, b) => a.pricePerVisit - b.pricePerVisit);
    }
    if (sort === 'rating') {
      return [...filtered].sort((a, b) => b.rating - a.rating);
    }
    return filtered;
  }, [workers, sort, minRating, onlyAvailable]);
  const total = visibleWorkers.length;

  return (
    <div className="search-view">
      <header className="search-view-nav">
        <div className="search-view-nav-left">
          <button type="button" className="search-back-btn" onClick={onBack} aria-label="Volver">
            <ChevronLeft size={20} />
          </button>
          <BrandLogo size={32} tagline="Encuentra profesionales. Reserva con confianza." />
        </div>

        <div className="search-view-nav-center">
          <div className="search-view-input-wrap">
            <input
              type="text"
              value={query}
              onChange={(e) => onQueryChange(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && onSearch(query)}
              className="search-view-input"
              aria-label="Buscar profesionales"
            />
            {query && (
              <button
                type="button"
                className="search-view-clear"
                onClick={() => onQueryChange('')}
                aria-label="Limpiar búsqueda"
              >
                <X size={16} />
              </button>
            )}
          </div>
        </div>

        <div className="search-view-nav-right">
          <button
            type="button"
            className="search-nav-bell"
            aria-label="Notificaciones"
            onClick={onOpenNotifications}
          >
            <Bell size={18} />
            {unreadCount > 0 ? <span className="search-nav-badge">{unreadCount}</span> : null}
          </button>
          {profileName ? (
            <button type="button" className="search-nav-profile" onClick={() => onLogout?.()}>
              <div className="search-nav-avatar">{profileName.trim().charAt(0).toUpperCase()}</div>
              <div>
                <strong>{profileLabel(profileName)}</strong>
                <span>Salir</span>
              </div>
            </button>
          ) : (
            <button type="button" className="btn-outline-orange" onClick={onShowAuth}>
              Ingresar
            </button>
          )}
        </div>
      </header>

      <div className="search-view-body">
        <aside className="search-filters">
          <div className="search-filters-head">
            <h2>Filtros</h2>
            <button
              type="button"
              className="search-filters-clear"
              onClick={() => {
                setSort('relevance');
                setMinRating(0);
                setOnlyAvailable(false);
              }}
            >
              Limpiar todo
            </button>
          </div>

          <div className="filter-group">
            <label className="filter-label">Calificación mínima</label>
            <div className="filter-stars">
              {[
                { label: 'Cualquiera', value: 0 },
                { label: '4.5 y más', value: 4.5 },
                { label: '4.0 y más', value: 4 },
                { label: '3.5 y más', value: 3.5 },
              ].map((item) => (
                <label key={item.label} className="filter-star-row">
                  <input
                    type="radio"
                    name="rating"
                    checked={minRating === item.value}
                    onChange={() => setMinRating(item.value)}
                  />
                  <span>{item.label}</span>
                </label>
              ))}
            </div>
          </div>

          <div className="filter-group">
            <label className="filter-label">Disponibilidad</label>
            <label className="filter-check">
              <input
                type="checkbox"
                checked={onlyAvailable}
                onChange={(event) => setOnlyAvailable(event.target.checked)}
              />{' '}
              Disponible ahora
            </label>
          </div>
        </aside>

        <main className="search-results-main">
          <div className="search-results-head">
            <div>
              <h1>Resultados para &ldquo;{displayQuery}&rdquo;</h1>
              <p>
                {total === 0
                  ? 'Sin profesionales en esta página'
                  : `Mostrando ${total} profesional${total === 1 ? '' : 'es'}${hasMore ? ' (hay más)' : ''}`}
              </p>
            </div>
            <select
              className="search-sort"
              value={sort}
              aria-label="Ordenar por"
              onChange={(event) => setSort(event.target.value as 'relevance' | 'price' | 'rating')}
            >
              <option value="relevance">Ordenar por: Relevancia</option>
              <option value="price">Precio</option>
              <option value="rating">Calificación</option>
            </select>
          </div>

          {isLoading ? (
            <div className="search-results-loading" aria-busy="true">
              {[0, 1, 2, 3].map((i) => (
                <div key={i} className="pro-card pro-card-skeleton">
                  <div className="skeleton-block skeleton-avatar-lg" />
                  <div className="skeleton-block skeleton-line" />
                  <div className="skeleton-block skeleton-line short" />
                </div>
              ))}
            </div>
          ) : workers.length === 0 ? (
            <div className="search-empty" role="status">
              <h2>Todavía no hay profesionales en esta categoría</h2>
              <p>
                No hay visitas publicadas ahora. Elige otro oficio del catálogo
                o vuelve más tarde.
              </p>
              <button type="button" className="btn-outline-orange" onClick={onBack}>
                Ver otras categorías
              </button>
            </div>
          ) : visibleWorkers.length === 0 ? (
            <div className="search-empty" role="status">
              <h2>Ningún profesional cumple esos filtros</h2>
              <p>Prueba con otra calificación o limpia los filtros.</p>
            </div>
          ) : (
            <div className="search-results-grid">
              {visibleWorkers.map((w) => (
                <button
                  key={w.id}
                  type="button"
                  className={`pro-card${selectedWorkerId === w.id ? ' is-selected' : ''}`}
                  onClick={() => onSelectWorker(w)}
                >
                  <img
                    src={w.photoUrl}
                    alt=""
                    className="pro-card-photo"
                    width={72}
                    height={72}
                    loading="lazy"
                    decoding="async"
                  />
                  <div className="pro-card-body">
                    <div className="pro-card-top">
                      <strong>{w.name}</strong>
                    </div>
                    <span className="pro-card-role">{w.profession}</span>
                    <div className="pro-card-rating">
                      <Star size={13} fill="var(--orange-accent)" color="var(--orange-accent)" />
                      <strong>{w.rating.toFixed(1)}</strong>
                      <span className="pro-card-stars">★★★★★</span>
                      <span>{w.jobsDone} trabajos</span>
                    </div>
                    <div className="pro-card-footer">
                      <span className="pro-card-price">
                        Desde ${clp(w.pricePerVisit)} / visita
                      </span>
                      {w.availableNow !== false && (
                        <span className="pro-card-badge">Disponible ahora</span>
                      )}
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}

          {hasMore && (
            <nav className="search-pagination" aria-label="Más resultados">
              <button
                type="button"
                className="search-page-btn"
                disabled={isLoadingMore}
                onClick={onLoadMore}
              >
                {isLoadingMore ? 'Cargando…' : 'Cargar más'}
              </button>
            </nav>
          )}
        </main>

        <aside className="search-map-panel">
          <Suspense fallback={<div className="search-map-skeleton" aria-hidden />}>
            <PremiumSearchMap
              workers={visibleWorkers}
              selectedWorkerId={selectedWorkerId}
              onSelectWorker={onSelectWorker}
              categoryLabel={displayQuery}
            />
          </Suspense>
          <div className="search-map-legend">
            <span className="search-map-legend-dot" /> Profesionales cerca
          </div>
        </aside>
      </div>
    </div>
  );
}
