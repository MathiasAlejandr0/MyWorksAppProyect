type BrandLogoProps = {
  size?: number;
  showText?: boolean;
  tagline?: string;
};

export function BrandLogo({ size = 36, showText = true, tagline }: BrandLogoProps) {
  return (
    <div className="brand-logo">
      <div className="brand-logo-mark" style={{ width: size, height: size }} aria-hidden>
        <svg viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect width="40" height="40" rx="10" fill="url(#brandGrad)" />
          <path
            d="M10 28V12h4.2l3.8 9.2L21.8 12H26v16h-3.6V18.8L18.6 28h-2.4l-3.8-9.2V28H10zm16.2-8.4c0-4.8 3.4-8 8-8 1.4 0 2.6.3 3.6.8V15c-.9-.5-2-.8-3.2-.8-2.6 0-4.2 1.8-4.2 4.4V28H26.2V19.6z"
            fill="#fff"
          />
          <defs>
            <linearGradient id="brandGrad" x1="0" y1="0" x2="40" y2="40">
              <stop stopColor="#FF8A3D" />
              <stop offset="1" stopColor="#F0782A" />
            </linearGradient>
          </defs>
        </svg>
      </div>
      {showText && (
        <div className="brand-logo-text">
          <span className="brand-logo-name">My Works App</span>
          {tagline && <span className="brand-logo-tagline">{tagline}</span>}
        </div>
      )}
    </div>
  );
}
