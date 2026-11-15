type BrandLogoProps = {
  size?: number;
  showText?: boolean;
  tagline?: string;
  onClick?: () => void;
};

export function BrandLogo({
  size = 36,
  showText = true,
  tagline,
  onClick,
}: BrandLogoProps) {
  const mark = (
    <>
      <div className="brand-logo-mark" style={{ width: size, height: size }} aria-hidden>
        <img src="/brand/mark.svg" alt="" width={size} height={size} />
      </div>
      {showText && (
        <div className="brand-logo-text">
          <span className="brand-logo-name">My Works App</span>
          {tagline && <span className="brand-logo-tagline">{tagline}</span>}
        </div>
      )}
    </>
  );

  if (onClick) {
    return (
      <button
        type="button"
        className="brand-logo brand-logo-button"
        onClick={onClick}
        aria-label="Volver al inicio"
      >
        {mark}
      </button>
    );
  }

  return <div className="brand-logo">{mark}</div>;
}
