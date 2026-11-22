-- id_trabajador y creado_en de liquidaciones son uuid y timestamptz.
-- No aplicar en wxqrfcqifkfgawrnqmnj sin el OK de Mathias.

CREATE OR REPLACE FUNCTION public.evaluar_alertas_ia()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_n integer := 0;
  v_umbral integer;
  v_ventana integer;
  v_fila record;
BEGIN
  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'rafaga_resenas';
  FOR v_fila IN
    SELECT c.id_usuario, count(*) AS n
    FROM public.calificaciones c
    WHERE privado.texto_a_timestamptz(c.creado_en) > now() - make_interval(mins => COALESCE(v_ventana, 60))
      AND c.id_usuario IS NOT NULL
    GROUP BY c.id_usuario
    HAVING count(*) >= COALESCE(v_umbral, 5)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_rafaga_resenas', 'media',
      format('%s reseñas en la ventana', v_fila.n),
      jsonb_build_object('usuario', v_fila.id_usuario, 'cantidad', v_fila.n, 'propuesta', true),
      v_fila.id_usuario
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'cuentas_misma_huella';
  FOR v_fila IN
    SELECT h.device_hash, count(DISTINCT h.user_id) AS n
    FROM public.ia_huellas h
    WHERE h.created_at > now() - make_interval(mins => COALESCE(v_ventana, 1440))
    GROUP BY h.device_hash
    HAVING count(DISTINCT h.user_id) >= COALESCE(v_umbral, 4)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_misma_huella', 'alta',
      format('%s cuentas con el mismo dispositivo', v_fila.n),
      jsonb_build_object('device_hash', left(v_fila.device_hash, 12), 'cantidad', v_fila.n, 'propuesta', true),
      NULL
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'logins_fallidos';
  FOR v_fila IN
    SELECT e.correo_enmascarado, count(*) AS n
    FROM public.eventos_acceso e
    WHERE e.tipo = 'login_fallido'
      AND e.creado_en > now() - make_interval(mins => COALESCE(v_ventana, 15))
    GROUP BY e.correo_enmascarado
    HAVING count(*) >= COALESCE(v_umbral, 5)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_login_fallido', 'alta',
      format('%s accesos fallidos del mismo correo', v_fila.n),
      jsonb_build_object('correo', v_fila.correo_enmascarado, 'cantidad', v_fila.n, 'propuesta', true),
      NULL
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'disputas_serie';
  FOR v_fila IN
    SELECT d.abierta_por, count(*) AS n
    FROM public.disputas d
    WHERE privado.texto_a_timestamptz(d.creado_en) > now() - make_interval(mins => COALESCE(v_ventana, 1440))
    GROUP BY d.abierta_por
    HAVING count(*) >= COALESCE(v_umbral, 3)
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_disputas_serie', 'media',
      format('%s disputas de la misma persona', v_fila.n),
      jsonb_build_object('usuario', v_fila.abierta_por, 'cantidad', v_fila.n, 'propuesta', true),
      v_fila.abierta_por
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  SELECT valor, ventana_minutos INTO v_umbral, v_ventana
  FROM public.umbrales_seguridad WHERE clave = 'banco_antes_retiro';
  FOR v_fila IN
    SELECT b.user_id
    FROM public.ia_cambios_banco b
    JOIN public.liquidaciones l ON l.id_trabajador = b.user_id
    WHERE b.creado_en > now() - interval '7 days'
      AND l.creado_en > b.creado_en
      AND l.creado_en < b.creado_en + make_interval(mins => COALESCE(v_ventana, 1440))
      AND l.estado_transferencia IN ('pendiente', 'transferido')
    LIMIT 1
  LOOP
    PERFORM privado.insertar_incidente_ia(
      'ia_banco_retiro', 'alta',
      'Cambió la cuenta bancaria y hubo un retiro en la ventana',
      jsonb_build_object('usuario', v_fila.user_id, 'propuesta', true, 'bloquea', false),
      v_fila.user_id
    );
    v_n := v_n + 1;
    EXIT;
  END LOOP;

  RETURN v_n;
END;
$$;


REVOKE ALL ON FUNCTION public.evaluar_alertas_ia() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.evaluar_alertas_ia() TO service_role;
