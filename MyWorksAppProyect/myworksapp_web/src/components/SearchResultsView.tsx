import { lazy, Suspense, useEffect, useMemo, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import {
  Bell,
  Star,
  ChevronLeft,
  MapPin,
  Navigation,
  Search,
  X,
} from 'lucide-react';
import { formatServiceRadiusKm, pluralize, roundClp } from '@myworksapp/shared';
import { StarScore } from './StarScore';
import { supabase } from '../supabaseClient';
import { BrandLogo } from './BrandLogo';
import { profileLabel } from '../profileLabel';
import { sortSearchWorkers, type CatalogSort } from '../catalogSort';

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
  serviceRadiusKm?: number | null;
  urbanRadiusKm?: number | null;
  outsideMobilizationFeeClp?: number | null;
  isElite?: boolean;
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
  clientLocation?: { latitude: number; longitude: number } | null;
  onUseMyLocation?: () => void;
  onPickClientLocation?: (location: { latitude: number; longitude: number }) => void;
  onSearchAddress?: (query: string) => Promise<unknown>;
  locating?: boolean;
  locatingAddress?: boolean;
}

function clp(amount: number): string {
  return roundClp(amount).toLocaleString('es-CL');
}

function coverageLine(worker: SearchWorker): string {
  const km = formatServiceRadiusKm(worker.serviceRadiusKm);
  return `Hasta ${km} km sin extra de traslado. El monto se confirma al pagar.`;
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
  clientLocation = null,
  onUseMyLocation,
  onPickClientLocation,
  onSearchAddress,
  locating = false,
  locatingAddress = false,
}: SearchResultsViewProps) {
  const displayQuery = query.trim() || 'profesionales';
  const [addressQuery, setAddressQuery] = useState('');
  const [showMap, setShowMap] = useState(false);

  useEffect(() => {
    let second = 0;
    const first = window.requestAnimationFrame(() => {
      second = window.requestAnimationFrame(() => setShowMap(true));
    });
    return () => {
      window.cancelAnimationFrame(first);
      window.cancelAnimationFrame(second);
    };
  }, []);

  const submitAddress = (event: FormEvent) => {
    event.preventDefault();
    const text = addressQuery.trim();
    if (!text || !onSearchAddress) return;
    void onSearchAddress(text);
  };

  const [sort, setSort] = useState<CatalogSort>('recommended');
  const [minRating, setMinRating] = useState(0);
  const [onlyAvailable, setOnlyAvailable] = useState(false);
  const [demoMode, setDemoMode] = useState(false);
  useEffect(() => {
    let cancelled = false;
    const db = supabase as unknown as {
      rpc: (fn: string) => Promise<{ data: unknown; error: { message: string } | null }>;
    };
    void Promise.resolve(db.rpc('demo_modo_activo')).then(({ data, error }) => {
      if (!cancelled && !error && data === true) setDemoMode(true);
    }).catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);
  const visibleWorkers = useMemo(() => {
    const filtered = workers.filter((worker) => {
      if (worker.rating < minRating) return false;
      if (onlyAvailable && worker.availableNow !== true) return false;
      return true;
    });
    return sortSearchWorkers(filtered, sort, clientLocation);
  }, [workers, sort, minRating, onlyAvailable, clientLocation]);
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
          {profileName ? (
          <button
            type="button"
            className="search-nav-bell"
            aria-label="Notificaciones"
            onClick={onOpenNotifications}
          >
            <Bell size={18} />
            {unreadCount > 0 ? <span className="search-nav-badge">{unreadCount}</span> : null}
          </button>
          ) : null}
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
        <aside className="search-filters" aria-label="Filtros de búsqueda">
          <div className="search-filters-head">
            <h2>Filtros</h2>
            <button
              type="button"
              className="search-filters-clear"
              onClick={() => {
                setSort('recommended');
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
              onChange={(event) => setSort(event.target.value as CatalogSort)}
            >
              <option value="recommended">Ordenar por: Cercanía, nota y precio</option>
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
            <>
            {demoMode ? <p className="demo-banner" role="status">Datos de demostración</p> : null}
            <div className="search-results-grid">
              {visibleWorkers.map((w) => (
                <article
                  key={w.id}
                  className={`pro-card${selectedWorkerId === w.id ? ' is-selected' : ''}`}
                >
                  <button type="button" className="pro-card-hit" onClick={() => onSelectWorker(w)}>
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
                      {w.isElite ? (
                        <span className="pro-card-elite">Élite</span>
                      ) : null}
                    </div>
                    <span className="pro-card-role">{w.profession}</span>
                    <div className="pro-card-rating">
                      <Star size={13} fill="var(--orange-accent)" color="var(--orange-accent)" aria-hidden />
                      {w.rating <= 0 ? (
                        <>
                          <strong>Nuevo · sin reseñas aún</strong>
                          {w.jobsDone > 0 && <span>{pluralize(w.jobsDone, 'trabajo')}</span>}
                        </>
                      ) : (
                        <>
                          <strong>{w.rating.toFixed(1)}</strong>
                          <StarScore rating={w.rating} />
                          <span>{pluralize(w.jobsDone, 'trabajo')}</span>
                        </>
                      )}
                    </div>
                    <p className="pro-card-coverage">{coverageLine(w)}</p>
                    <div className="pro-card-footer">
                      <span className="pro-card-price">
                        Desde ${clp(w.pricePerVisit)} / visita
                      </span>
                      {w.availableNow === true && (
                        <span className="pro-card-badge">Disponible ahora</span>
                      )}
                    </div>
                  </div>
                  </button>
                  <Link className="pro-card-profile" to={`/profesional/${w.id}`}>Ver ficha</Link>
                </article>
              ))}
            </div>
            </>
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

        <aside className="search-map-panel" aria-label="Mapa de profesionales">
          {showMap ? (
            <Suspense fallback={<div className="search-map-skeleton">Cargando mapa…</div>}>
              <PremiumSearchMap
                workers={visibleWorkers}
                selectedWorkerId={selectedWorkerId}
                onSelectWorker={onSelectWorker}
                categoryLabel={displayQuery}
                clientLocation={clientLocation}
                onPickClientLocation={onPickClientLocation}
              />
            </Suspense>
          ) : (
            <div className="search-map-skeleton">Cargando mapa…</div>
          )}
          <div className="search-map-location">
            <form className="search-map-address" onSubmit={submitAddress}>
              <MapPin size={14} aria-hidden />
              <input
                type="text"
                value={addressQuery}
                onChange={(event) => setAddressQuery(event.target.value)}
                placeholder="Calle, barrio o ciudad"
                aria-label="Dirección del trabajo"
                disabled={locatingAddress}
              />
              <button type="submit" disabled={locatingAddress || addressQuery.trim().length < 3}>
                <Search size={14} />
                {locatingAddress ? 'Buscando…' : 'Buscar'}
              </button>
            </form>
            <div className="search-map-location-actions">
              <button
                type="button"
                className="search-map-locate"
                onClick={onUseMyLocation}
                disabled={locating}
              >
                <Navigation size={14} />
                {locating
                  ? 'Leyendo GPS…'
                  : clientLocation
                    ? 'Ubicación lista'
                    : 'Usar GPS'}
              </button>
              <span>o marca el punto en el mapa</span>
            </div>
          </div>
          <div className="search-map-legend">
            <span className="search-map-legend-item">
              <span className="search-map-legend-dot" /> Profesionales cerca
            </span>
            <span className="search-map-legend-item">
              <span className="search-map-legend-dot search-map-legend-dot--elite" /> Élite del mes
            </span>
            <span className="search-map-legend-item">
              <span className="search-map-legend-dot search-map-legend-dot--client" /> Tu trabajo
            </span>
            <span className="search-map-legend-item">
              <span className="search-map-legend-radar" /> Área sin extra de traslado
            </span>
          </div>
        </aside>
      </div>
    </div>
  );
}
