# Disputas escalables

Cómo cierra MyWorksApp una disputa sin que una persona mire cada foto, y por qué no se le pide a un detector de inteligencia artificial que decida el dinero.

No se aplicó nada en el proyecto Supabase de producción `wxqrfcqifkfgawrnqmnj`. Esta rama solo deja el código, la migración y las pruebas.

## Flujo por niveles

**Nivel 0. Antes del reclamo.** El profesional inicia con el PIN del cliente. La evidencia del trabajo, en la app, sale solo de la cámara: foto del antes, foto del después o un detalle. No hay galería ni archivo. Cada captura pide un nonce de un solo uso, guarda el SHA-256 del archivo y el de la imagen antes de comprimirla, toma el GPS del teléfono y deja que el servidor ponga la hora.

**Nivel 1. Acuerdo.** Las partes pueden aceptar, rehacer o anular, como ya estaba. Si anulan, el caso queda en `reembolso_pendiente` y el cron ahora pide la devolución a la tarjeta.

**Nivel 2. Reglas objetivas.** `clasificar_disputa` mira hechos, no “si la pintura se ve bien”:

| Hecho | Qué propone | ¿Mueve dinero solo? |
|---|---|---|
| Motivo conducta | Humano | No |
| El profesional ya tiene disputas resueltas sobre el tope | Humano | No |
| Monto sobre `$80.000` | Humano | No |
| Foto duplicada (dHash) | Humano | No |
| Hay fotos, pero no son confiables | Humano | No |
| No hay evidencia ni llegada, monto bajo, primer caso | Reembolsar al vencer el plazo | Sí, la regla que ya existía |
| Antes y después confiables, GPS dentro del radio, profesional verificado, monto bajo, primer caso | Liberar al vencer el plazo | Sí, la regla que ya existía |

El silencio del cliente (48 h) solo libera el pago si hay un par antes/después con procedencia verificada. Una foto de la galería o de la web ya no alcanza.

**Nivel 3. Puntaje.** `puntaje_riesgo` (0 a 100) y `decision_sugerida` ordenan la bandeja. La consola lo muestra como sugerencia. El puntaje no libera ni devuelve.

**Nivel 4. Persona.** Conducta, reincidencia, monto alto, apelación, evidencia no confiable, duplicado o un reembolso que falló varias veces. Prioridad `alta` / `media` / `baja` y `asignado_a`. El administrador asigna desde la bandeja.

La apelación (`apelar_disputa`) la puede pedir una parte dentro de las 72 horas si el cierre fue del sistema. El caso vuelve a `requiere_humano`. Pedirla no mueve el dinero. Si el pago ya se liberó o ya se devolvió, la revisión deja constancia y no lo mueve otra vez.

## Procedencia de la evidencia

Tabla `evidencia_nonces`: el nonce vive pocos minutos, va atado al trabajo y a quien lo pidió, y se gasta una sola vez.

Tabla `evidencia_procedencia`: qué se recibió, con qué hash, a qué distancia del trabajo y con qué confianza. Las partes del trabajo la pueden leer. El equipo de soporte y el administrador también. QA no. Nadie la escribe directo: solo las funciones del servidor.

Columnas nuevas en `fotos_trabajo`: origen, tipo (antes/después/detalle/video), GPS, hashes, nonce, distancia y `confianza` (`confiable` o `no_verificada`). Un trigger impide que el cliente se ponga `confiable` o cambie el hash. La foto vieja, sin sello, queda `no_verificada`.

Para que la app marque `confiable` tienen que cumplirse todas:

- nonce vigente, de ese trabajo y de esa persona, sin usar;
- SHA-256 igual al de la imagen WebP guardada;
- dHash calculado en el servidor a partir de la muestra de 72 luminancias, igual al que manda la app;
- GPS del teléfono a no más de 500 metros de la dirección del trabajo (se puede cambiar con `soporte_radio_evidencia_m`);
- hora del servidor dentro de la ventana del nonce.

Si el GPS cae fuera del radio, la función rechaza la captura. La foto sigue en `no_verificada`.

En la web el archivo sigue pudiendo subirse, porque el cliente a veces manda un comprobante desde el computador. Antes de pasarlo a WebP se guarda el hash y el nombre, el tipo y el tamaño originales. `registrar_evidencia_web` deja siempre `no_verificada`. Esa marca no se borra al convertir.

## Hash perceptual

El dHash (64 bits) no dice si una foto la hizo una IA. Dice si la misma imagen ya apareció en otro trabajo o en otra captura. Si la distancia de Hamming es 10 o menos, la foto nueva no es confiable, queda `duplicado` y se inserta una fila en `alertas_evidencia`. Si en la base existe `ia_fraude` (la pieza de la rama de IA), se intenta avisar ahí con la regla `evidencia_duplicada`. Si esa tabla tiene otra forma, el aviso de `alertas_evidencia` igual queda.

La muestra de luminancia la arma el teléfono o el navegador. El servidor vuelve a calcular el dHash y rechaza si no coincide. El SHA-256 sí se calcula sobre los bytes guardados. Postgres no decodifica WebP, y no se manda la foto del domicilio a un servicio externo para “verificar” el dHash.

## Por qué no se confía en un detector de IA

Un clasificador que “acierta” en un banco de prueba marca fotos reales como falsas con una frecuencia alta, y se queda atrás de cada generador nuevo. El NIST pide firmar el origen, no adivinarlo después. Por eso esta rama no llama a Gemini, Hive ni a ninguna API de pago, y no manda RUT ni la foto del cliente a un modelo externo.

La luz amarilla de la consola se enciende cuando la foto no está verificada o está duplicada. Es una señal para la persona que revisa la bandeja. No es un veredicto y no mueve el dinero.

## Reembolso que sí se ejecuta

El cron `mwa_resolver_soporte_automatico` (cada 10 minutos) ahora ejecuta `encadenar_soporte_automatico()`:

1. `resolver_soporte_automatico()` deja el caso en `reembolso_pendiente`, como antes.
2. `despachar_reembolsos_automaticos()` llama a `invocar_reembolso_edge()`.
3. Esa función lee en Vault `mwa_supabase_url` y `mwa_soporte_cron_secret` y hace `net.http_post` a `soporte-automatico` con el header `x-soporte-secret`. El comando del cron no contiene el secreto.
4. La función de borde devuelve el pago una sola vez (`refundHeldPaymentOnce`), cierra la disputa y marca `reembolsos_automaticos.estado = ejecutado`.
5. Si falla, queda `fallido` y el cron reintenta hasta 8 veces. Después el caso pasa a `requiere_humano` con regla `fallo_reembolso`.

Un reembolso ya `ejecutado` no se vuelve a pedir.

## Qué habría que aplicar en producción

Con el visto bueno de Mathias, y sin correr `seed_historial_puerto_montt.sql`:

1. Aplicar `myworksapp_app/supabase/migrations/20261124140000_disputas_escalables.sql`.
2. Crear en Vault, a mano, sin pegar los valores en el repositorio:
   - `mwa_soporte_cron_secret`: un secreto largo, el mismo que puede copiarse al secreto de la función `SOPORTE_CRON_SECRET` si se quiere el atajo de entorno.
   - `mwa_supabase_url`: `https://wxqrfcqifkfgawrnqmnj.supabase.co`
3. Tener `pg_net` y `pg_cron` activos. La migración reprograma el cron si `pg_cron` está.
4. Desplegar la función `soporte-automatico` (acepta el header del cron y la service role).
5. Publicar la app, la web y la consola de esta rama.

Hasta ese momento un `reembolso_pendiente` de producción sigue sin devolverse solo, igual que hoy.
