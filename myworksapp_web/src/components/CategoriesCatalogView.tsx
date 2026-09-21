import { ArrowLeft } from 'lucide-react';
import { BrandLogo } from './BrandLogo';
import { CategoryCard } from './CategoryCard';
import type { ServiceCategory } from '../data/serviceCategories';

type CategoriesCatalogViewProps = {
  categories: ServiceCategory[];
  profileName?: string;
  onBack: () => void;
  onSelectCategory: (category: ServiceCategory) => void;
  onShowAuth: () => void;
};

/** Catálogo completo de oficios — no dispara búsqueda de electricistas. */
export function CategoriesCatalogView({
  categories,
  profileName,
  onBack,
  onSelectCategory,
  onShowAuth,
}: CategoriesCatalogViewProps) {
  return (
    <div className="categories-catalog-view">
      <header className="categories-catalog-nav">
        <div className="categories-catalog-nav-left">
          <button
            type="button"
            className="search-back-btn"
            onClick={onBack}
            aria-label="Volver al inicio"
          >
            <ArrowLeft size={20} />
          </button>
          <BrandLogo size={32} tagline="Todos los oficios para tu hogar" />
        </div>
        <div className="categories-catalog-nav-right">
          {profileName ? (
            <div className="search-nav-profile">
              <div className="search-nav-avatar">{profileName.charAt(0)}</div>
              <strong>{profileName.split(' ')[0]}</strong>
            </div>
          ) : (
            <button type="button" className="btn-outline-orange" onClick={onShowAuth}>
              Ingresar
            </button>
          )}
        </div>
      </header>

      <main className="categories-catalog-main container">
        <p className="section-kicker">CATÁLOGO</p>
        <h1>Todas las categorías</h1>
        <p className="categories-catalog-lead">
          Elige un oficio. Te mostraremos profesionales cerca de ti en el mapa, con
          disponibilidad y precio de visita.
        </p>

        <div className="categories-grid categories-grid--catalog">
          {categories.map((cat) => (
            <CategoryCard
              key={cat.id}
              title={cat.title}
              subtitle={cat.subtitle}
              photo={cat.photo}
              variant="grid"
              onClick={() => onSelectCategory(cat)}
            />
          ))}
        </div>
      </main>
    </div>
  );
}
