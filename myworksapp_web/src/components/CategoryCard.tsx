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
            alt=""
            loading="lazy"
            decoding="async"
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
