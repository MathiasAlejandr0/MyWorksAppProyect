# Auditoría de la base de datos: integridad y normalización

**Proyecto:** My Works App · **Base:** PostgreSQL 17.6 en Supabase (proyecto `wxqrfcqifkfgawrnqmnj`, plan gratuito, región us-west-2)
**Fecha de ejecución:** 16 de noviembre de 2026, entre las 01:00 y las 02:00 (hora de Chile, America/Santiago, UTC−3)
**Alcance:** esquema `public` (52 tablas, 437 columnas, 143 funciones), con los datos reales de la demo.

Este documento es la primera de cuatro partes de la auditoría de base de datos:

| Parte | Documento |
|-------|-----------|
| 1. Integridad y normalización | `docs/pruebas/auditoria_base_datos.md` (este) |
| 2. Rendimiento de consultas | `docs/pruebas/rendimiento_base_datos.md` |
| 3. Estrés con usuarios concurrentes | `docs/pruebas/estres_base_datos.md` |
| 4. Seguridad (RLS, privilegios, inyección, Edge Functions) | `docs/pruebas/seguridad_base_datos.md` |

El diccionario de datos (`docs/DICCIONARIO_BASE_DATOS.md` / `.docx`) y el Anexo A de la Fase 2 se regeneraron desde el esquema ya corregido y ahora incluyen, para cada tabla, su forma normal, la justificación en palabras simples y sus relaciones explicadas.

## 1. Objetivo

Comprobar, con evidencia sacada de la base real y no del código, que:

1. cada tabla está normalizada (1FN, 2FN, 3FN, BCNF y, donde aplica, 4FN) o, si repite un dato a propósito, que eso está justificado y se mantiene consistente;
2. la base hace cumplir sus propias reglas (claves foráneas, dominios cerrados, formatos), en vez de confiar solo en que la aplicación envíe datos correctos;
3. los cambios necesarios se pueden aplicar sin perder ni alterar datos.

## 2. Método

### 2.1 Fuente de verdad

Todo se consultó en la base viva, en modo lectura, con el catálogo de Postgres (`pg_constraint`, `pg_index`, `pg_policies`, `pg_proc`, `information_schema.columns`). Las migraciones del repositorio se usaron solo para entender la historia, porque una migración puede haber sido corregida después por otra.

### 2.2 Criterio de cada forma normal

| Forma | Pregunta que se hizo a cada tabla |
|-------|-----------------------------------|
| 1FN | ¿Cada celda guarda un solo valor y la tabla tiene clave primaria? |
| 2FN | Si la clave es compuesta, ¿alguna columna depende solo de una parte de ella? |
| 3FN | ¿Alguna columna que no es clave depende de otra columna que tampoco es clave (dependencia transitiva)? |
| BCNF | ¿Todo lo que determina a otra columna es una clave candidata? |
| 4FN | ¿Se mezclan en la misma tabla dos listas independientes del mismo dueño? |

Las columnas JSON o de texto que guardan un documento completo (el contenido de una acción sin conexión, el desglose de una cotización, el formulario de un servicio) se consideraron atómicas: la base nunca consulta su interior por separado, lo trata como un solo valor.

### 2.3 Verificación de redundancias

Cuando una tabla repite un dato que existe en otra, se escribió una consulta que cuenta cuántas filas difieren de la fuente. Una redundancia se acepta solo si tiene una razón concreta (rendimiento de una consulta frecuente, RLS o un registro histórico) y si el conteo de diferencias es 0.

### 2.4 Verificación antes de cada restricción

Antes de agregar una clave foránea se contó cuántas filas quedarían huérfanas; antes de agregar un CHECK, cuántas filas lo violarían. Todas las restricciones se agregaron como `NOT VALID` y luego se validaron con `VALIDATE CONSTRAINT`: así, si algún dato no cumpliera, la migración falla completa y no se cambia nada.

## 3. Resultados del análisis de normalización

### 3.1 Resumen

| Resultado | Tablas | Cuáles |
|-----------|--------|--------|
| BCNF sin redundancias | 37 | la mayoría (identificador propio y columnas que solo describen la fila) |
| 4FN (listas separadas de la ficha) | 3 | trabajador_precios, trabajador_servicios, trabajador_servicios_extra |
| BCNF con un dato repetido a propósito | 9 | calificaciones, calificaciones_cliente, codigos_restablecimiento, liquidaciones, notificaciones, perfiles, trabajos, ubicacion_en_vivo, trabajador_horarios (columna heredada) |
| 2FN con desnormalización controlada | 3 | mensajes, tickets_soporte, trabajadores |

Ninguna tabla está por debajo de 2FN. Las tres que no llegan a 3FN en sentido estricto lo hacen por una decisión de diseño explicada abajo, y el dato repetido coincide con su fuente en el 100 % de las filas.

### 3.2 Datos repetidos a propósito y su verificación

| Tabla.columna | Fuente | Por qué se guarda | Diferencias |
|---------------|--------|-------------------|-------------|
| `trabajos.estado_pago` | `pagos.estado` del pago principal | Filtrar listas de pedidos sin unir con pagos. Lo mantiene el trigger `copiar_estado_pago_trabajo`. | 0 |
| `mensajes.id_destinatario` | el otro participante del trabajo | Filtro de Realtime y RLS sin unir con trabajos. | 0 |
| `calificaciones.id_calificado` | trabajador o cliente del trabajo | Listar reseñas por persona con índice. | 0 |
| `calificaciones_cliente.id_trabajador` | `trabajos.id_trabajador` | RLS: el profesional ve lo que escribió. | 0 |
| `ubicacion_en_vivo.id_trabajador` | `trabajos.id_trabajador` | Autorizar la publicación de GPS en tiempo real. | 0 |
| `liquidaciones.id_trabajo`, `id_trabajador` | el pago liquidado | Libro contable: debe conservar a quién se pagó. | 0 |
| `trabajadores.id_region` | `comunas.id_region` | Profesionales con región pero sin comuna. | 0 (59 fichas con comuna) |
| `perfiles.correo` | `auth.users.email` | Mostrar y buscar sin salir de `public`. | 0 |
| `tickets_soporte.nombre_*`, `monto_escrow` | perfiles y pagos del trabajo | Foto del caso al abrir el ticket (trigger `fijar_ticket_desde_trabajo`). | 0 (tabla vacía) |
| `trabajadores.calificacion`, `trabajos_completados`, `score_listado` | calificaciones y trabajos | Ordenar el catálogo sin recalcular en cada consulta. | 0 (ver 3.3) |
| `trabajador_horarios.horarios` (jsonb) | columnas por día | Formato antiguo que aún leen versiones previas de la app (64 de 66 filas lo tienen). | — |

### 3.3 Observación sobre los datos de demostración

Durante la auditoría se encontró que los 24 profesionales sembrados para la demo (ids `11111111-…-0004xx`) tenían `calificacion` y `trabajos_completados` cargados a mano, sin trabajos ni reseñas que los respaldaran. Es una dependencia transitiva rota: la nota debe depender de las reseñas, no escribirse aparte.

**Corrección:** la migración `20261116044049_stats_profesional_fuente_unica.sql` (aplicada el 16-nov con el visto bueno de Mathias) definió una sola fuente: `privado.stats_profesional()` calcula la nota como el promedio simple de las reseñas reales y los trabajos como los trabajos en estado `completado`. El catálogo, la ficha y el panel de administración usan esa función, y las columnas cacheadas se recalcularon desde las filas reales, sin inventar reseñas ni trabajos.

**Verificación (16-nov, 02:08):** en los 64 profesionales, la nota y los trabajos guardados coinciden con el cálculo desde los datos reales (0 diferencias). 40 tienen nota respaldada por reseñas; los que no tienen reseñas se muestran como "Nuevo".

### 3.4 Listas en 4FN

La ficha del profesional (`trabajadores`) tenía dos listas en JSON: niveles de precio y servicios personalizados. Mezclarlas en una fila viola 4FN, porque son listas independientes del mismo dueño. La base ya las separaba en `trabajador_precios` y `trabajador_servicios_extra` mediante el trigger `explotar_oferta_trabajador`; los JSON quedan como formato de escritura de la app. La auditoría completó ese diseño: las tablas hijas tenían `id_usuario` como texto y sin clave foránea, y ahora es `uuid` con FK a `trabajadores` (ver 4.6). Se probó el trigger después del cambio: al guardar un servicio extra en la ficha de un profesional de prueba, apareció la fila correspondiente en `trabajador_servicios_extra`.

## 4. Hallazgos de integridad y corrección

Todos se corrigieron en la migración `20261116042559_auditoria_bd_integridad.sql`, aplicada con `apply_migration` y verificada. No borra filas.

### N1. Valores por defecto en inglés

Las primeras migraciones dejaron defaults en inglés (`rol = 'user'`, `estado_cuenta = 'active'`, `tipo_pago = 'primary'`, `mensajes.tipo = 'text'`, `tipo_medio = 'photo'`, etc.), pero el código y todos los datos usan el dominio en español. Un INSERT que omitiera la columna guardaba un valor que ninguna regla reconoce; por ejemplo, un perfil con rol `user` no pasa `es_rol_trabajador` ni `is_admin`, y queda en un estado que la app no muestra.
**Corrección:** defaults en español en 10 columnas (`usuario`, `activo`, `principal`, `texto`, `foto`, `nuevo`, `pendiente`, `por_hora`, `pendiente_cliente`).
**Se mantuvo a propósito:** `tickets_soporte.estado` (`Pending`/`Resolved`, que es lo que usa la consola de escritorio) y `acciones_pendientes.estado` (`pending_sync`, el valor del repositorio Dart). Cambiarlos rompería esos clientes.

### N2. Estados sin dominio cerrado

Columnas como `perfiles.rol`, `trabajos.estado`, `pagos.estado` o `calificaciones.puntaje` aceptaban cualquier texto o número. El dominio vivía solo en el código.
**Corrección:** 24 CHECK de dominio y rango, construidos con los valores que realmente existen en los datos y en el código: roles (5), estados de cuenta (4), estados de trabajo (13), modalidad de cobro (4), estados de pago (13), método y ambiente de pago, moneda CLP, montos no negativos, puntaje 1–5, coordenadas válidas, horas de bloque 1–24, entre otros.

### N3. Booleanos guardados como integer

Doce banderas (`disponible`, `leido`, `usado`, `activa`, etc.) son `integer` por herencia de la versión SQLite de la app. Se mantuvo el tipo para no romper los clientes, pero ahora un CHECK limita cada una a 0 o 1.

### N4. Fechas guardadas como texto

Muchas columnas `*_en` son `text`. Todos los valores actuales son ISO-8601 válidos, aunque con formatos mezclados (con y sin `T`, con y sin zona). Cambiar el tipo exigía reescribir el código de tres clientes.
**Corrección:** función `es_marca_tiempo_iso(text)` (IMMUTABLE) y 46 CHECK que impiden guardar un texto que no sea fecha u hora ISO. El cambio a `timestamptz` queda recomendado como trabajo futuro.

### N5. Claves foráneas faltantes

31 columnas referenciaban otra tabla sin FK declarada (por ejemplo `mensajes.id_remitente`, `reportes.id_reportante`, `pagos.id_orden_cambio`, `trabajos.id_cotizacion_seleccionada`). Sin FK, borrar un perfil o un trabajo dejaba filas apuntando a nada.
**Verificación previa:** 0 filas huérfanas en las 31.
**Corrección:** FK con la acción de borrado que corresponde a cada caso: `CASCADE` cuando la fila hija no tiene sentido sin el padre (mensajes de un trabajo), `SET NULL` cuando hay que conservar el registro (quién resolvió una disputa). Además se validó `liquidaciones_id_trabajo_fkey`, que estaba `NOT VALID`.
**Caso especial:** `perfiles.id → auth.users.id` se agregó con `ON DELETE CASCADE` pero sin validar, porque 8 perfiles de la demo no tienen usuario de Auth. La FK protege todas las filas nuevas; las 8 antiguas quedan documentadas.
En total la base pasó de 44 a 78 claves foráneas (31 de este punto y 3 del punto N6). La migración `20261116043033_auditoria_bd_indices_fk.sql` agregó el índice de cada nueva FK (ver el documento de rendimiento).

### N6. Identificadores de usuario guardados como texto

`trabajador_precios.id_usuario`, `trabajador_servicios_extra.id_usuario` y `metodos_pago_oneclick.id_usuario` eran `text` mientras la clave a la que apuntan es `uuid`. Por eso no podían tener FK, y las políticas RLS comparaban con un cast que impide usar índices.
**Verificación previa:** todos los valores eran uuid válidos y la única función que escribe esas tablas (`explotar_oferta_trabajador`) se pudo reescribir sin casts.
**Corrección:** `ALTER COLUMN … TYPE uuid`, FK y políticas recreadas comparando uuid con uuid.

### N7. Comuna duplicada

`santiago_centro` repetía a `santiago` en la misma región y no la usaba ningún registro. Se desactivó (`activa = 0`, sin borrarla) y se creó el índice único `comunas_region_nombre_activa_uidx` para que no puedan existir dos comunas activas con el mismo nombre en una región.

### Cifras antes y después

| Elemento | Antes | Después |
|----------|-------|---------|
| Claves foráneas | 44 | 78 |
| Restricciones CHECK | 43 | 125 |
| Restricciones sin validar | 1 | 1 (perfiles → auth.users, explicada) |
| Columnas de id de usuario en texto | 3 | 0 |

## 5. Riesgos que quedan y recomendaciones

1. **`perfiles.correo` sin índice único.** No hay duplicados hoy (0), pero un índice único podría impedir el registro de alguien cuyo correo ya figure en uno de los 8 perfiles de demo sin Auth. Se recomienda limpiar esos 8 perfiles antes de agregarlo.
2. **Fechas en texto.** Están validadas, pero conviene migrarlas a `timestamptz` en una versión futura de los clientes.
3. **Cifras cacheadas del profesional.** Ya se recalculan desde los datos reales (3.3). Si en el futuro se cargan reseñas o trabajos por fuera de las funciones de la app, hay que volver a correr el recálculo de esa migración.
4. **`notificaciones.id_relacionado`.** Es una referencia polimórfica (apunta a distintas tablas según el tipo) y por diseño no puede tener FK.

## 6. Reproducibilidad

- Migraciones: `myworksapp_app/supabase/migrations/20261116042559_auditoria_bd_integridad.sql` y `20261116043033_auditoria_bd_indices_fk.sql`.
- Snapshot del esquema después de la auditoría: `docs/_schema_public.json`; generador del diccionario: `docs/_gen_diccionario_desde_schema.py`, con el análisis por tabla en `docs/_normalizacion_bd.py`.
- Para regenerar el diccionario: `python3 MyWorksAppProyect/docs/_gen_diccionario_desde_schema.py` desde la raíz del repositorio.
