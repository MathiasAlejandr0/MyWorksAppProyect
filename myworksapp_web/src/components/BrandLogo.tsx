type BrandLogoProps = {
  size?: number;
  showText?: boolean;
  tagline?: string;
};

export function BrandLogo({ size = 36, showText = true, tagline }: BrandLogoProps) {
  return (
    <div className="brand-logo">
      <div className="brand-logo-mark" style={{ width: size, height: size }} aria-hidden>
        <img src="/brand/mark.svg" alt="" width={size} height={size} />
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
