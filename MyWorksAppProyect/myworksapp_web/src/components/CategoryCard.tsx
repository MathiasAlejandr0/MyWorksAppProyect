import { useState } from 'react';
import { ChevronRight } from 'lucide-react';

type CategoryCardProps = {
  title: string;
  subtitle: string;
  photo: string;
  onClick: () => void;
  variant?: 'landing' | 'grid';
};

export function CategoryCard({ title, subtitle, photo, onClick, variant = 'landing' }: CategoryCardProps) {
  const [failed, setFailed] = useState(false);

  return (
    <button
      type="button"
      className={`category-card category-card--${variant}`}
      onClick={onClick}
    >
      <div className={`category-media${failed ? ' category-media--fallback' : ''}`}>
        {!failed ? (
          <img
            src={photo}
            srcSet={/\/categories\/(electricidad|pintura|jardineria|construccion|soporte-tecnico|mudanza|climatizacion)\.webp$/.test(photo)
              ? `${photo.replace('.webp', '-480.webp')} 480w, ${photo.replace('.webp', '-640.webp')} 640w, ${photo.replace('.webp', '-960.webp')} 960w`
              : undefined}
            sizes="(max-width: 700px) 100vw, 320px"
            alt=""
            loading="lazy"
            decoding="async"
            width={640}
            height={400}
            onError={() => setFailed(true)}
          />
        ) : null}
        <div className="category-media-scrim" aria-hidden />
        <div className="category-media-label">
          <span className="category-title">{title}</span>
          <span className="category-subtitle">{subtitle}</span>
          <span className="category-explore">
            {variant === 'grid' ? 'EXPLORAR' : ''}
            <ChevronRight size={variant === 'grid' ? 14 : 16} strokeWidth={2.2} />
          </span>
        </div>
      </div>
    </button>
  );
}
