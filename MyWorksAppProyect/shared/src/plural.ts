/** «1 reseña», «2 reseñas». Evita textos como «1 notas». */
export function pluralize(count: number, singular: string, plural = `${singular}s`): string {
  return `${count} ${count === 1 ? singular : plural}`;
}
