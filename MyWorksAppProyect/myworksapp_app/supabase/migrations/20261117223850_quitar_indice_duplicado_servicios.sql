-- servicios_categoria_idx repetía idx_servicios_categoria (mismo índice sobre servicios.categoria). Se deja el original.
DROP INDEX IF EXISTS public.servicios_categoria_idx;
