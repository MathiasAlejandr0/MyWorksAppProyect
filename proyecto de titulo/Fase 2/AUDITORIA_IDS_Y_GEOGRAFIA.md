# Auditoría de IDs y normalización geográfica

**Proyecto:** MyWorksApp  
**Fecha:** 2026-10-05  
**Esquema:** PostgreSQL `public`  
**Alcance:** claves (PK/FK), `id_comuna` / ciudad / país, y alineación del modelo ER v2.2

---

## Hallazgo principal

`trabajos.id_comuna` **existía y se usaba** (slug tipo `providencia`, `puerto_montt`, `santiago`) **sin tabla destino**. `trabajadores.zona_trabajo` era un **texto libre** (a veces comuna, a veces “Región Metropolitana (todas)”). No había `paises`, `regiones` ni `comunas`.

Eso viola 3NF: el mismo territorio se repetía en strings de la app (`ChileComunas`, `inferComunaKey`) y no se podía referenciar con integridad.

**Corrección:** migración `20261009000001_catalogo_geografico.sql` + ER v2.2.

```
paises 1──N regiones 1──N comunas
                              ▲
              trabajadores.id_comuna
              trabajos.id_comuna
trabajadores.id_region ──► regiones   (cobertura “(todas)”)
```

---

## IDs bien puestos (PK reales)

| Tabla | PK | Tipo | Veredicto |
|-------|----|------|-----------|
| perfiles | id | uuid = auth.users.id | Correcto. 1:1 con Auth |
| trabajadores | id_usuario | uuid FK perfiles | Correcto. 1:1 |
| servicios | id | text | Correcto (catálogo) |
| comunas | id | text slug | Correcto (coincide con `id_comuna` de la app) |
| regiones | id | text (`rm`, `ll`, …) | Correcto |
| paises | id | text (`CL`) | Correcto |
| trabajador_servicios | (id_trabajador, categoria_servicio) | compuesto | Correcto |
| trabajador_precios | (id_usuario, codigo) | compuesto 4NF | Correcto en el modelo lógico |
| trabajador_servicios_extra | (id_usuario, id) | compuesto 4NF | Correcto en el modelo lógico |
| configuraciones_servicio | id + UNIQUE id_servicio | 1:0..1 | Correcto |
| cancelaciones_trabajo | id + UNIQUE id_trabajo | 1:0..1 | Correcto |
| liquidaciones | id + UNIQUE id_pago | 1:0..1 | Correcto |
| ubicacion_en_vivo | id_trabajo | 1:1 con trabajos | Correcto |
| app_config | clave | text | Correcto |
| metodos_pago_oneclick | id_usuario | text = auth.uid | Aceptable (solo service_role) |

---

## IDs que eran (o son) problemáticos

| Columna | Antes | Ahora | Riesgo residual |
|---------|-------|-------|-----------------|
| trabajos.id_comuna | text **sin FK** | FK → `comunas.id` | Slugs desconocidos se anulan al migrar |
| trabajadores.zona_trabajo | texto libre, no ID | se mantiene UI; FKs `id_comuna` / `id_region` | La app aún escribe el texto; el trigger rellena FKs |
| trabajadores.id_comuna | no existía | FK → comunas | — |
| trabajadores.id_region | no existía | FK → regiones (cobertura regional) | — |
| ubicacion_en_vivo.id_trabajador | uuid **sin FK** | FK → trabajadores | Corregido en la misma migración |
| id_sku_servicio | text en trabajos, **sin tabla SKU** | sin cambio | Columna huérfana. No hay catálogo de SKU |
| liquidaciones.id_trabajador | text vs uuid | sin cambio | No puede ser FK física |
| liquidaciones.id_operador | text, sin FK a perfiles | sin cambio | Debería ser uuid → perfiles.id |
| metodos_pago_oneclick.id_usuario | text vs uuid | sin cambio | Intencional (auth.uid::text) |
| trabajador_precios.id_usuario (BD viva) | **text**, sin FK uuid | modelo ER usa uuid+FK | Desajuste físico vs lógico 4NF |
| notificaciones.id_relacionado | polimórfico | sin cambio | No es FK (apunta a trabajo u otra entidad) |
| acciones_pendientes.id_entidad | polimórfico | sin cambio | No es FK |
| pagos.id_transaccion | id externo Transbank | sin cambio | No debe ser FK interna |
| trabajos.id_sku_servicio | huérfano | pendiente | Crear `skus_servicio` o borrar la columna |

FKs de “trabajador” en el dump inglés apuntaban a `profiles.id`. El modelo de negocio (y el ER) las trata como `trabajadores.id_usuario`.

---

## Geografía: qué había en la app

| Fuente | Qué guardaba |
|--------|----------------|
| `trabajos.id_comuna` | slug: `providencia`, `puerto_montt`, default `santiago` (`inferComunaKey`) |
| `trabajadores.zona_trabajo` | nombre visible: `Providencia`, `Puerto Montt`, `Región Metropolitana (todas)` |
| `ChileComunas` | lista hardcodeada en Dart (RM, Los Lagos, otras ciudades) |
| GPS `20261006` | centros lat/lng de algunas comunas, **inline en el SQL**, no en tabla |

No había entidad **ciudad** aparte: en Chile la unidad municipal es la **comuna** (Valparaíso, Puerto Montt y Concepción son comunas). Por eso no se creó `ciudades`.

---

## Tablas nuevas (normalización)

| Tabla | PK | FK | Rol |
|-------|----|----|-----|
| paises | id | — | Hoy `CL` |
| regiones | id | id_pais → paises | RM, Los Lagos, Valparaíso, … |
| comunas | id (slug) | id_region → regiones | Destino de `id_comuna` |

Seed: comunas de `ChileComunas` + slugs de `inferComunaKey` + coordenadas del GPS.

También se incorporaron al ER (ya estaban en migraciones posteriores a v2.1):

- `ubicacion_en_vivo` (GPS del pedido)
- `app_config` (interruptores)

---

## Conteos

| Versión ER | Tablas public |
|------------|----------------|
| v1.6 | 28–29 |
| v2.1 (4NF oferta) | 32 |
| **v2.2 (geo + GPS + config)** | **37** |

Migración a aplicar en Supabase: `20261009000001_catalogo_geografico.sql`.

---

## Qué no se tocó (a propósito)

1. Mezcla **uuid / text** en PKs históricas (trabajos, pagos, mensajes son `text`). Cambiarlo es una migración de datos distinta.
2. Booleanos `0/1` e ISO en `text`.
3. JSON de escritura en `trabajadores`.
4. `id_sku_servicio` — no hay evidencia de filas de SKU en el catálogo vivo.
5. `service_pricing` del baseline inglés: no aparece en el rename ES ni en el dump remoto usado por las apps.

---

## Archivos actualizados

| Artefacto | Ruta |
|-----------|------|
| Migración BD | `myworksapp_app/supabase/migrations/20261009000001_catalogo_geografico.sql` |
| SQL de modelado | `Fase 2/modelo_entidad_relacion.sql` |
| DBML | `Fase 2/modelo_entidad_relacion.dbml` |
| Memoria ER | `Fase 2/MODELO_ENTIDAD_RELACION.md` |
| Vista HTML | `Fase 2/modelo_entidad_relacion.html` |
| Esta auditoría | `Fase 2/AUDITORIA_IDS_Y_GEOGRAFIA.md` |
