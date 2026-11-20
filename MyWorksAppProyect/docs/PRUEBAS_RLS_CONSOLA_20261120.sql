-- Pruebas de la bitácora y de los RPC de consola.
-- Correr en una base LOCAL después de aplicar 20261120130000_auditoria_consola.sql.
-- No ejecutar contra la base remota. No crea datos de negocio: solo intenta
-- privilegios y espera que fallen.
--
-- Roles esperados (créalos en local antes, con JWT o SET request.jwt.claim):
--   anon, authenticated sin rol de consola, soporte, qa,
--   administrador con aal1, administrador suspendido, administrador aal2 activo.
-- Solo el último puede ejecutar acciones de admin.

-- 1) authenticated no inserta, no actualiza y no borra la bitácora.
-- Reemplaza el rol de sesión según tu local. Con el rol de tabla sin GRANT:
SET ROLE authenticated;
DO $$
BEGIN
  BEGIN
    INSERT INTO public.auditoria_consola (accion, entidad, motivo)
    VALUES ('liberar_pago', 'pagos', 'intento directo que debe fallar');
    RAISE EXCEPTION 'FALLO: authenticated insertó en auditoria_consola';
  EXCEPTION
    WHEN insufficient_privilege OR check_violation OR raise_exception THEN
      IF SQLERRM LIKE 'FALLO:%' THEN RAISE; END IF;
  END;
END $$;
RESET ROLE;

-- 2) Aunque un superusuario intente insertar directo, el trigger lo rechaza.
DO $$
BEGIN
  BEGIN
    INSERT INTO public.auditoria_consola (accion, entidad, motivo)
    VALUES ('liberar_pago', 'pagos', 'sin pasar por registrar_auditoria');
    RAISE EXCEPTION 'FALLO: el insert directo no fue rechazado';
  EXCEPTION
    WHEN others THEN
      IF SQLERRM NOT LIKE '%solo registrar_auditoria%' THEN
        RAISE EXCEPTION 'FALLO inesperado: %', SQLERRM;
      END IF;
  END;
  BEGIN
    UPDATE public.auditoria_consola SET motivo = 'tocado' WHERE false;
  EXCEPTION
    WHEN others THEN
      IF SQLERRM NOT LIKE '%inmutable%' AND SQLERRM NOT LIKE '%0 rows%' THEN
        NULL;
      END IF;
  END;
END $$;

-- 3) Matriz (ejecutar cada bloque con el JWT correspondiente en local).
--    anon                          -> consola_resumen_periodo forbidden / sin execute
--    authenticated sin rol         -> forbidden
--    soporte aal2                  -> resumen sin bloque financiero (financiero null)
--    qa aal2                       -> resumen sin financiero; cron legible; sin moderar dinero
--    admin aal1                    -> is_admin() false -> forbidden en fijar_verificacion
--    admin suspendido              -> is_admin() false
--    admin aal2 activo             -> resumen con financiero y registrar vía RPC
--
-- Control de cifras (admin aal2), diferencia esperada 0 contra:
--   SELECT COALESCE(sum(round(monto)),0)
--   FROM pagos
--   WHERE estado IN ('retenido','liberado')
--     AND texto_a_timestamptz(creado_en) >= :desde
--     AND texto_a_timestamptz(creado_en) < :hasta;
-- Ese total es gmv_clp de consola_resumen_periodo(:desde, :hasta).
-- No hay fecha_completado: el resumen no informa trabajos completados.
