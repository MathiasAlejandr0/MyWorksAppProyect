-- =============================================================================
-- Seed catálogo servicios + grants marketplace (anon puede ver oficios)
-- Aplicar COMPLETO en SQL Editor tras 04 (rename) y 05 (RLS).
-- Idempotente.
-- =============================================================================

BEGIN;

-- Catálogo base (INSERT solo si falta la categoría)
INSERT INTO public.servicios (
  id, nombre, descripcion, categoria, activo,
  requiere_certificacion, modelo_precio, aviso_legal,
  creado_en, actualizado_en
)
SELECT
  v.id,
  v.nombre,
  v.descripcion,
  v.categoria,
  1,
  v.requiere_cert,
  v.modelo_precio,
  v.aviso_legal,
  to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US'),
  to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
FROM (
  VALUES
    ('svc-plomeria', 'plomeria', 'Gasfitería y plomería', 'Reparaciones e instalaciones de agua y gas.', 0, 'por_hora', 'Trabajos de gas requieren certificación SEC cuando aplique.'),
    ('svc-electricidad', 'electricidad', 'Electricidad domiciliaria', 'Instalaciones y fallas eléctricas en hogar.', 1, 'por_hora', 'Instalaciones eléctricas deben cumplir normativa SEC.'),
    ('svc-limpieza', 'limpieza', 'Limpieza e higiene', 'Limpieza de hogares y espacios.', 0, 'fijo', NULL),
    ('svc-ensamblaje', 'ensamblaje', 'Armado de muebles', 'Ensamblaje de muebles y estructuras livianas.', 0, 'fijo', NULL),
    ('svc-soporte_tecnico', 'soporte_tecnico', 'Soporte técnico', 'PCs, WiFi e impresoras a domicilio.', 0, 'por_hora', NULL),
    ('svc-jardinera', 'jardinera', 'Jardinería y poda', 'Mantención de jardines y áreas verdes.', 0, 'por_hora', NULL),
    ('svc-mudanza', 'mudanza', 'Mudanzas y fletes', 'Traslados y ayuda de carga.', 0, 'fijo', NULL),
    ('svc-construccion', 'construccion', 'Construcción y albañilería', 'Obras menores y reparaciones estructurales.', 0, 'por_hora', NULL)
) AS v(id, categoria, nombre, descripcion, requiere_cert, modelo_precio, aviso_legal)
WHERE NOT EXISTS (
  SELECT 1 FROM public.servicios s WHERE s.categoria = v.categoria
);

-- Nombres ES por si ya existían filas
UPDATE public.servicios SET
  nombre = CASE categoria
    WHEN 'plomeria' THEN 'Gasfitería y plomería'
    WHEN 'electricidad' THEN 'Electricidad domiciliaria'
    WHEN 'limpieza' THEN 'Limpieza e higiene'
    WHEN 'ensamblaje' THEN 'Armado de muebles'
    WHEN 'soporte_tecnico' THEN 'Soporte técnico'
    WHEN 'jardinera' THEN 'Jardinería y poda'
    WHEN 'mudanza' THEN 'Mudanzas y fletes'
    WHEN 'construccion' THEN 'Construcción y albañilería'
    ELSE nombre
  END,
  descripcion = COALESCE(descripcion, 'Servicio profesional en Chile'),
  activo = COALESCE(activo, 1)
WHERE categoria IN (
  'plomeria','electricidad','limpieza','ensamblaje','soporte_tecnico','jardinera','mudanza','construccion'
);

-- Lectura pública del marketplace (catálogo + perfiles profesionales)
DROP POLICY IF EXISTS servicios_select ON public.servicios;
CREATE POLICY servicios_select ON public.servicios
  FOR SELECT TO anon, authenticated
  USING (COALESCE(activo, 1) = 1);

DROP POLICY IF EXISTS servicios_select_admin ON public.servicios;
CREATE POLICY servicios_select_admin ON public.servicios
  FOR SELECT TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS trabajadores_select ON public.trabajadores;
CREATE POLICY trabajadores_select ON public.trabajadores
  FOR SELECT TO anon, authenticated
  USING (true);

-- Grants mínimos por si el rename dejó tablas sin privilegios API
GRANT SELECT ON TABLE public.servicios TO anon, authenticated;
GRANT SELECT ON TABLE public.trabajadores TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.pagos TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.mensajes TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.disputas TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.trabajos TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.perfiles TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.notificaciones TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.calificaciones TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.propuestas_cotizacion TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.ordenes_cambio TO authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.fotos_trabajo TO authenticated;
GRANT SELECT ON TABLE public.tickets_soporte TO authenticated;
GRANT INSERT, UPDATE ON TABLE public.tickets_soporte TO authenticated;

COMMIT;
