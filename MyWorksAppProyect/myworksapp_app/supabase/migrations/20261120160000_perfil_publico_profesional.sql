-- Perfil público y reseñas (CU-06). No abre la tabla calificaciones a anon.
-- Un profesional demo queda fuera cuando demo_modo no es 1.
-- No está aplicada.

BEGIN;

CREATE OR REPLACE FUNCTION public.perfil_publico_profesional(p_id uuid)
RETURNS TABLE (
  id_usuario uuid,
  nombre text,
  profesion text,
  descripcion text,
  zona_trabajo text,
  radio_servicio_km numeric,
  tarifa_visita numeric,
  ruta_foto_perfil text,
  verificado boolean,
  calificacion numeric,
  n_calificaciones integer,
  trabajos_completados integer,
  es_elite boolean,
  categoria text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    t.id_usuario,
    p.nombre,
    t.profesion,
    t.descripcion,
    t.zona_trabajo,
    t.radio_servicio_km,
    t.tarifa_visita,
    p.ruta_foto_perfil,
    t.estado_verificacion = 'verificado',
    s.calificacion,
    s.n_calificaciones,
    s.trabajos_completados,
    s.es_elite,
    (
      SELECT min(ts.categoria_servicio)
      FROM public.trabajador_servicios ts
      WHERE ts.id_trabajador = t.id_usuario
    )
  FROM public.trabajadores t
  JOIN public.perfiles p ON p.id = t.id_usuario
  JOIN LATERAL public.stats_profesional(t.id_usuario) AS s ON true
  WHERE t.id_usuario = p_id
    AND coalesce(t.disponible, 0) = 1
    AND coalesce(t.precios_configurados, 0) = 1
    AND t.estado_verificacion = 'verificado'
    AND public.catalogo_muestra_profesional(t.es_demo);
$$;

REVOKE ALL ON FUNCTION public.perfil_publico_profesional(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.perfil_publico_profesional(uuid) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.horario_publico_profesional(p_id uuid)
RETURNS TABLE (
  dia_semana integer,
  hora_inicio text,
  hora_fin text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT h.dia_semana, h.hora_inicio::text, h.hora_fin::text
  FROM public.trabajador_horarios h
  WHERE h.id_usuario = p_id
    AND h.activo IS DISTINCT FROM false
    AND EXISTS (
      SELECT 1
      FROM public.perfil_publico_profesional(p_id) perfil
      WHERE perfil.id_usuario = p_id
    )
  ORDER BY h.dia_semana;
$$;

REVOKE ALL ON FUNCTION public.horario_publico_profesional(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.horario_publico_profesional(uuid) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.resenas_publicas_profesional(p_id uuid)
RETURNS TABLE (
  nota integer,
  comentario text,
  fecha text,
  nombre_corto text
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT
    c.puntaje,
    CASE
      WHEN c.comentario IS NULL OR btrim(c.comentario) = '' THEN NULL
      WHEN public.texto_tiene_contacto(c.comentario) THEN NULL
      ELSE left(btrim(c.comentario), 500)
    END,
    c.creado_en,
    CASE
      WHEN btrim(coalesce(autor.nombre, '')) = '' THEN 'Cliente'
      WHEN split_part(btrim(autor.nombre), ' ', 2) = '' THEN split_part(btrim(autor.nombre), ' ', 1)
      ELSE split_part(btrim(autor.nombre), ' ', 1)
        || ' '
        || left(split_part(btrim(autor.nombre), ' ', 2), 1)
        || '.'
    END
  FROM public.calificaciones c
  LEFT JOIN public.perfiles autor ON autor.id = c.id_usuario
  WHERE c.id_calificado = p_id
    AND c.direccion = 'cliente_a_trabajador'
    AND c.estado_revision = 'vigente'
    AND EXISTS (
      SELECT 1
      FROM public.perfil_publico_profesional(p_id) perfil
      WHERE perfil.id_usuario = p_id
    )
  ORDER BY c.creado_en DESC
  LIMIT 30;
$$;

REVOKE ALL ON FUNCTION public.resenas_publicas_profesional(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resenas_publicas_profesional(uuid) TO anon, authenticated;

COMMENT ON FUNCTION public.resenas_publicas_profesional(uuid) IS
  'Reseñas vigentes del cliente al profesional: nota, comentario sin datos de contacto, fecha y nombre abreviado.';

COMMIT;
