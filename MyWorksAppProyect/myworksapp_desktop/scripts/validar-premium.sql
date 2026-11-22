-- Arnés local. No es una migración y no toca producción.
-- Crea el mínimo para ejecutar las funciones nuevas con datos sintéticos.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS auth;
CREATE OR REPLACE FUNCTION auth.uid() RETURNS uuid
LANGUAGE sql STABLE AS $$ SELECT '11111111-1111-1111-1111-111111111111'::uuid $$;

CREATE OR REPLACE FUNCTION public.rol_consola() RETURNS text
LANGUAGE sql STABLE AS $$ SELECT 'administrador'::text $$;
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS boolean
LANGUAGE sql STABLE AS $$ SELECT true $$;
CREATE OR REPLACE FUNCTION public.texto_a_timestamptz(p_valor text) RETURNS timestamptz
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
  IF p_valor IS NULL OR btrim(p_valor) = '' THEN RETURN NULL; END IF;
  RETURN p_valor::timestamptz;
EXCEPTION WHEN others THEN RETURN NULL;
END $$;
CREATE OR REPLACE FUNCTION public.disputa_esta_activa(p_estado text) RETURNS boolean
LANGUAGE sql IMMUTABLE AS $$
  SELECT COALESCE(p_estado, '') IN ('abierta', 'en_revision', 'requiere_humano', 'reembolso_pendiente')
$$;
CREATE OR REPLACE FUNCTION public.comision_servicio_clp(p_bruto numeric) RETURNS integer
LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE WHEN COALESCE(p_bruto, 0) <= 0 THEN 0
    ELSE LEAST(round(p_bruto)::integer, GREATEST(1000, round(p_bruto * 0.05)::integer)) END
$$;

DO $$ BEGIN
  CREATE TYPE public.accion_auditoria_consola AS ENUM ('nota_interna');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.perfiles (
  id uuid PRIMARY KEY,
  nombre text,
  rol text,
  correo text,
  creado_en text,
  estado_cuenta text
);
CREATE TABLE IF NOT EXISTS public.comunas (
  id text PRIMARY KEY,
  nombre text,
  activa integer
);
CREATE TABLE IF NOT EXISTS public.servicios (
  id text PRIMARY KEY,
  nombre text,
  categoria text,
  activo integer
);
CREATE TABLE IF NOT EXISTS public.trabajos (
  id text PRIMARY KEY,
  estado text,
  creado_en text,
  actualizado_en timestamptz DEFAULT now(),
  id_usuario uuid,
  id_trabajador uuid,
  id_servicio text,
  id_comuna text,
  direccion text,
  descripcion text
);
CREATE TABLE IF NOT EXISTS public.pagos (
  id text PRIMARY KEY,
  monto numeric,
  tipo_pago text,
  estado text,
  creado_en text,
  reembolsado_en text,
  id_trabajo text
);
CREATE TABLE IF NOT EXISTS public.calificaciones (
  id text PRIMARY KEY,
  puntaje numeric,
  comentario text,
  estado_revision text,
  creado_en text,
  id_calificado uuid,
  id_usuario uuid,
  id_trabajo text
);
CREATE TABLE IF NOT EXISTS public.disputas (
  id text PRIMARY KEY,
  estado text,
  creado_en text,
  actualizado_en timestamptz DEFAULT now(),
  resuelta_en text,
  motivo text,
  descripcion text,
  resolucion text,
  vence_en timestamptz,
  id_trabajo text
);
CREATE TABLE IF NOT EXISTS public.cancelaciones_trabajo (
  id text PRIMARY KEY,
  motivo text,
  cancelado_en text,
  id_trabajo text
);
CREATE TABLE IF NOT EXISTS public.trabajadores (
  id_usuario uuid PRIMARY KEY,
  estado_verificacion text,
  calificacion numeric,
  profesion text,
  id_comuna text
);
CREATE TABLE IF NOT EXISTS public.tickets_soporte (
  id text PRIMARY KEY,
  estado text,
  creado_en text,
  asunto text
);
CREATE TABLE IF NOT EXISTS public.ticket_mensajes (
  id uuid PRIMARY KEY,
  id_ticket text,
  cuerpo text,
  creado_en timestamptz
);
CREATE TABLE IF NOT EXISTS public.reportes (
  id text PRIMARY KEY,
  estado text,
  motivo text,
  creado_en text
);
CREATE TABLE IF NOT EXISTS public.notificaciones (
  id text PRIMARY KEY,
  leido integer,
  creado_en text,
  tipo text,
  titulo text,
  cuerpo text,
  id_usuario uuid
);
CREATE TABLE IF NOT EXISTS public.incidentes_seguridad (
  id uuid PRIMARY KEY,
  estado text,
  severidad text,
  tipo text,
  creado_en timestamptz,
  resumen text
);
CREATE TABLE IF NOT EXISTS public.eventos_acceso (
  tipo text,
  creado_en timestamptz
);
CREATE TABLE IF NOT EXISTS public.auditoria_consola (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creado_en timestamptz DEFAULT now(),
  id_actor uuid,
  accion public.accion_auditoria_consola,
  entidad text,
  rol_actor text
);
CREATE TABLE IF NOT EXISTS public.app_config (
  clave text PRIMARY KEY,
  valor text
);
CREATE TABLE IF NOT EXISTS public.banderas_funcionalidad (
  id text PRIMARY KEY,
  habilitada integer,
  nombre_bandera text
);
