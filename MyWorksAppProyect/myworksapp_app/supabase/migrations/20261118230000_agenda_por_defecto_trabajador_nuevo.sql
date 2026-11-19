-- El alta ya crea las 7 ventanas. Sin horas en trabajador_horas_publicadas
-- el cliente no puede agendar. Lunes a viernes publican 09:00–17:00.

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
  SELECT NEW.id_usuario, d.dia, h.hora
  FROM generate_series(1, 5) AS d(dia)
  CROSS JOIN generate_series(time '09:00', time '17:00', interval '1 hour') AS h(hora)
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
