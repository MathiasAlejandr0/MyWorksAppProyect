-- Paridad con shared/src/chat/contactCases.json.
-- El repo no tiene pgTAP. Con la migración aplicada en una base local:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/texto_tiene_contacto_casos.sql
-- No apunta a producción.
DO $$
DECLARE
  v boolean;
BEGIN
  v := public.texto_tiene_contacto('escribeme a ana@correo.cl');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'escribeme a ana@correo.cl', v;
  END IF;
  v := public.texto_tiene_contacto('mi correo es ana arroba correo.cl');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'mi correo es ana arroba correo.cl', v;
  END IF;
  v := public.texto_tiene_contacto('ana arroba gmail');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'ana arroba gmail', v;
  END IF;
  v := public.texto_tiene_contacto('9 8765 4321');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', '9 8765 4321', v;
  END IF;
  v := public.texto_tiene_contacto('+56912345678');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', '+56912345678', v;
  END IF;
  v := public.texto_tiene_contacto('+56 9 8765 4321');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', '+56 9 8765 4321', v;
  END IF;
  v := public.texto_tiene_contacto('912345678');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', '912345678', v;
  END IF;
  v := public.texto_tiene_contacto('9.1234.5678');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', '9.1234.5678', v;
  END IF;
  v := public.texto_tiene_contacto('el fijo es 2 2345 6789');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'el fijo es 2 2345 6789', v;
  END IF;
  v := public.texto_tiene_contacto('+56 65 234 5678');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', '+56 65 234 5678', v;
  END IF;
  v := public.texto_tiene_contacto('fijo Puerto Montt 65 234 5678');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'fijo Puerto Montt 65 234 5678', v;
  END IF;
  v := public.texto_tiene_contacto('652345678');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', '652345678', v;
  END IF;
  v := public.texto_tiene_contacto('nueve uno dos tres cuatro cinco seis siete ocho');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'nueve uno dos tres cuatro cinco seis siete ocho', v;
  END IF;
  v := public.texto_tiene_contacto('hablame por whatsapp');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'hablame por whatsapp', v;
  END IF;
  v := public.texto_tiene_contacto('te paso mi wsp');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'te paso mi wsp', v;
  END IF;
  v := public.texto_tiene_contacto('llamame cuando puedas');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'llamame cuando puedas', v;
  END IF;
  v := public.texto_tiene_contacto('Háblame al fijo');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'Háblame al fijo', v;
  END IF;
  v := public.texto_tiene_contacto('mira https://wa.me/56911111111');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'mira https://wa.me/56911111111', v;
  END IF;
  v := public.texto_tiene_contacto('mi sitio es ejemplo.cl');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'mi sitio es ejemplo.cl', v;
  END IF;
  v := public.texto_tiene_contacto('te paso el wasap');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'te paso el wasap', v;
  END IF;
  v := public.texto_tiene_contacto('mi tiktok es oficios');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'mi tiktok es oficios', v;
  END IF;
  v := public.texto_tiene_contacto('tik tok @juan');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'tik tok @juan', v;
  END IF;
  v := public.texto_tiene_contacto('fb: juanita');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'fb: juanita', v;
  END IF;
  v := public.texto_tiene_contacto('facebook.com/juan.perez');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'facebook.com/juan.perez', v;
  END IF;
  v := public.texto_tiene_contacto('mi insta es juan');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'mi insta es juan', v;
  END IF;
  v := public.texto_tiene_contacto('mi signal es ana');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'mi signal es ana', v;
  END IF;
  v := public.texto_tiene_contacto('discord: taller.norte');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'discord: taller.norte', v;
  END IF;
  v := public.texto_tiene_contacto('telegram @pedro');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'telegram @pedro', v;
  END IF;
  v := public.texto_tiene_contacto('m.me/juanita');
  IF v IS DISTINCT FROM true THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'm.me/juanita', v;
  END IF;
  v := public.texto_tiene_contacto('El enchufe de la cocina no funciona');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'El enchufe de la cocina no funciona', v;
  END IF;
  v := public.texto_tiene_contacto('Configurar Facebook en el televisor del living');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'Configurar Facebook en el televisor del living', v;
  END IF;
  v := public.texto_tiene_contacto('La abuela no puede entrar a TikTok');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'La abuela no puede entrar a TikTok', v;
  END IF;
  v := public.texto_tiene_contacto('te escribo por facebook');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'te escribo por facebook', v;
  END IF;
  v := public.texto_tiene_contacto('buscame en facebook');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'buscame en facebook', v;
  END IF;
  v := public.texto_tiene_contacto('subo el avance a tiktok');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'subo el avance a tiktok', v;
  END IF;
  v := public.texto_tiene_contacto('veo tik tok');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'veo tik tok', v;
  END IF;
  v := public.texto_tiene_contacto('hablame por telegram');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'hablame por telegram', v;
  END IF;
  v := public.texto_tiene_contacto('el instagramer del barrio pide arreglo de la puerta');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'el instagramer del barrio pide arreglo de la puerta', v;
  END IF;
  v := public.texto_tiene_contacto('traer una arroba de papas a la casa');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'traer una arroba de papas a la casa', v;
  END IF;
  v := public.texto_tiene_contacto('el muro queda en más 56 cm');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'el muro queda en más 56 cm', v;
  END IF;
  v := public.texto_tiene_contacto('cobro más 56000 si hay materiales');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'cobro más 56000 si hay materiales', v;
  END IF;
  v := public.texto_tiene_contacto('personas de más 56 años');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'personas de más 56 años', v;
  END IF;
  v := public.texto_tiene_contacto('total 25000');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'total 25000', v;
  END IF;
  v := public.texto_tiene_contacto('total $25.000');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'total $25.000', v;
  END IF;
  v := public.texto_tiene_contacto('total 2.500.000');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'total 2.500.000', v;
  END IF;
  v := public.texto_tiene_contacto('total 250000000');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'total 250000000', v;
  END IF;
  v := public.texto_tiene_contacto('RUT 20.123.456-7');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'RUT 20.123.456-7', v;
  END IF;
  v := public.texto_tiene_contacto('RUT 12.345.678-9');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'RUT 12.345.678-9', v;
  END IF;
  v := public.texto_tiene_contacto('RUT 201234567');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'RUT 201234567', v;
  END IF;
  v := public.texto_tiene_contacto('dirección Pasaje Los Carrera 1234');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'dirección Pasaje Los Carrera 1234', v;
  END IF;
  v := public.texto_tiene_contacto('vale 9.990 el repuesto');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'vale 9.990 el repuesto', v;
  END IF;
  v := public.texto_tiene_contacto('son 12.500 pesos');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'son 12.500 pesos', v;
  END IF;
  v := public.texto_tiene_contacto('hora 14:30 del 20-11-2026');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'hora 14:30 del 20-11-2026', v;
  END IF;
  v := public.texto_tiene_contacto('pásame tu fb');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'pásame tu fb', v;
  END IF;
  v := public.texto_tiene_contacto('más 5 personas');
  IF v IS DISTINCT FROM false THEN
    RAISE EXCEPTION 'caso distinto al filtro de la app: % (obtuvo %)', 'más 5 personas', v;
  END IF;
END $$;
