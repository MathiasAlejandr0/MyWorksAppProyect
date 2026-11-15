-- Cierra el UNIQUE que 00003 omitió: deja un trabajo activo por
-- profesional y minuto, cancela el resto y crea el índice.

BEGIN;

WITH ranking AS (
  SELECT
    t.id,
    t.estado,
    row_number() OVER (
      PARTITION BY t.id_trabajador, public.minuto_utc(t.fecha_programada::text)
      ORDER BY
        CASE t.estado
          WHEN 'en_curso' THEN 1
          WHEN 'en_camino' THEN 2
          WHEN 'esperando_aprobacion_cliente' THEN 3
          WHEN 'aceptado' THEN 4
          WHEN 'pagado' THEN 5
          WHEN 'confirmado' THEN 6
          WHEN 'pendiente' THEN 7
          WHEN 'esperando_cotizaciones' THEN 8
          WHEN 'esperando_pago' THEN 9
          ELSE 10
        END,
        t.creado_en ASC NULLS LAST,
        t.id ASC
    ) AS rn
  FROM public.trabajos t
  WHERE t.fecha_programada IS NOT NULL
    AND t.id_trabajador IS NOT NULL
    AND t.estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio')
),
extras AS (
  SELECT id, estado
  FROM ranking
  WHERE rn > 1
),
cancelados AS (
  UPDATE public.trabajos t
  SET
    estado = CASE
      WHEN t.estado = 'esperando_pago' THEN 'expirado'
      ELSE 'cancelado'
    END,
    actualizado_en = to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD"T"HH24:MI:SS.US')
  FROM extras x
  WHERE t.id = x.id
  RETURNING t.id
)
UPDATE public.pagos p
SET estado = 'reembolsado'
FROM cancelados c
WHERE p.id_trabajo::text = c.id::text
  AND coalesce(p.tipo_pago, 'principal') = 'principal'
  AND p.estado IN ('pendiente', 'autorizado', 'retenido');

CREATE UNIQUE INDEX IF NOT EXISTS trabajos_trabajador_minuto_activo_uidx
  ON public.trabajos (
    id_trabajador,
    (public.minuto_utc(fecha_programada::text))
  )
  WHERE fecha_programada IS NOT NULL
    AND id_trabajador IS NOT NULL
    AND estado NOT IN ('cancelado', 'expirado', 'completado', 'no_asistio');

COMMIT;
