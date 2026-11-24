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
  const [imageError, setImageError] = useState(false);

  return (
    <button
      type="button"
      className={`category-card category-card--${variant}`}
      onClick={onClick}
    >
      <div className={`category-media${imageError ? ' category-media--fallback' : ''}`}>
        {!imageError && (
          <img
            src={photo}
            alt={`${title} - ${subtitle}`}
            loading="lazy"
            decoding="async"
            width={640}
            height={400}
            onError={(e) => {
              console.error(`Failed to load image: ${photo}`, e);
              setImageError(true);
            }}
          />
        )}
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
