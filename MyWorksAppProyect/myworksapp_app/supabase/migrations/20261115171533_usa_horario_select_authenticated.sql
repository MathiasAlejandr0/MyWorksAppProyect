-- 20261115000001 dejó fuera usa_horario de los GRANT SELECT por columna de
-- trabajadores. La web (reserva rápida) y el repositorio de agenda de Flutter
-- leen esa columna con la sesión del usuario y reciben 403/42501.
-- Es un booleano no sensible (si el profesional usa agenda publicada); la
-- política RLS de SELECT sigue mandando sobre qué filas se ven.
BEGIN;
GRANT SELECT (usa_horario) ON public.trabajadores TO authenticated;
COMMIT;
