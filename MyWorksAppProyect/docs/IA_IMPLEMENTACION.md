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

## Funciones

| Función | Rol |
| --- | --- |
| `embed` | gte-small con `Supabase.ai.Session`. Si el modelo no está, hash local. No llama a una API de pago |
| `asistente-solicitud` | JSON de categoría, urgencia, rango y preguntas. Gemini si hay `GEMINI_API_KEY`. Ollama si `OLLAMA_URL`. Si no, mock |
| `moderar-mensaje` | Reglas primero. El modelo solo opina en los casos `dudoso` |
| `validar-documento` | Visión de Gemini sobre la foto ya recortada. Sin el campo `rut`. Guarda `sugerencia_validacion` |

Secretos solo en el entorno o en secrets de Supabase: `GEMINI_API_KEY`, `OLLAMA_URL`, `IA_PROVEEDOR`, `IA_EMBED_PROVEEDOR`, `EMBED_INTERNO_SECRET`. El código no trae claves.

## Cómo probar en local

1. Supabase local (no el proyecto `wxqrfcqifkfgawrnqmnj`).
2. `supabase db reset` dentro de `myworksapp_app`, o aplicar las migraciones en orden.
3. No correr `scripts/demo/seed_historial_puerto_montt.sql`.
4. Embeddings provisionales: `psql "$DATABASE_URL" -f scripts/ia/backfill_embeddings.sql`.
5. Para gte-small, desplegar `embed` en el stack local. Para el asistente sin Gemini: no definas la clave. Para Ollama: `IA_PROVEEDOR=ollama` y `OLLAMA_URL=http://127.0.0.1:11434`.
6. Tests: `npm test` en `shared` y en `myworksapp_desktop`. En la app, `flutter test test/ia_ml_test.dart`. Python: `python3 -m unittest scripts/ia/test_isolation_forest.py`.
7. Comparación del catálogo sin Docker: `node scripts/ia/bench_catalogo.mjs`. Con k6: `node scripts/ia/bench_http.mjs` y `k6 run -e RUTA=antes scripts/load/k6/catalogo-mv.js`, luego `RUTA=despues`.

En esta máquina no hay Docker, así que no se levantó Supabase local ni se tocó producción. El k6 (20 VU, 20 s, 2.000 peticiones, 0 errores) pegó a un servidor que imita el patrón: `/antes` recalcula por profesional y `/despues` lee el agregado.

| Ruta | mediana | p95 |
| --- | --- | --- |
| antes | 0,96 ms | 2,10 ms |
| después | 0,69 ms | 1,47 ms |

El microbenchmark de 1.000 profesionales dio 0,25 ms contra 0,11 ms, con los mismos 20 resultados. En Postgres el ahorro es mayor: la función deja de ejecutar `stats_profesional()` por cada fila.
8. Consola: pestaña **Alertas IA** y ruta **Moderación**. Capturas de la vista fija: `VITE_IA_PREVIEW=1 npm run dev` en el escritorio.

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
