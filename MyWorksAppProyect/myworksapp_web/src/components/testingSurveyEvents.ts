export const OPEN_SURVEY_EVENT = 'mwa:abrir-encuesta';

/** Abre la encuesta de testing desde cualquier botón o enlace de la web. */
export function openTestingSurvey(): void {
  window.dispatchEvent(new Event(OPEN_SURVEY_EVENT));
}

/** /encuesta o ?encuesta abren la encuesta directo (enlace para testers). */
export function surveyRequestedByUrl(): boolean {
  const { pathname, search } = window.location;
  return /^\/encuesta\/?$/i.test(pathname) || new URLSearchParams(search).has('encuesta');
}
