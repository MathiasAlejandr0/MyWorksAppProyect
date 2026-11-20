import { useEffect, useRef, useState, type FormEvent } from 'react';
import { ClipboardList, X } from 'lucide-react';
import {
  SUS_ITEMS,
  SUS_SCALE_LABELS,
  submitTestingSurvey,
  susGrade,
  susScore,
  validateTestingSurvey,
  type SurveyPlatform,
  type SurveyRole,
  type SurveyTaskResult,
} from '@myworksapp/shared';
import { supabase } from '../supabaseClient';
import { useAuth } from '../context/useAuth';
import { OPEN_SURVEY_EVENT, surveyRequestedByUrl } from './testingSurveyEvents';
import { useDialogA11y } from '../hooks/useDialogA11y';


const ROLE_OPTIONS: { value: SurveyRole; label: string }[] = [
  { value: 'cliente', label: 'Cliente' },
  { value: 'profesional', label: 'Profesional' },
  { value: 'administrador', label: 'Administrador' },
  { value: 'visitante', label: 'Solo miré' },
];

const PLATFORM_OPTIONS: { value: SurveyPlatform; label: string }[] = [
  { value: 'web', label: 'Web' },
  { value: 'app', label: 'App Android' },
  { value: 'escritorio', label: 'Consola de escritorio' },
];

const TASK_OPTIONS: { value: SurveyTaskResult; label: string }[] = [
  { value: 'si', label: 'Sí' },
  { value: 'parcial', label: 'En parte' },
  { value: 'no', label: 'No' },
];

/**
 * Encuesta de testing (UAT): SUS de 10 afirmaciones, satisfacción general,
 * si pudo completar la tarea y comentarios. Se envía con enviar_encuesta_testing;
 * solo el administrador puede leer las respuestas.
 */
export function TestingSurveyModal() {
  const { profile } = useAuth();
  const [open, setOpen] = useState(surveyRequestedByUrl);
  const [pickedRole, setRole] = useState<SurveyRole | null>(null);
  const role: SurveyRole = pickedRole ?? (profile?.role === 'trabajador' ? 'profesional' : 'cliente');
  const [platform, setPlatform] = useState<SurveyPlatform>('web');
  const [task, setTask] = useState<SurveyTaskResult>('si');
  const [satisfaction, setSatisfaction] = useState(0);
  const [sus, setSus] = useState<number[]>(() => Array(10).fill(0));
  const [worked, setWorked] = useState('');
  const [improve, setImprove] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [sending, setSending] = useState(false);
  const [doneScore, setDoneScore] = useState<number | null>(null);
  const dialogRef = useRef<HTMLDivElement>(null);
  const close = () => {
    setOpen(false);
    if (surveyRequestedByUrl()) window.history.replaceState({}, '', '/');
  };
  useDialogA11y(open, close, dialogRef);

  useEffect(() => {
    const show = () => setOpen(true);
    window.addEventListener(OPEN_SURVEY_EVENT, show);
    return () => window.removeEventListener(OPEN_SURVEY_EVENT, show);
  }, []);

  if (!open) return null;

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    const input = {
      platform,
      role,
      taskCompleted: task,
      satisfaction,
      sus,
      worked,
      improve,
      appVersion: 'web',
    };
    const problem = validateTestingSurvey(input);
    if (problem) {
      setError(problem);
      return;
    }
    setSending(true);
    setError(null);
    try {
      await submitTestingSurvey(supabase, input);
      setDoneScore(susScore(sus));
    } catch (e) {
      setError(e instanceof Error ? e.message : 'No pudimos guardar la encuesta.');
    } finally {
      setSending(false);
    }
  };

  return (
    <div
      className="auth-modal-backdrop modal-fade-in"
      role="dialog"
      aria-modal="true"
      aria-labelledby="survey-title"
    >
      <div className="card-3d auth-modal-card survey-card modal-rise" ref={dialogRef}>
        <button type="button" className="modal-close" onClick={close} aria-label="Cerrar encuesta">
          <X size={18} />
        </button>
        <p className="auth-modal-kicker">
          <ClipboardList size={14} aria-hidden /> Encuesta de testing
        </p>
        <h2 id="survey-title" className="auth-modal-title">
          {doneScore === null ? '¿Cómo te fue probando MyWorksApp?' : '¡Gracias por tu opinión!'}
        </h2>

        {doneScore !== null ? (
          <>
            <p className="auth-modal-lead" role="status">
              Guardamos tu respuesta. Tu puntaje de usabilidad (SUS) fue {doneScore.toFixed(1)} de 100:{' '}
              {susGrade(doneScore).toLowerCase()}. El promedio de referencia es 68.
            </p>
            <button type="button" className="btn-primary auth-modal-submit" onClick={close}>
              Volver a MyWorksApp
            </button>
          </>
        ) : (
          <form onSubmit={submit} className="auth-modal-form survey-form">
            <p className="auth-modal-lead">
              Toma unos 3 minutos y es anónima. No se publica en ningún perfil.
            </p>

            <fieldset className="survey-fieldset">
              <legend>1. ¿Con qué rol probaste?</legend>
              <div className="survey-chips">
                {ROLE_OPTIONS.map((option) => (
                  <label key={option.value} className="survey-chip">
                    <input
                      type="radio"
                      name="survey-role"
                      checked={role === option.value}
                      onChange={() => setRole(option.value)}
                    />
                    {option.label}
                  </label>
                ))}
              </div>
            </fieldset>

            <fieldset className="survey-fieldset">
              <legend>2. ¿Dónde lo probaste?</legend>
              <div className="survey-chips">
                {PLATFORM_OPTIONS.map((option) => (
                  <label key={option.value} className="survey-chip">
                    <input
                      type="radio"
                      name="survey-platform"
                      checked={platform === option.value}
                      onChange={() => setPlatform(option.value)}
                    />
                    {option.label}
                  </label>
                ))}
              </div>
            </fieldset>

            <fieldset className="survey-fieldset">
              <legend>3. ¿Pudiste completar lo que querías hacer (por ejemplo, pedir un servicio)?</legend>
              <div className="survey-chips">
                {TASK_OPTIONS.map((option) => (
                  <label key={option.value} className="survey-chip">
                    <input
                      type="radio"
                      name="survey-task"
                      checked={task === option.value}
                      onChange={() => setTask(option.value)}
                    />
                    {option.label}
                  </label>
                ))}
              </div>
            </fieldset>

            <fieldset className="survey-fieldset">
              <legend>4. En general, ¿qué tan satisfecho(a) quedaste? (1 = nada, 5 = muy satisfecho)</legend>
              <div className="survey-scale" role="radiogroup" aria-label="Satisfacción general">
                {[1, 2, 3, 4, 5].map((value) => (
                  <label key={value} className={`survey-scale-dot${satisfaction === value ? ' is-on' : ''}`}>
                    <input
                      type="radio"
                      name="survey-satisfaction"
                      checked={satisfaction === value}
                      onChange={() => setSatisfaction(value)}
                    />
                    {value}
                  </label>
                ))}
              </div>
            </fieldset>

            <fieldset className="survey-fieldset">
              <legend>
                5. Marca qué tan de acuerdo estás (1 = muy en desacuerdo, 5 = muy de acuerdo)
              </legend>
              <ol className="survey-sus">
                {SUS_ITEMS.map((item, index) => (
                  <li key={item}>
                    <span className="survey-sus-text">{item}</span>
                    <div className="survey-scale" role="radiogroup" aria-label={`Afirmación ${index + 1}`}>
                      {[1, 2, 3, 4, 5].map((value) => (
                        <label
                          key={value}
                          title={SUS_SCALE_LABELS[value - 1]}
                          className={`survey-scale-dot${sus[index] === value ? ' is-on' : ''}`}
                        >
                          <input
                            type="radio"
                            name={`survey-sus-${index}`}
                            checked={sus[index] === value}
                            onChange={() =>
                              setSus((current) => current.map((v, i) => (i === index ? value : v)))
                            }
                          />
                          {value}
                        </label>
                      ))}
                    </div>
                  </li>
                ))}
              </ol>
            </fieldset>

            <label className="survey-label" htmlFor="survey-worked">6. ¿Qué te resultó más claro o útil?</label>
            <textarea
              id="survey-worked"
              className="auth-modal-input survey-textarea"
              value={worked}
              maxLength={1000}
              onChange={(event) => setWorked(event.target.value)}
            />
            <label className="survey-label" htmlFor="survey-improve">7. ¿Qué mejorarías?</label>
            <textarea
              id="survey-improve"
              className="auth-modal-input survey-textarea"
              value={improve}
              maxLength={1000}
              onChange={(event) => setImprove(event.target.value)}
            />

            {error ? (
              <p className="toast-error" role="alert">
                {error}
              </p>
            ) : null}
            <button type="submit" className="btn-primary auth-modal-submit" disabled={sending}>
              {sending ? 'Enviando…' : 'Enviar encuesta'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
