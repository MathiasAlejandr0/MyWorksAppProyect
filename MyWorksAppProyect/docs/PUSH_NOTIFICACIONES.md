# Notificaciones push (FCM)

Con la app abierta los avisos ya llegan por Supabase Realtime. Esto agrega el
push de Firebase Cloud Messaging (gratis) para cuando la app está cerrada o en
segundo plano. Todo queda apagado hasta completar estos pasos: sin las
variables `FCM_*` la app no inicializa Firebase y la Edge Function responde
`skipped`.

## Cómo funciona

1. Al iniciar sesión, la app (Android) pide permiso de notificaciones, obtiene
   su token FCM y lo guarda con `registrar_dispositivo_push()`. Al cerrar
   sesión lo borra con `quitar_dispositivo_push()`.
2. Cada fila nueva en `public.notificaciones` dispara un Database Webhook que
   llama a la Edge Function `send-push`.
3. `send-push` busca los tokens del destinatario en `dispositivos_push`, firma
   un JWT con la cuenta de servicio, pide un access token a Google y envía el
   mensaje por la API HTTP v1. Los tokens que FCM da por muertos se borran.

## Pasos manuales (Mathias)

1. **Proyecto Firebase.** En <https://console.firebase.google.com> crea un
   proyecto (plan Spark, gratis) y agrega una app Android con el paquete
   `cl.myworksapp.app`. No hace falta descargar `google-services.json`.
2. **Valores de la app.** En *Configuración del proyecto → General → Tus apps*
   copia: clave de API (`FCM_API_KEY`), ID de la app (`FCM_APP_ID`,
   `1:...:android:...`), número del proyecto (`FCM_SENDER_ID`) e ID del
   proyecto (`FCM_PROJECT_ID`). Son identificadores públicos de la app.
   Agrégalos a `dart_defines.json` (lo lee `scripts/build-apk.ps1`) o pásalos
   con `--dart-define=FCM_...=...` al compilar.
3. **Cuenta de servicio.** En *Configuración del proyecto → Cuentas de
   servicio* genera una clave privada (JSON). Ese archivo **sí es secreto**:
   no lo subas al repo. Guárdalo como secreto de la función:

   ```bash
   supabase secrets set --project-ref wxqrfcqifkfgawrnqmnj \
     FCM_SERVICE_ACCOUNT="$(cat ruta/a/cuenta-servicio.json)"
   ```

4. **Migración.** Aplica `20261113000005_push_dispositivos.sql` (después de
   las anteriores pendientes).
5. **Función.** `supabase functions deploy send-push --project-ref wxqrfcqifkfgawrnqmnj`
   (`verify_jwt = false` en `config.toml`; la función exige la service role).
6. **Webhook.** En el dashboard de Supabase: *Database → Webhooks → Create*.
   Tabla `public.notificaciones`, evento `INSERT`, tipo *Supabase Edge
   Functions*, función `send-push`, método POST, y activa *Add auth header
   with service key*.
7. **Probar.** Compila el APK con los `FCM_*`, inicia sesión en un teléfono,
   cierra la app y crea un aviso para esa cuenta (por ejemplo aceptando un
   trabajo desde otra cuenta). Debería llegar el push. En
   *Edge Functions → send-push → Logs* se ve `sent`/`removed`.

## Límites

- Solo Android por ahora. iOS necesita además una clave APNs en Firebase.
- El push muestra título y cuerpo; tocarlo abre la app (aún no navega al
  trabajo; el `id_relacionado` va en `data` para hacerlo después).
- Con la app en primer plano no se duplica: Android no pinta el push de tipo
  `notification` y el banner lo pone Realtime.
