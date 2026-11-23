-- La web pública entra como anon. La política existente solo deja insertar
-- a authenticated. Estos tres nombres son los únicos que puede escribir anon.
DROP POLICY IF EXISTS analitica_insert_anon ON public.eventos_analitica;
CREATE POLICY analitica_insert_anon ON public.eventos_analitica
  FOR INSERT
  TO anon
  WITH CHECK (
    id_usuario IS NULL
    AND nombre_evento = ANY (ARRAY[
      'vio_ficha_profesional'::text,
      'eligio_hora_reserva'::text,
      'confirmo_pedido'::text
    ])
    AND (metadatos IS NULL OR char_length(metadatos) <= 500)
  );

GRANT INSERT ON TABLE public.eventos_analitica TO anon;
