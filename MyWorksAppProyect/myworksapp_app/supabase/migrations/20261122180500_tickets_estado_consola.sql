-- La consola responde tickets con pendiente, respondido y resuelto.
-- El chequeo viejo solo aceptaba Pending y Resolved, así que la respuesta
-- no podía guardarse. No aplicar en el proyecto remoto.

ALTER TABLE public.tickets_soporte DROP CONSTRAINT IF EXISTS tickets_status_check;
ALTER TABLE public.tickets_soporte DROP CONSTRAINT IF EXISTS tickets_soporte_estado_chk;
ALTER TABLE public.tickets_soporte
  ADD CONSTRAINT tickets_soporte_estado_chk
  CHECK (
    estado IS NULL
    OR estado IN ('pendiente', 'respondido', 'resuelto', 'Pending', 'Resolved')
  );
