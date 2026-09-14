-- Catálogo / profesiones en español (post-rename)
BEGIN;

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
  descripcion = COALESCE(descripcion, 'Servicio profesional en Chile')
WHERE categoria IN (
  'plomeria','electricidad','limpieza','ensamblaje','soporte_tecnico','jardinera','mudanza','construccion'
);

UPDATE public.trabajadores SET
  profesion = CASE categoria_servicio
    WHEN 'construccion' THEN 'Maestro Constructor'
    WHEN 'plomeria' THEN 'Gasfiter'
    WHEN 'electricidad' THEN 'Electricista'
    WHEN 'limpieza' THEN 'Especialista en Limpieza'
    WHEN 'ensamblaje' THEN 'Armador de Muebles'
    WHEN 'soporte_tecnico' THEN 'Soporte Técnico'
    WHEN 'jardinera' THEN 'Jardinero'
    WHEN 'mudanza' THEN 'Especialista en Mudanzas'
    ELSE profesion
  END
WHERE categoria_servicio IS NOT NULL;

UPDATE public.perfiles SET rol = 'administrador' WHERE correo = 'admin@demo.com' AND rol IS DISTINCT FROM 'administrador';
UPDATE public.perfiles SET rol = 'usuario' WHERE correo = 'usuario@demo.com' AND rol IS DISTINCT FROM 'usuario';

COMMIT;
