-- El chat ya rechaza teléfono, correo, enlaces y redes.
-- El cobro en garantía no lo hacía: un texto cargado por API
-- (descripción del trabajo o un mensaje antiguo) igual podía pagarse.
-- Esta lectura usa la misma regla y frena el pago principal.

CREATE OR REPLACE FUNCTION public.texto_tiene_contacto(p_texto text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $$
DECLARE
  v text := COALESCE(p_texto, '');
BEGIN
  IF btrim(v) = '' THEN
    RETURN false;
  END IF;
  IF v ~* '[a-z0-9._%+\-]+@[a-z0-9.\-]+\.[a-z]{2,}' THEN
    RETURN true;
  END IF;
  IF v ~* '\marroba\M' THEN
    RETURN true;
  END IF;
  IF v ~* '(whats[[:space:]]*app|w[aá]ts?a+p+|\mwsp\M|guasap|wasap|ll[aá]mame|h[aá]blame[[:space:]]+al|telegram|\minsta\M|instagram|facebook|tiktok|snapchat|\mtwitter\M|wa\.me|t\.me|(plus|m[aá]s)[[:space:]]*56)' THEN
    RETURN true;
  END IF;
  IF v ~* '(https?://|www\.)' THEN
    RETURN true;
  END IF;
  IF v ~* '\m[a-z0-9\-]+\.(cl|com|net|org)\M' THEN
    RETURN true;
  END IF;
  IF v ~ '(^|[^0-9])(\+?56[[:space:].-]*)?[29]([[:space:].-]?[0-9]){8}([^0-9]|$)' THEN
    RETURN true;
  END IF;
  IF v ~* '(cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)([[:space:],-]+(cero|uno|una|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)){6,}' THEN
    RETURN true;
  END IF;
  RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION public.pagos_exigir_sin_contacto()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_desc text;
BEGIN
  IF COALESCE(NEW.tipo_pago, 'principal') <> 'principal' THEN
    RETURN NEW;
  END IF;
  IF NEW.estado IS NOT NULL
     AND NEW.estado NOT IN ('pendiente', 'retenido', 'autorizado') THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(t.descripcion, '')
  INTO v_desc
  FROM public.trabajos t
  WHERE t.id::text = NEW.id_trabajo::text;

  IF public.texto_tiene_contacto(v_desc) THEN
    RAISE EXCEPTION 'este tipo de mensaje no está permitido';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.mensajes m
    WHERE m.id_trabajo::text = NEW.id_trabajo::text
      AND public.texto_tiene_contacto(COALESCE(m.contenido, ''))
  ) THEN
    RAISE EXCEPTION 'este tipo de mensaje no está permitido';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pagos_exigir_sin_contacto ON public.pagos;
CREATE TRIGGER pagos_exigir_sin_contacto
  BEFORE INSERT ON public.pagos
  FOR EACH ROW
  EXECUTE FUNCTION public.pagos_exigir_sin_contacto();

REVOKE ALL ON FUNCTION public.pagos_exigir_sin_contacto() FROM PUBLIC, anon, authenticated;
