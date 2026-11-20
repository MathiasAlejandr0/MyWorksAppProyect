/** Estrellas según la nota real, de 0 a 5. */
export function StarScore({ rating }: { rating: number }) {
  const safe = Number.isFinite(rating) ? Math.max(0, Math.min(5, rating)) : 0;
  const filled = Math.round(safe);
  return (
    <span className="pro-card-stars" aria-label={`${safe.toFixed(1)} de 5`}>
      <span aria-hidden>{'★'.repeat(filled)}</span>
      <span className="pro-card-stars-empty" aria-hidden>{'★'.repeat(5 - filled)}</span>
    </span>
  );
}
