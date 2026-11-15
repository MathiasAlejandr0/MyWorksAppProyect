-- Push con FCM: tokens de los equipos de cada usuario.
--
-- La app guarda su token con registrar_dispositivo_push() al iniciar sesión
-- y lo borra con quitar_dispositivo_push() al cerrarla. La Edge Function
-- send-push (llamada por un Database Webhook sobre INSERT en notificaciones)
-- lee los tokens con la service role. Ver docs/PUSH_NOTIFICACIONES.md.

BEGIN;

CREATE TABLE IF NOT EXISTS public.dispositivos_push (
  token text PRIMARY KEY,
  id_usuario uuid NOT NULL REFERENCES public.perfiles(id) ON DELETE CASCADE,
  plataforma text NOT NULL DEFAULT 'android'
    CHECK (plataforma IN ('android', 'ios', 'web')),
  creado_en timestamptz NOT NULL DEFAULT now(),
  actualizado_en timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT dispositivos_push_token_largo CHECK (char_length(token) BETWEEN 20 AND 4096)
);

CREATE INDEX IF NOT EXISTS idx_dispositivos_push_usuario
  ON public.dispositivos_push (id_usuario);

ALTER TABLE public.dispositivos_push ENABLE ROW LEVEL SECURITY;

-- Cada usuario ve sus equipos; las escrituras van solo por las RPC.
DROP POLICY IF EXISTS dispositivos_push_select_propios ON public.dispositivos_push;
CREATE POLICY dispositivos_push_select_propios ON public.dispositivos_push
  FOR SELECT TO authenticated
  USING (id_usuario = (SELECT auth.uid()));

REVOKE ALL ON public.dispositivos_push FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.dispositivos_push TO authenticated;
GRANT ALL ON public.dispositivos_push TO service_role;

-- Un token es de un equipo: si otra cuenta inicia sesión en el mismo
-- teléfono, el token pasa a esa cuenta (por eso SECURITY DEFINER).
CREATE OR REPLACE FUNCTION public.registrar_dispositivo_push(
  p_token text,
  p_plataforma text DEFAULT 'android'
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Debes iniciar sesión';
  END IF;
  IF p_token IS NULL OR char_length(p_token) NOT BETWEEN 20 AND 4096 THEN
    RAISE EXCEPTION 'Token de notificaciones no válido';
  END IF;

  INSERT INTO public.dispositivos_push (token, id_usuario, plataforma)
  VALUES (p_token, v_uid, COALESCE(NULLIF(p_plataforma, ''), 'android'))
  ON CONFLICT (token) DO UPDATE
    SET id_usuario = EXCLUDED.id_usuario,
        plataforma = EXCLUDED.plataforma,
        actualizado_en = now();

  -- Tope de equipos por cuenta: se queda con los 10 más recientes.
  DELETE FROM public.dispositivos_push d
  WHERE d.id_usuario = v_uid
    AND d.token IN (
      SELECT token FROM public.dispositivos_push
      WHERE id_usuario = v_uid
      ORDER BY actualizado_en DESC
      OFFSET 10
    );
END;
$$;

CREATE OR REPLACE FUNCTION public.quitar_dispositivo_push(p_token text)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  DELETE FROM public.dispositivos_push
  WHERE token = p_token AND id_usuario = auth.uid();
$$;

REVOKE EXECUTE ON FUNCTION public.registrar_dispositivo_push(text, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.quitar_dispositivo_push(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.registrar_dispositivo_push(text, text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.quitar_dispositivo_push(text) TO authenticated, service_role;

COMMIT;
