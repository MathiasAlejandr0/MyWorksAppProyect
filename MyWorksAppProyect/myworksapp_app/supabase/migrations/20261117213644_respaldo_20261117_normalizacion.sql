-- Respaldo previo a la normalización del 17-11-2026 (trabajadores, horarios, ofertas, liquidaciones, cotizaciones y encuestas).
CREATE SCHEMA IF NOT EXISTS backup_20261117;
REVOKE ALL ON SCHEMA backup_20261117 FROM PUBLIC, anon, authenticated;
CREATE TABLE backup_20261117.trabajadores AS TABLE public.trabajadores;
CREATE TABLE backup_20261117.trabajador_horarios AS TABLE public.trabajador_horarios;
CREATE TABLE backup_20261117.trabajador_precios AS TABLE public.trabajador_precios;
CREATE TABLE backup_20261117.trabajador_servicios AS TABLE public.trabajador_servicios;
CREATE TABLE backup_20261117.trabajador_servicios_extra AS TABLE public.trabajador_servicios_extra;
CREATE TABLE backup_20261117.servicios AS TABLE public.servicios;
CREATE TABLE backup_20261117.liquidaciones AS TABLE public.liquidaciones;
CREATE TABLE backup_20261117.propuestas_cotizacion AS TABLE public.propuestas_cotizacion;
CREATE TABLE backup_20261117.encuestas_testing AS TABLE public.encuestas_testing;
DO $$ DECLARE r record; BEGIN FOR r IN SELECT tablename FROM pg_tables WHERE schemaname='backup_20261117' LOOP EXECUTE format('ALTER TABLE backup_20261117.%I ENABLE ROW LEVEL SECURITY', r.tablename); EXECUTE format('REVOKE ALL ON backup_20261117.%I FROM PUBLIC, anon, authenticated', r.tablename); END LOOP; END $$;
