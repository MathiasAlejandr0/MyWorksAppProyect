# IA en MyWorksApp (fases 0 a 4)

La rama `feat/ia-ml` deja lista la base de eventos, la búsqueda híbrida, el asistente, la moderación y las alertas. Nada de esto se aplicó en el proyecto Supabase `wxqrfcqifkfgawrnqmnj`. Las fases 5 a 8 están solo en `IA_ROADMAP.md`.

La IA que toca una decisión sensible **propone**. Un administrador confirma en la consola. No bloquea cuentas, no resuelve disputas y no rechaza documentos.

## Arquitectura

```text
app / web
  registrar_evento          (no bloquea la pantalla)
  buscar_profesionales_hibrido  → si falla, listar_profesionales_catalogo
  asistente-solicitud | embed | moderar-mensaje | validar-documento

Postgres
  eventos
  mv_stats_profesional      (pg_cron, cada hora)
  embeddings vector(384) + cola
  cola_moderacion
  incidentes_seguridad tipo ia_*

Consola
  Moderación (cola)
  Seguridad → Alertas IA (Realtime de incidentes_seguridad)
```

El catálogo público dejó de llamar `stats_profesional()` una vez por profesional. Lee `mv_stats_profesional`. Esa era la consulta que en k6 se degradaba cerca de 100 VU y caía cerca de 280.

## Migraciones

No corren solas en producción. Timestamps posteriores a `20261122190000`.

| Archivo | Qué hace |
| --- | --- |
| `20261122200000_ia_eventos_stats_vector.sql` | Tabla `eventos`, RLS, `mv_stats_profesional`, catálogo sobre la vista, extensión `vector`, cron horario |
| `20261122210000_ia_embeddings_busqueda.sql` | `embedding vector(384)` en `trabajadores` y `trabajos` (la solicitud), índice HNSW, cola, `buscar_profesionales_hibrido`, `profesionales_parecidos`, pesos |
| `20261122220000_ia_asistente.sql` | Consentimiento `ia-datos-2026`, sugerencia de perfil, resumen de reseñas |
| `20261122230000_ia_moderacion.sql` | `cola_moderacion`, `clasificar_mensaje`, sugerencia de documento |
| `20261122230100_ia_moderacion_enum.sql` | Valor de bitácora `revisar_moderacion` |
| `20261122230200_ia_moderacion_revision.sql` | Listar y revisar la cola. No borra el mensaje |
| `20261122240000_ia_fraude.sql` | Reglas (reseñas, huella, login, disputas, cuenta y retiro), bandera del Isolation Forest, cron cada 15 min |
| `20261122250000_ia_embeddings_sin_hash.sql` | Quita el vector hash. Sin gte-small el embedding queda null y el texto sigue en la cola |
| `20261122260000_ia_fraude_liquidacion_uuid.sql` | La regla de retiro compara `liquidaciones.id_trabajador` uuid y `creado_en` timestamptz |

## Funciones

| Función | Rol |
| --- | --- |
| `embed` | gte-small con `Supabase.ai.Session`. Si el modelo no está, responde 503 y no inventa un vector |
| `asistente-solicitud` | JSON de categoría, urgencia, rango y preguntas. Gemini si hay `GEMINI_API_KEY`. Ollama si `OLLAMA_URL`. Si no, mock |
| `moderar-mensaje` | Reglas primero. El modelo solo opina en los casos `dudoso` |
| `validar-documento` | Visión de Gemini sobre la foto ya recortada. Sin el campo `rut`. Guarda `sugerencia_validacion` |

Secretos solo en el entorno o en secrets de Supabase: `GEMINI_API_KEY`, `OLLAMA_URL`, `IA_PROVEEDOR`, `EMBED_INTERNO_SECRET`. El código no trae claves.

## Cómo probar en local

1. Supabase local (no el proyecto `wxqrfcqifkfgawrnqmnj`).
2. `supabase db reset` dentro de `myworksapp_app`, o aplicar las migraciones en orden.
3. No correr `scripts/demo/seed_historial_puerto_montt.sql`.
4. Encolar textos sin vector: `psql "$DATABASE_URL" -f scripts/ia/backfill_embeddings.sql`. No escribe un embedding.
5. gte-small corre dentro del Edge Runtime (`edge-runtime`), no en Deno pelado. El asistente sin Gemini usa el mock. Ollama: `IA_PROVEEDOR=ollama` y `OLLAMA_URL=http://127.0.0.1:11434`.
6. k6 real: `scripts/load/k6/catalogo-real.js` contra PostgREST, con `K6_URL` y `K6_JWT`.

## Resultados locales (22-nov-2026)

Postgres 17.6 de la imagen `supabase/postgres:17.6.1.071`, con `vector` y `pg_cron`. PostgREST 14.3, pool de 10. 801 profesionales sintéticos de electricidad, 1.602 trabajos completados y 1.602 reseñas. No se usó el proyecto `wxqrfcqifkfgawrnqmnj`.

El `supabase start` no llegó a quedar en pie: la red bridge de Docker no deja que un contenedor hable con otro, y el runtime de Realtime no conectaba. El Postgres, PostgREST y GoTrue se levantaron en la red host. Las migraciones se aplicaron con `psql` y `ON_ERROR_STOP`.

El orden de archivos del repo no recrea solo el esquema: los primeros asumen tablas que el baseline crea después, y `20260322000001` usa `pagos` antes del rename de septiembre. Para llegar a cero errores se aplicó el baseline, después el rename, y el resto en orden. Hicieron falta objetos que el repo no crea: `auth.jwt()`, `storage.buckets` y `storage.objects`, y columnas que el baseline no trae (`tickets_soporte.estado`, `codigos_restablecimiento.usado`). `is_admin()` se creó vacío y las migraciones posteriores lo reemplazaron. Al final, los 142 archivos más `20261122250000` y `20261122260000` quedaron aplicados.

Comprobado en esa base:

- `refrescar_mv_stats_profesional` llenó 801 filas. El catálogo devolvió 20.
- `buscar_profesionales_hibrido('enchufe', ...)` devolvió 10 filas en modo `lexico` (no había vector).
- `profesionales_parecidos` devolvió 4.
- Un mensaje con insulto se insertó y quedó en `cola_moderacion` con motivo `insulto` y estado `pendiente`. El mensaje sigue en `mensajes`.
- `evaluar_alertas_ia` abrió `ia_rafaga_resenas` (el cliente sintético cargó las reseñas).
- Un usuario inserta su evento y no lee el de otro. Con `admin_requiere_aal2=1`, el admin en aal1 recibe `forbidden` en `consola_alertas_ia` y en `consola_revisar_moderacion`. Con aal2, `is_admin()` es verdadero y lee las alertas.
- No queda la función `embedding_hash`. Un alta deja `embedding` null y una fila en `ia_cola_embeddings`.

k6 (`catalogo-real.js`, rampa 50→300 VU, 2 min 45 s, solo `listar_profesionales_catalogo`, think 0,1 s). El p95 de 10 s en el antes es el tope de la espera, no una respuesta útil.

| VU | Antes p50 | Antes p95 | Después p50 | Después p95 |
| --- | --- | --- | --- | --- |
| ~50 | 883 ms | 6,7 s | 16 ms | 88 ms |
| ~100 | 3,0 s | 10 s | 115 ms | 532 ms |
| ~150 | 4,5 s | 10 s | 240 ms | 1,1 s |
| ~200 | 6,5 s | 10 s | 358 ms | 1,6 s |
| ~280 | 8,6 s | 10 s | 512 ms | 2,4 s |
| ~300 | 9,7 s | 10 s | 579 ms | 2,7 s |

Antes: 4.924 peticiones, 27,9 % de error. Se degrada ya cerca de 50 VU y el p95 queda pegado al tope desde unos 100 VU. Después: 49.930 peticiones, 0 % de error. Sube con los VU por el pool de 10, y no se cae a 300.

gte-small sí corrió en el Edge Runtime local (`public.ecr.aws/supabase/edge-runtime:v1.70.0`). `POST /` de `embed` respondió `origen: gte-small` y un vector de 384. En Deno pelado, sin `Supabase.ai`, la misma función responde 503 y `embedding: null`.

Curl contra las funciones servidas con Deno, JWT de GoTrue local:

- `embed` sin apikey: 401. Sin modelo: 503, sin vector.
- `asistente-solicitud` sin sesión: 401. Sin consentimiento no se usó; con consentimiento y mock: 200, gasfitería, urgencia alta. Tras 20 llamadas: 429. Un Ollama falso que devolvió categoría `magia`: 422.
- `moderar-mensaje` con insulto: 200, motivo `insulto`, sin borrar.
- `validar-documento` con campo `rut`: 400. Con WebP recortado y sin RUT: 200, sugerencia, no aprueba.

## Costo

Plan gratis. pgvector, pg_cron y Edge Functions entran en el free tier de Supabase. gte-small corre dentro de la función, sin una API de embeddings de pago. Gemini se usa en su capa gratuita y solo si Mathias carga el secret. Ollama es local. El Isolation Forest es un script de Python en GitHub Actions, sin librerías de pago. La bandera `anomalias_isolation_forest` nace apagada: con pocos eventos no se escriben alertas de modelo.

## Privacidad (ley chilena de datos personales)

- El uso de IA que manda texto o una foto a un proveedor externo exige el consentimiento `ia-datos-2026` (`registrar_consentimiento_ia`).
- `eventos` no guarda RUT, correo, teléfono ni cuenta. Un trigger los saca de `metadata`.
- Antes de Gemini u Ollama el texto pasa por `enmascararParaExterno`.
- La validación de documento no acepta un campo `rut`. En el teléfono se recorta el borde inferior (donde suele ir el RUT) y solo esa copia va al modelo. La foto completa, en WebP, queda para el administrador.
- El resumen de reseñas y la sugerencia de perfil se vuelven a enmascarar al guardarse.
- Entrenar (fases 5 a 8) pide datos anonimizados. Esta rama no entrena modelos.

## Qué no hace

- No aplica migraciones en producción.
- No decide sola un bloqueo, una disputa ni un documento.
- No borra mensajes marcados. El filtro de contacto que ya existía sigue impidiendo teléfono, correo y enlaces en el chat.
- No toca `Fase 1/` ni `Fase 2/`.
