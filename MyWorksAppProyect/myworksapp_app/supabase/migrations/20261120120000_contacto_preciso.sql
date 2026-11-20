-- Precisa texto_tiene_contacto y el freno del pago principal.
-- No reescribe 20261119170000: esa migración puede estar aplicada.
--
-- Una red (Facebook, TikTok, Instagram, Telegram, Signal, Discord, fb, insta)
-- cuenta solo con usuario, enlace o @. WhatsApp, «llámame» y un enlace siguen
-- siendo contacto por sí solos: son el canal para salir de la app.
-- Un RUT, una medida o un monto no es un teléfono. El fijo chileno entra
-- con el código de área (65 Puerto Montt, 2 Santiago, y el resto del país).
--
-- El trigger corre en INSERT y en UPDATE. crear_intencion_pago reutiliza
-- una fila pendiente con UPDATE de monto; sin esta revisión ese cobro
-- no volvía a mirar el texto.
--
-- Se evalúan la descripción, la dirección y los mensajes del cliente en
-- este trabajo. No se recorre el chat de otros pedidos ni los mensajes
-- del profesional: un texto viejo, de otro trabajo o del oficio, no deja
-- el cobro trabado.
-- service_role y un administrador pueden crear el pago igual. Es la vía
-- para destrabar un caso legítimo (un RUT que igual calzó, un mensaje
-- anterior) sin apagar el filtro para el cliente. auth.role() lee el JWT:
-- no se usa current_user, porque la función es SECURITY DEFINER y ese
-- usuario sería siempre el dueño.

CREATE OR REPLACE FUNCTION public.texto_tiene_contacto(p_texto text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v text := btrim(COALESCE(p_texto, ''));
  v_phone constant text := '(?:^|[^0-9])(?:\+?56[[:space:].-]*)?(?:9(?:[[:space:].-]?[0-9]){8}|2(?:[[:space:].-]?[0-9]){8}|(?:32|33|34|35|41|42|43|45|51|52|53|55|57|58|61|63|64|65|67|71|72|73|75)(?:[[:space:].-]?[0-9]){7})(?:[^0-9]|$)';
  v_hit text;
  v_digits text;
  v_guard integer := 0;
BEGIN
  IF v = '' THEN
    RETURN false;
  END IF;

  IF v ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}' THEN
    RETURN true;
  END IF;

  IF v ~* '\m[a-z0-9._%+\-]+\M[[:space:]]+arroba[[:space:]]+([a-z0-9.\-]+\.(cl|com|net|org)|gmail|hotmail|outlook|yahoo|icloud)\M' THEN
    RETURN true;
  END IF;

  IF v ~* '(whats[[:space:]]*app|w[aá]ts?a+p+|\mwsp\M|guasap|wasap|wa\.me|t\.me|ll[aá]mame|h[aá]blame[[:space:]]+al)' THEN
    RETURN true;
  END IF;

  IF v ~* '(facebook|\mfb\M|instagram|\minsta\M|\mig\M|tik[[:space:]]*tok|tiktok|snapchat|twitter|signal|discord|telegram)[[:space:]]*[:：][[:space:]]*@?[[:alnum:]._]{2,}'
     OR v ~* '(facebook|\mfb\M|instagram|\minsta\M|\mig\M|tik[[:space:]]*tok|tiktok|snapchat|twitter|signal|discord|telegram)[[:space:]]+@[[:space:]]*[[:alnum:]._]{2,}'
     OR v ~* '\m(mi|en)\M[[:space:]]+(facebook|\mfb\M|instagram|\minsta\M|\mig\M|tik[[:space:]]*tok|tiktok|snapchat|twitter|signal|discord|telegram)[[:space:]]+(es|de)[[:space:]]+@?[[:alnum:]._]{2,}'
     OR v ~* '(facebook|fb|instagram|tiktok|twitter|x|snapchat|t)\.(com|me)/[[:alnum:]._]{2,}'
     OR v ~* 'fb\.me/[[:alnum:]._]{2,}'
     OR v ~* 'm\.me/[[:alnum:]._]{2,}' THEN
    RETURN true;
  END IF;

  IF v ~* '(https?://|www\.)' THEN
    RETURN true;
  END IF;

  IF v ~* '\m[a-z0-9\-]+\.(cl|com|net|org)\M' THEN
    RETURN true;
  END IF;

  IF v ~* '(cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)([[:space:],-]+(cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)){6,}' THEN
    RETURN true;
  END IF;

  v := regexp_replace(v, '\mrut\M[[:space:]]*:?[[:space:]]*[0-9]{7,9}\M', ' ', 'gi');
  v := regexp_replace(v, '\m[0-9]{1,2}\.[0-9]{3}\.[0-9]{3}-[0-9Kk]\M', ' ', 'g');
  v := regexp_replace(v, '\m[0-9]{7,8}-[0-9Kk]\M', ' ', 'g');
  v := regexp_replace(v, '\$[[:space:]]*[0-9]{1,3}(\.[0-9]{3})+', ' ', 'g');
  v := regexp_replace(v, '\m[0-9]{1,3}(\.[0-9]{3})+\M', ' ', 'g');
  v := regexp_replace(
    v,
    '\m[0-9]+([.,][0-9]+)?[[:space:]]*(cm|mm|km|kg|grs?|g|ml|lts?|lt|mts?|metros?|horas?|hrs?|min|años?)\M',
    ' ',
    'gi'
  );

  WHILE v ~ v_phone LOOP
    v_guard := v_guard + 1;
    IF v_guard > 8 THEN
      EXIT;
    END IF;
    v_hit := substring(v from v_phone);
    v_digits := regexp_replace(v_hit, '[^0-9]', '', 'g');
    IF v_digits !~ '000$' THEN
      RETURN true;
    END IF;
    v := regexp_replace(v, v_phone, ' ');
  END LOOP;

  RETURN false;
END;
$$;

COMMENT ON FUNCTION public.texto_tiene_contacto(text) IS
  'True si el texto trae teléfono chileno, correo, enlace o usuario de una red. Una red nombrada, un RUT, una medida o un monto no cuentan.';

CREATE OR REPLACE FUNCTION public.pagos_exigir_sin_contacto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_desc text;
  v_dir text;
  v_cliente text;
BEGIN
  IF COALESCE(auth.role(), '') = 'service_role' OR public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF COALESCE(NEW.tipo_pago, 'principal') <> 'principal' THEN
    RETURN NEW;
  END IF;

  IF NEW.estado IS NOT NULL
     AND NEW.estado NOT IN ('pendiente', 'retenido', 'autorizado') THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(t.descripcion, ''),
         COALESCE(t.direccion, ''),
         t.id_usuario::text
    INTO v_desc, v_dir, v_cliente
  FROM public.trabajos t
  WHERE t.id::text = NEW.id_trabajo::text;

  IF public.texto_tiene_contacto(v_desc)
     OR public.texto_tiene_contacto(v_dir) THEN
    RAISE EXCEPTION 'este tipo de mensaje no está permitido';
  END IF;

  IF v_cliente IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.mensajes m
    WHERE m.id_trabajo::text = NEW.id_trabajo::text
      AND m.id_remitente::text = v_cliente
      AND public.texto_tiene_contacto(COALESCE(m.contenido, ''))
  ) THEN
    RAISE EXCEPTION 'este tipo de mensaje no está permitido';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pagos_exigir_sin_contacto ON public.pagos;
CREATE TRIGGER pagos_exigir_sin_contacto
  BEFORE INSERT OR UPDATE ON public.pagos
  FOR EACH ROW
  EXECUTE FUNCTION public.pagos_exigir_sin_contacto();

REVOKE ALL ON FUNCTION public.pagos_exigir_sin_contacto() FROM PUBLIC, anon, authenticated;

COMMENT ON FUNCTION public.pagos_exigir_sin_contacto() IS
  'Frena el pago principal si la descripción, la dirección o un mensaje del cliente traen contacto. service_role y admin pueden registrarlo.';
