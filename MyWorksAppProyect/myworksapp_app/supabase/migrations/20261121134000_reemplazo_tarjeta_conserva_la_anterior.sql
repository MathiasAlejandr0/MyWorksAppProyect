-- El reemplazo de tarjeta guarda la inscripción vigente hasta que la nueva
-- termina. Si la persona sale, se puede volver a la anterior.
ALTER TABLE public.metodos_pago_oneclick
  ADD COLUMN IF NOT EXISTS tbk_user_prev text,
  ADD COLUMN IF NOT EXISTS username_prev text,
  ADD COLUMN IF NOT EXISTS tipo_tarjeta_prev text,
  ADD COLUMN IF NOT EXISTS ultimos4_prev text;

COMMENT ON COLUMN public.metodos_pago_oneclick.tbk_user_prev IS
  'Inscripción vigente mientras se reemplaza la tarjeta. Se borra al terminar o al volver atrás.';
