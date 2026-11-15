-- Aún NO aplicada en wxqrfcqifkfgawrnqmnj.
--
-- Un cliente con sesión no podía crear pedidos: el INSERT en trabajos
-- respondía 42501 "permission denied for function minuto_utc".
--
-- El índice único trabajos_trabajador_minuto_activo_uidx usa
-- public.minuto_utc(fecha_programada), y minuto_utc llama a
-- public.texto_a_timestamptz. Postgres evalúa la expresión del índice con
-- el rol que inserta, así que authenticated necesita EXECUTE sobre las dos.
-- Ambas son funciones SQL inmutables, sin SECURITY DEFINER y sin acceso a
-- tablas: dar EXECUTE no expone datos.
--
-- Origen: 20261108000003_auditoria_horarios_chat revocó EXECUTE de
-- minuto_utc a authenticated después de crear el índice.
-- anon sigue sin EXECUTE: no puede insertar en trabajos.

DO $$
BEGIN
  IF to_regprocedure('public.minuto_utc(text)') IS NOT NULL THEN
    GRANT EXECUTE ON FUNCTION public.minuto_utc(text) TO authenticated;
  END IF;
  IF to_regprocedure('public.texto_a_timestamptz(text)') IS NOT NULL THEN
    GRANT EXECUTE ON FUNCTION public.texto_a_timestamptz(text) TO authenticated;
  END IF;
END $$;
