-- Consola de escritorio para colaboradores invitados con rol "soporte" o "qa".
--
-- Mínimo privilegio:
--   * administrador: todo lo que ya tenía (is_admin() no cambia).
--   * soporte: ve la cola de disputas que requieren una persona (con nombre
--     de las partes y monto retenido, sin correos ni direcciones), ve la
--     evidencia fotográfica y deja notas a las partes. NO libera ni devuelve
--     pagos, no verifica profesionales, no invita ni ve métricas de negocio.
--   * qa: ve la misma cola en solo lectura (sin evidencia ni notas) para
--     revisar la calidad del servicio.
-- Las acciones de dinero, verificación, invitaciones y métricas siguen
-- protegidas por is_admin() / rol administrador en la base y en las Edge
-- Functions. Si app_config.admin_requiere_aal2 = '1', soporte y qa también
-- deben entrar con segundo factor (aal2), igual que un administrador.
-- No crea ni modifica filas.

BEGIN;

CREATE OR REPLACE FUNCTION public.rol_consola()
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT p.rol
  FROM public.perfiles p
  WHERE p.id = auth.uid()
    AND p.rol IN ('administrador', 'soporte', 'qa')
    AND p.estado_cuenta IN ('activo', 'active')
    AND (
      COALESCE(
        (SELECT c.valor FROM public.app_config c WHERE c.clave = 'admin_requiere_aal2'),
        '0'
      ) IS DISTINCT FROM '1'
      OR COALESCE(auth.jwt()->>'aal', '') = 'aal2'
    );
$$;
REVOKE ALL ON FUNCTION public.rol_consola() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.rol_consola() TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.consola_disputas_abiertas()
RETURNS TABLE (
  id text,
  id_trabajo text,
  motivo text,
  descripcion text,
  estado text,
  decision_sugerida text,
  motivo_regla text,
  vence_en timestamptz,
  creado_en text,
  nombre_cliente text,
  nombre_profesional text,
  monto_retenido numeric
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF public.rol_consola() IS NULL THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT
    d.id::text,
    d.id_trabajo::text,
    d.motivo,
    d.descripcion,
    d.estado,
    d.decision_sugerida,
    d.motivo_regla,
    d.vence_en,
    d.creado_en::text,
    COALESCE(pc.nombre, 'Cliente'),
    COALESCE(pp.nombre, 'Profesional'),
    COALESCE((
      SELECT max(pg.monto)
      FROM public.pagos pg
      WHERE pg.id_trabajo = d.id_trabajo
        AND pg.estado IN ('autorizado', 'retenido', 'pendiente')
    ), 0)
  FROM public.disputas d
  JOIN public.trabajos t ON t.id::text = d.id_trabajo::text
  LEFT JOIN public.perfiles pc ON pc.id = t.id_usuario
  LEFT JOIN public.perfiles pp ON pp.id = t.id_trabajador
  WHERE d.estado IN ('requiere_humano', 'reembolso_pendiente')
  ORDER BY d.creado_en DESC
  LIMIT 200;
END;
$$;
REVOKE ALL ON FUNCTION public.consola_disputas_abiertas() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.consola_disputas_abiertas() TO authenticated, service_role;

-- Evidencia: administrador o soporte (qa no ve fotos del domicilio).
CREATE OR REPLACE FUNCTION public.evidencia_disputa(p_id_disputa text)
RETURNS TABLE(id text, imagen_base64 text)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_admin() AND public.rol_consola() IS DISTINCT FROM 'soporte' THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  RETURN QUERY
  SELECT f.id::text, encode(f.imagen_webp, 'base64')
  FROM public.fotos_trabajo f
  JOIN public.disputas d ON d.id_trabajo::text = f.id_trabajo::text
  WHERE d.id::text = btrim(p_id_disputa)
    AND f.imagen_webp IS NOT NULL
    AND octet_length(f.imagen_webp) >= 12
  ORDER BY f.creado_en
  LIMIT 4;
END;
$function$;

-- Nota de soporte a las partes de una disputa activa (queda en el hilo).
CREATE OR REPLACE FUNCTION public.soporte_comentar_disputa(p_id text, p_comentario text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_rol text := public.rol_consola();
  v_row public.disputas%ROWTYPE;
  v_nota text := left(btrim(COALESCE(p_comentario, '')), 1000);
BEGIN
  IF v_rol IS NULL OR v_rol NOT IN ('administrador', 'soporte') THEN
    RAISE EXCEPTION 'forbidden';
  END IF;
  IF v_nota = '' THEN
    RAISE EXCEPTION 'El comentario es requerido';
  END IF;

  SELECT * INTO v_row FROM public.disputas WHERE id::text = btrim(p_id) FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Disputa no encontrada';
  END IF;
  IF NOT public.disputa_esta_activa(v_row.estado) THEN
    RAISE EXCEPTION 'La disputa ya fue resuelta';
  END IF;

  INSERT INTO public.disputa_mensajes (id, id_disputa, id_autor, cuerpo)
  VALUES (gen_random_uuid()::text, v_row.id, v_uid, 'Soporte: ' || v_nota);

  UPDATE public.disputas
  SET descripcion = left(
        concat_ws(
          E'\n',
          NULLIF(v_row.descripcion, ''),
          concat(to_char(now() AT TIME ZONE 'America/Santiago', 'DD/MM HH24:MI'), ' · Soporte: ', v_nota)
        ),
        4000
      ),
      actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  WHERE id::text = v_row.id::text;
END;
$$;
REVOKE ALL ON FUNCTION public.soporte_comentar_disputa(text, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.soporte_comentar_disputa(text, text) TO authenticated, service_role;

-- Un perfil nuevo creado por el propio usuario nunca nace con rol de
-- consola: esos roles solo los asigna invitar-colaborador (service_role) o
-- un administrador. handle_new_user ya solo crea usuario/trabajador.
CREATE OR REPLACE FUNCTION public.perfiles_rol_inicial_seguro()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
BEGIN
  -- SECURITY INVOKER a propósito: current_user es quien inserta.
  IF NEW.rol IN ('administrador', 'soporte', 'qa')
     AND NOT (
       public.is_admin()
       OR COALESCE(auth.role(), '') = 'service_role'
       OR current_user IN ('postgres', 'supabase_admin', 'supabase_auth_admin')
     ) THEN
    RAISE EXCEPTION 'No puedes crear un perfil con ese rol';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION public.perfiles_rol_inicial_seguro() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS perfiles_rol_inicial_seguro ON public.perfiles;
CREATE TRIGGER perfiles_rol_inicial_seguro
  BEFORE INSERT ON public.perfiles
  FOR EACH ROW
  EXECUTE FUNCTION public.perfiles_rol_inicial_seguro();

COMMIT;
