-- Auditoría 2026-10-05 (P1).
-- perfiles_publicos_por_ids devolvía nombre, rol y foto de CUALQUIER perfil a cualquier
-- usuario con sesión, con solo conocer su id. La app lo usa para fichas de profesionales y
-- para el nombre de quien dejó una reseña. Ahora solo devuelve:
--   * el propio perfil y, para un admin, cualquiera;
--   * profesionales (su ficha es pública en el catálogo);
--   * autores de una calificación (su nombre ya sale en las reseñas públicas);
--   * la contraparte de un trabajo compartido.

CREATE OR REPLACE FUNCTION public.perfiles_publicos_por_ids(p_ids uuid[])
RETURNS TABLE(id uuid, nombre text, rol text, ruta_foto_perfil text)
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT p.id, p.nombre, p.rol, p.ruta_foto_perfil
  FROM public.perfiles p
  WHERE auth.uid() IS NOT NULL
    AND p.id = ANY(COALESCE(p_ids, ARRAY[]::uuid[]))
    AND (
      p.id = auth.uid()
      OR public.is_admin()
      OR lower(COALESCE(p.rol, '')) IN ('trabajador', 'worker', 'especialista', 'specialist')
      OR EXISTS (
        SELECT 1 FROM public.calificaciones c
        WHERE c.id_usuario = p.id
      )
      OR EXISTS (
        SELECT 1 FROM public.trabajos t
        WHERE (t.id_usuario = auth.uid() AND t.id_trabajador = p.id)
           OR (t.id_trabajador = auth.uid() AND t.id_usuario = p.id)
      )
    )
  LIMIT 200;
$function$;

REVOKE ALL ON FUNCTION public.perfiles_publicos_por_ids(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.perfiles_publicos_por_ids(uuid[]) TO authenticated, service_role;
