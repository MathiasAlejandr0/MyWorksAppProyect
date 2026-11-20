-- generate_series(time, time, interval) no existe en Postgres. Con la versión
-- de 20261118230000, cada INSERT en trabajadores falla y no se puede dar de alta
-- a un profesional. Se generan las horas con timestamp y se convierten a time.

BEGIN;

CREATE OR REPLACE FUNCTION public.trabajador_horarios_desde_alta()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  PERFORM public._asegurar_ventanas_horario(NEW.id_usuario);

  INSERT INTO public.trabajador_horas_publicadas (id_usuario, dia_semana, hora)
  SELECT NEW.id_usuario, d.dia, h.ts::time
  FROM generate_series(1, 5) AS d(dia)
  CROSS JOIN generate_series(
    timestamp '2000-01-01 09:00',
    timestamp '2000-01-01 17:00',
    interval '1 hour'
  ) AS h(ts)
  WHERE NOT EXISTS (
    SELECT 1
    FROM public.trabajador_horas_publicadas p
    WHERE p.id_usuario = NEW.id_usuario
  );

  UPDATE public.trabajadores
  SET usa_horario = true
  WHERE id_usuario = NEW.id_usuario
    AND usa_horario IS NOT TRUE;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.trabajador_horarios_desde_alta() FROM PUBLIC, anon, authenticated;

COMMIT;
