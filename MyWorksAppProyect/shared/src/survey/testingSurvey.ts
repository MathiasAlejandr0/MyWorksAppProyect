import type { AppSupabase } from '../client';

/**
 * Encuesta de testing (UAT). Cuestionario SUS de 10 ítems (Brooke, 1996),
 * en español, más satisfacción general, si completó la tarea y comentarios.
 * Se envía con la función enviar_encuesta_testing; la base guarda cada
 * respuesta en encuesta_testing_respuestas y calcula el puntaje SUS.
 */
export const SUS_ITEMS: readonly string[] = [
  'Creo que me gustaría usar MyWorksApp con frecuencia.',
  'Encontré MyWorksApp innecesariamente complicada.',
  'Pensé que MyWorksApp era fácil de usar.',
  'Creo que necesitaría ayuda de una persona con conocimientos técnicos para usar MyWorksApp.',
  'Las funciones de MyWorksApp están bien integradas.',
  'Pensé que había demasiada inconsistencia en MyWorksApp.',
  'Imagino que la mayoría de las personas aprendería a usar MyWorksApp muy rápido.',
  'Encontré MyWorksApp muy difícil de usar.',
  'Me sentí muy seguro(a) usando MyWorksApp.',
  'Necesité aprender muchas cosas antes de poder usar MyWorksApp.',
];

export const SUS_SCALE_LABELS: readonly string[] = [
  'Muy en desacuerdo',
  'En desacuerdo',
  'Neutral',
  'De acuerdo',
  'Muy de acuerdo',
];

export type SurveyPlatform = 'web' | 'app' | 'escritorio';
export type SurveyRole = 'visitante' | 'cliente' | 'profesional' | 'administrador';
export type SurveyTaskResult = 'si' | 'parcial' | 'no';

export interface TestingSurveyInput {
  platform: SurveyPlatform;
  role: SurveyRole;
  taskCompleted: SurveyTaskResult;
  satisfaction: number;
  sus: number[];
  worked?: string;
  improve?: string;
  appVersion?: string;
}

export const SURVEY_TEXT_MAX = 1000;

/** Puntaje SUS 0–100. null si las respuestas no están completas. */
export function susScore(answers: readonly number[]): number | null {
  if (answers.length !== 10) return null;
  let sum = 0;
  for (let i = 0; i < 10; i += 1) {
    const value = answers[i];
    if (!Number.isInteger(value) || value < 1 || value > 5) return null;
    sum += i % 2 === 0 ? value - 1 : 5 - value;
  }
  return sum * 2.5;
}

/** Lectura habitual del SUS (Bangor, Kortum y Miller, 2009). */
export function susGrade(score: number): string {
  if (score >= 85) return 'Excelente';
  if (score >= 72) return 'Buena';
  if (score >= 68) return 'Sobre el promedio';
  if (score >= 51) return 'Aceptable con reparos';
  return 'Deficiente';
}

/** Mensaje para el usuario, o null si se puede enviar. */
export function validateTestingSurvey(input: TestingSurveyInput): string | null {
  const answered = input.sus.filter((value) => Number.isInteger(value) && value >= 1 && value <= 5).length;
  if (input.sus.length !== 10 || answered < 10) {
    return `Responde las 10 afirmaciones (llevas ${answered} de 10).`;
  }
  if (!Number.isInteger(input.satisfaction) || input.satisfaction < 1 || input.satisfaction > 5) {
    return 'Elige tu satisfacción general de 1 a 5.';
  }
  if ((input.worked ?? '').length > SURVEY_TEXT_MAX || (input.improve ?? '').length > SURVEY_TEXT_MAX) {
    return `Los comentarios admiten hasta ${SURVEY_TEXT_MAX} caracteres.`;
  }
  return null;
}

export async function submitTestingSurvey(
  supabase: AppSupabase,
  input: TestingSurveyInput,
): Promise<void> {
  const problem = validateTestingSurvey(input);
  if (problem) throw new Error(problem);
  const clean = (value?: string) => {
    const trimmed = (value ?? '').trim();
    return trimmed ? trimmed.slice(0, SURVEY_TEXT_MAX) : null;
  };
  // La encuesta y sus 10 respuestas entran juntas por la función de la base,
  // que valida y calcula el puntaje (vista encuestas_testing_con_puntaje).
  const { error } = await supabase.rpc('enviar_encuesta_testing', {
    p_plataforma: input.platform,
    p_rol: input.role,
    p_tarea_completada: input.taskCompleted,
    p_satisfaccion: input.satisfaction,
    p_sus: input.sus,
    p_que_funciono: clean(input.worked) ?? undefined,
    p_que_mejorar: clean(input.improve) ?? undefined,
    p_version_app: clean(input.appVersion)?.slice(0, 40) ?? undefined,
  });
  if (error) throw new Error('No pudimos guardar la encuesta. Inténtalo de nuevo en un momento.');
}
