# Automatización de perfiles de trabajadores

**Proyecto:** MyWorksApp  
**Módulo:** Perfil profesional del trabajador  
**Versión:** 1.0  
**Fecha:** 2026-10-04  
**Alcance:** alta de cuenta, onboarding, oferta de precios y reputación  
**Documento hermano:** [AUTOMATIZACION_RANKING_Y_RESENAS.md](AUTOMATIZACION_RANKING_Y_RESENAS.md) (quién aparece primero en el listado y reseñas dudosas)

---

## 1. Objetivo

Documentar la **automatización del perfil de trabajador** en MyWorksApp: qué se crea solo, qué debe completar la persona y qué se deriva en la base de datos sin que la aplicación vuelva a escribir copias.

El perfil no es un formulario único. Es un conjunto de tablas (`perfiles`, `trabajadores`, `trabajador_precios`, `trabajador_servicios_extra`, `trabajador_servicios`, `portafolio_trabajador`, `calificaciones`) que deben quedar coherentes para que el profesional aparezca en búsquedas y pueda recibir trabajos.

La automatización cubre tres capas:

| Capa | Dónde ocurre | Qué resuelve |
|------|----------------|--------------|
| Identidad | Trigger `handle_new_user` en PostgreSQL | Crea `perfiles` al registrarse en Auth |
| Experiencia | Flutter (`WorkerRegisterPage`, checklist, navegación) | Guía el alta y bloquea el listado incompleto |
| Consistencia | La app escribe la oferta en filas; trigger sobre `calificaciones` | Precios, extras y oficios tienen una sola fuente y la calificación se recalcula |

---

## 2. Problema de negocio

Sin automatización, el trabajador tendría que:

1. Crear su cuenta y, en un segundo paso, copiar nombre, correo y rol a `perfiles`.
2. Cargar sus precios, servicios extra y oficio en varios lugares.
3. Actualizar a mano `calificacion` cada vez que un cliente califica un trabajo.
4. Adivinar qué le falta para aparecer en el marketplace.

Eso produce perfiles vacíos, precios desfasados entre copias, y rankings que no coinciden con las notas reales.

La automatización **no reemplaza** la decisión profesional (oficio, zona, tarifas). Reemplaza las copias derivadas y el checklist de “qué falta”.

---

## 3. Modelo de datos del perfil

El trabajador es una extensión 1:1 de `perfiles`:

```
auth.users  ──1:1──►  perfiles  ──1:1──►  trabajadores
                                              │
                                              ├──► trabajador_precios          (N)
                                              ├──► trabajador_servicios_extra  (N)
                                              ├──► trabajador_servicios        (N:M con categoría)
                                              └──► portafolio_trabajador       (N)
```

`calificacion` en `trabajadores` **no se edita en pantalla**. Es un agregado de `calificaciones` unidas a `trabajos` del mismo `id_trabajador`.

La oferta vive solo en filas (4FN): los precios en `trabajador_precios`, los servicios extra en `trabajador_servicios_extra` y los oficios en `trabajador_servicios` (cada oficio es una categoría de `categorias_servicio`). `trabajadores` no repite esos datos. El formulario de tarifas arma el objeto en la app y el repositorio lo guarda como filas; las búsquedas y el cobro leen esas mismas filas.

---

## 4. Flujo automatizado (de punta a punta)

```
Registro Auth (rol trabajador)
        │
        ▼
handle_new_user()
  INSERT perfiles (nombre, correo, rol='trabajador', estado_cuenta='activo')
        │
        ▼
La app no encuentra fila en trabajadores
        │
        ▼
goToWorkerEntryRoute → /registro-trabajador
        │
        ▼
WorkerRegisterPage
  upsert trabajadores (profesión, zona)
  upsert trabajador_precios, trabajador_servicios_extra
  y trabajador_servicios (categoría) desde el repositorio
        │
        ▼
Pantalla de tarifas (pricingConfigured = false)
        │
        ▼
Home trabajador + WorkerOnboardingCard
  6 requisitos, porcentaje y atajos a cada pantalla
        │
        ▼
Cuando el checklist está completo y isAvailable = true
  el profesional entra al listado de búsqueda
```

`handle_new_user` **no** inserta `trabajadores`. El rol en `perfiles` solo marca la intención. El perfil profesional se crea cuando la persona elige oficio y zona. Así no hay filas de trabajador vacías por un registro a medias.

---

## 5. Automatización de identidad (`handle_new_user`)

Al insertar un usuario en `auth.users`, el trigger crea (o ignora si ya existe) la fila de `perfiles`.

Reglas:

- Metadato `role` / `trabajador` / `worker` → `rol = 'trabajador'`. Cualquier otro valor → `rol = 'usuario'`.
- El nombre se toma, en orden, de `name`, `nombre`, `full_name`, `given_name` o la parte local del correo.
- `estado_cuenta` parte en `activo`.
- `ON CONFLICT (id) DO NOTHING`: un reintento de Auth no duplica el perfil.

El trabajador autenticado solo puede insertar su propia fila en `trabajadores` (`id_usuario = auth.uid()`), salvo administrador.

---

## 6. Automatización de onboarding (aplicación)

### 6.1 Entrada según estado

`goToWorkerEntryRoute` elige la primera pantalla útil:

| Estado | Destino |
|--------|---------|
| No hay fila en `trabajadores` | Registro de oficio y zona |
| Hay fila, pero `pricingConfigured = false` | Configuración de tarifas |
| Perfil operativo | Home del trabajador |

No se deja al profesional en un home vacío si todavía no tiene oferta.

### 6.2 Alta con valores por defecto

Al enviar el formulario de registro, la app:

- Mapea la profesión a su categoría (`trabajador_servicios.categoria_servicio`).
- Carga **tarifas por defecto** del catálogo (`WorkerServiceOptionsCatalog.defaultTiersFor`).
- Deja `isAvailable = true` (puede listarse cuando el resto del checklist esté listo).
- Hace `upsert` en `trabajadores` (si la persona vuelve a entrar, no se duplica).

El repositorio guarda además esos defaults en `trabajador_precios` y la categoría en `trabajador_servicios`.

### 6.3 Checklist de seis requisitos

`WorkerOnboardingChecklistService` calcula un porcentaje `(completados / 6) × 100`.

| # | Requisito | Criterio | Si falta, la UI lleva a |
|---|-----------|----------|-------------------------|
| 1 | Foto de perfil | `perfiles` con foto no vacía | Perfil |
| 2 | Descripción | ≥ 150 caracteres | Gestión de perfil |
| 3 | Portafolio | ≥ 1 foto en `portafolio_trabajador` | Gestión de perfil |
| 4 | Servicio | categoría en `trabajador_servicios` distinta de vacío / `general` | Registro |
| 5 | Zona | texto ≥ 3 caracteres | Gestión de perfil |
| 6 | Tarifas | `pricingConfigured = true` | Setup de precios |

La tarjeta `WorkerOnboardingCard` se oculta al 100 %. Mientras falte algo, muestra barra, lista de pendientes y un botón de refresco.

### 6.4 Visibilidad en el marketplace

`isListedInSearch` exige:

- fila de trabajador existente,
- tarifas configuradas,
- `isAvailable = true`,
- checklist completo,
- y, en el repositorio, que el profesional no esté ocupado en un trabajo activo.

La reputación de listado **sí se guarda** en `trabajadores.score_listado` (migración de ranking). `WorkerReputationService` usa esa columna si existe; si no, resta hasta 1,75 puntos internos por rechazos. El cliente ve `calificacion`, no el score interno.

---

## 7. Automatización en base de datos (oferta y reputación)

Migración de referencia: `20261004000001_normalizar_y_optimizar.sql`.

### 7.1 Oferta del profesional (una sola fuente)

La oferta se guarda con tres tablas hijas de `trabajadores`, todas con `id_usuario` (o `id_trabajador`) igual a `auth.uid()` en RLS:

1. `trabajador_precios`: una fila por código de servicio con `monto_clp`.
2. `trabajador_servicios_extra`: extras con título, subtítulo, monto y unidad (`fijo` o `por_m2`).
3. `trabajador_servicios`: el oficio del profesional, una categoría de `categorias_servicio`.

El repositorio (`WorkerRepository._saveOffer` en la app) hace `upsert` de las filas vigentes y borra las que el profesional quitó. No hay triggers de copia ni columnas JSON de oferta en `trabajadores`. La región del profesional se obtiene desde su comuna (`comunas` → `regiones`).

Las horas reservables se guardan con la RPC `guardar_horarios_propios`: reemplaza de forma atómica la ventana semanal (`trabajador_horarios`, una fila por día) y las horas publicadas (`trabajador_horas_publicadas`).

### 7.2 Recalcular calificación (`refrescar_calificacion_trabajador`)

Trigger `AFTER INSERT OR UPDATE OR DELETE` en `calificaciones`.

1. Resuelve el `id_trabajador` del trabajo calificado.
2. Escribe en `trabajadores.calificacion` el promedio redondeado a 2 decimales de todas las notas de sus trabajos.
3. Si no hay notas, deja `0`.

El perfil público no permite “subir la nota a mano”. La nota sale del historial.

---

## 8. Qué queda deliberadamente manual

La automatización **no** inventa:

- Oficio ni categoría de servicio.
- Zona de cobertura.
- Texto de presentación ni fotos de portafolio.
- Montos finales de visita o extras (solo propone defaults al registrar).
- Disponibilidad operativa (`isAvailable`): el profesional puede ocultarse.

Esas decisiones son del titular del perfil. El sistema solo deriva copias, porcentajes y ranking.

---

## 9. Invariantes que la automatización protege

| Invariante | Cómo se sostiene |
|------------|------------------|
| Un usuario Auth tiene a lo más un `perfiles` | PK `perfiles.id` + `ON CONFLICT DO NOTHING` |
| Un trabajador es 1:1 con el usuario | PK `trabajadores.id_usuario` + `upsert` |
| Precios, extras y oficio tienen una sola fuente | Tablas `trabajador_precios`, `trabajador_servicios_extra` y `trabajador_servicios`; `trabajadores` no los repite |
| `calificacion` = promedio de notas reales | Trigger `calificaciones_refrescar_trabajador` |
| No hay trabajador “fantasma” al registrarse | `handle_new_user` no inserta `trabajadores` |
| No se lista un perfil a medias | Checklist + `pricingConfigured` + `isAvailable` |
| El trabajador no escribe la fila de otro | RLS `id_usuario = auth.uid()` |

---

## 10. Diagrama de secuencia (oferta)

```
Trabajador          Flutter                 PostgreSQL
    │                  │                         │
    │  guardar tarifas │                         │
    │─────────────────►│  upsert trabajador_precios
    │                  │  upsert trabajador_servicios_extra
    │                  │  (borra las filas quitadas)
    │                  │────────────────────────►│
    │                  │  OK                     │
    │                  │◄────────────────────────│
    │  perfil listo    │                         │
    │◄─────────────────│                         │
```

La app escribe directamente en las tablas de la oferta; el catálogo y el cobro leen esas mismas filas.

---

## 11. Beneficios

- **Menos errores de copia:** los precios, los extras y el oficio tienen una sola fuente de lectura.
- **Onboarding medible:** el porcentaje es el mismo criterio que usa el listado (`canReceiveJobs`).
- **Alta más rápida:** tarifas por defecto + ruta automática a precios.
- **Auditoría:** la calificación del perfil se puede reconstruir desde `calificaciones`.
- **Seguridad:** las funciones `SECURITY DEFINER` no están expuestas a roles de cliente.

---

## 12. Límites y trabajo futuro

1. El checklist corre **en el cliente** (tres lecturas: perfil, trabajador, portafolio). Un RPC `estado_onboarding_trabajador(id)` unificaría la regla y evitaría que una versión vieja de la app liste con criterios distintos.
2. `handle_new_user` no crea `trabajadores`; un flujo “quiero ser trabajador” en un solo paso podría insertar la fila con categoría `general` y forzar el registro igual. Hoy se prefiere no crear filas vacías.
3. `trabajador_servicios` se llena con la categoría principal; los servicios extra siguen en filas de `trabajador_servicios_extra`, no en el catálogo `servicios.id`.
4. ~~La penalización por rechazos no está en SQL~~ **Hecho en v ranking:** `score_listado` se calcula en Postgres (`20261010000001_ranking_y_resenas.sql`). Ver `AUTOMATIZACION_RANKING_Y_RESENAS.md`.
5. `liquidaciones.id_trabajador` es `uuid` con clave foránea a `perfiles`; la automatización de perfil no la modifica.

---

## 13. Archivos de implementación

| Pieza | Ubicación |
|-------|-----------|
| Trigger de perfil Auth | `supabase/migrations/20260914000004_aplicar_rename_es.sql` (`handle_new_user`) |
| Calificación y tablas de la oferta (4FN) | `supabase/migrations/20261004000001_normalizar_y_optimizar.sql` |
| Oferta como única fuente y horarios publicados | `supabase/migrations/20261117214219_normalizar_oferta_profesional.sql`, `20261117214336_normalizar_horarios_publicados.sql` |
| RLS de `trabajadores` | `supabase/migrations/20260914000005_rls_politicas_negocio.sql` |
| Alta en app | `lib/features/worker/presentation/pages/worker_register_page.dart` |
| Enrutado por estado | `lib/core/utils/worker_navigation.dart` |
| Checklist | `lib/core/services/worker_onboarding_checklist_service.dart` |
| Tarjeta de progreso | `lib/features/worker/presentation/widgets/worker_onboarding_card.dart` |
| Repositorio | `lib/core/database/repositories/worker_repository.dart` |
| Ranking interno (cliente, respaldo) | `lib/core/services/worker_reputation_service.dart` |
| Ranking y reseñas (servidor + panel) | [AUTOMATIZACION_RANKING_Y_RESENAS.md](AUTOMATIZACION_RANKING_Y_RESENAS.md) |

---

## 14. Conclusión

La automatización del perfil de trabajador en MyWorksApp es **híbrida**:

- La **persona** define oficio, zona, texto, fotos y precios.
- El **servidor** crea el perfil de identidad y mantiene la calificación; la oferta vive en filas.
- La **app** conduce el onboarding y oculta del marketplace a quien no cumple los seis requisitos.

Con eso, el perfil publicado es una proyección consistente de datos que el profesional ya cargó, no un segundo mantenimiento paralelo.
