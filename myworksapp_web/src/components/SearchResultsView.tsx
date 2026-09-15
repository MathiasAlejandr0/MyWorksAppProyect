import {
  Heart,
  Bell,
  Star,
  MapPin,
  SlidersHorizontal,
  ChevronLeft,
  ChevronRight,
  Navigation,
  Zap,
  X,
} from 'lucide-react';
import { BrandLogo } from './BrandLogo';

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
}: SearchResultsViewProps) {
  const displayQuery = query || 'electricistas';
  const total = workers.length > 0 ? 248 : workers.length;

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
          <button type="button" className="search-nav-icon-btn" aria-label="Favoritos">
            <Heart size={18} />
            <span>Favoritos</span>
          </button>
          <button type="button" className="search-nav-bell" aria-label="Notificaciones">
            <Bell size={18} />
            <span className="search-nav-badge">3</span>
          </button>
          {profileName ? (
            <div className="search-nav-profile">
              <div className="search-nav-avatar">{profileName.charAt(0)}</div>
              <div>
                <strong>{profileName.split(' ')[0]} R.</strong>
                <span>Ver perfil</span>
              </div>
            </div>
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
            <button type="button" className="search-filters-clear">
              Limpiar todo
            </button>
          </div>

          <div className="filter-group">
            <label className="filter-label">
              <MapPin size={14} /> Ubicación
            </label>
            <select className="filter-select" defaultValue="all">
              <option value="all">Todas las ubicaciones</option>
              <option value="palermo">Palermo</option>
              <option value="condes">Las Condes</option>
            </select>
          </div>

          <div className="filter-group">
            <label className="filter-label">Precio por hora</label>
            <div className="filter-range-labels">
              <span>$10</span>
              <span>$80</span>
            </div>
            <input type="range" min={10} max={80} defaultValue={45} className="filter-range" />
          </div>

          <div className="filter-group">
            <label className="filter-label">Calificación mínima</label>
            <div className="filter-stars">
              {['4.5 y más', '4.0 y más', '3.5 y más', '3.0 y más'].map((label, i) => (
                <label key={label} className="filter-star-row">
                  <input type="radio" name="rating" defaultChecked={i === 0} />
                  <span className="filter-star-icons">
                    {[1, 2, 3, 4, 5].map((s) => (
                      <Star key={s} size={12} fill={s <= 4 ? 'var(--orange-accent)' : 'none'} />
                    ))}
                  </span>
                  <span>{label}</span>
                </label>
              ))}
            </div>
          </div>

          <div className="filter-group">
            <label className="filter-label">Disponibilidad</label>
            <label className="filter-check">
              <input type="checkbox" defaultChecked /> Disponible ahora
            </label>
            <label className="filter-check">
              <input type="checkbox" /> En las próximas 24h
            </label>
          </div>

          <div className="filter-group">
            <label className="filter-label">Servicios</label>
            {['Instalaciones eléctricas', 'Reparaciones', 'Mantenimiento', 'Emergencias'].map(
              (svc, i) => (
                <label key={svc} className="filter-check">
                  <input type="checkbox" defaultChecked={i === 0} /> {svc}
                </label>
              ),
            )}
          </div>

          <button type="button" className="filter-more-btn">
            <SlidersHorizontal size={16} /> Más filtros
          </button>
        </aside>

        <main className="search-results-main">
          <div className="search-results-head">
            <div>
              <h1>Resultados para &ldquo;{displayQuery}&rdquo;</h1>
              <p>
                Mostrando 1–{Math.min(12, workers.length || 12)} de {total} profesionales
              </p>
            </div>
            <select className="search-sort" defaultValue="relevance" aria-label="Ordenar por">
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
            <div className="search-empty">
              <p>No hay profesionales disponibles para esta búsqueda.</p>
            </div>
          ) : (
            <div className="search-results-grid">
              {workers.map((w) => (
                <button
                  key={w.id}
                  type="button"
                  className={`pro-card${selectedWorkerId === w.id ? ' is-selected' : ''}`}
                  onClick={() => onSelectWorker(w)}
                >
                  <img src={w.photoUrl} alt="" className="pro-card-photo" />
                  <div className="pro-card-body">
                    <div className="pro-card-top">
                      <strong>{w.name}</strong>
                      <Heart size={16} className="pro-card-heart" />
                    </div>
                    <span className="pro-card-role">{w.profession}</span>
                    <div className="pro-card-rating">
                      <Star size={13} fill="var(--orange-accent)" color="var(--orange-accent)" />
                      <strong>{w.rating.toFixed(1)}</strong>
                      <span className="pro-card-stars">★★★★★</span>
                    </div>
                    <div className="pro-card-footer">
                      <span className="pro-card-price">
                        Desde ${Math.round(w.pricePerVisit / 1000) * 1000 || 35} / hora
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

          <nav className="search-pagination" aria-label="Paginación">
            <button type="button" className="search-page-btn" disabled aria-label="Anterior">
              <ChevronLeft size={16} />
            </button>
            {[1, 2, 3].map((n) => (
              <button
                key={n}
                type="button"
                className={`search-page-num${n === 1 ? ' is-active' : ''}`}
              >
                {n}
              </button>
            ))}
            <span className="search-page-dots">…</span>
            <button type="button" className="search-page-num">
              21
            </button>
            <button type="button" className="search-page-btn" aria-label="Siguiente">
              <ChevronRight size={16} />
            </button>
          </nav>
        </main>

        <aside className="search-map-panel">
          <div className="search-map-canvas">
            <div className="search-map-grid" aria-hidden />
            <div className="search-map-route" aria-hidden />
            {['Palermo', 'Recoleta', 'Belgrano'].map((zone, i) => (
              <div
                key={zone}
                className={`search-map-pin${i === 0 ? ' is-active' : ''}`}
                style={{ top: `${28 + i * 18}%`, left: `${35 + i * 12}%` }}
              >
                <Zap size={14} />
              </div>
            ))}
            <div className="search-map-zone-label">Palermo</div>
            {workers[0] && (
              <div className="search-map-card">
                <img src={workers[0].photoUrl} alt="" />
                <div>
                  <strong>{workers[0].name}</strong>
                  <span>{workers[0].profession}</span>
                </div>
              </div>
            )}
          </div>
          <div className="search-map-controls">
            <button type="button" className="search-map-zoom">+</button>
            <button type="button" className="search-map-zoom">−</button>
          </div>
          <button type="button" className="search-map-locate">
            <Navigation size={14} /> Usar mi ubicación actual
          </button>
          <div className="search-map-legend">
            <span className="search-map-legend-dot" /> Alta coincidencia
          </div>
        </aside>
      </div>
    </div>
  );
}
