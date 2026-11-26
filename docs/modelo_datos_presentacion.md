# Modelo de Datos — Presentación Técnica
## MyWorksApp — PostgreSQL con RLS

**Fecha del cuerpo:** 20 de noviembre de 2026 (`main` `d9d2c7c`, 60 tablas contadas desde el DDL)  
**Lectura del 22-11-2026:** la base viva tiene 76 tablas y 94 claves foráneas. Este documento no se reescribió tabla por tabla. La forma normal de las 15 tablas nuevas no se reclasificó. La 4FN del texto de abajo aplica a las listas del profesional, no al esquema completo.  
**Fuente del cuerpo:** migraciones en `myworksapp_app/supabase/migrations/` y `MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md` sección 0-bis.

---

## Número Definitivo de Tablas

### Estado Actual del Esquema `public`

| Métrica | Valor | Fuente |
|---------|-------|--------|
| **Tablas totales** | **60** | Migraciones hasta `20261120220000` |
| Columnas totales | 481 | Conteo desde DDL |
| Claves foráneas físicas | 86 | Conteo desde DDL |
| Políticas RLS | 132 | Migraciones con `CREATE POLICY` |
| Tipos ENUM | 1 | `accion_auditoria_consola` (27 valores) |
| Vistas | 2 | `encuestas_testing_con_puntaje`, `cobros_profesional` |
| Última migración | `20261120220000` | `catalogo_stats_una_consulta_y_realtime.sql` |

**Consistencia:** No decimos "vamos en 90" ni mostramos 43. El número real y verificado es **60 tablas**.

---

## División Modular del Modelo de Datos

### Agrupación por Dominio de Negocio

Para facilitar la comprensión, las 60 tablas se dividen en **9 módulos funcionales**:

---

### 1. MÓDULO USUARIOS/AUTENTICACIÓN (9 tablas)

**Propósito:** Gestión de identidades, perfiles, roles y consentimientos.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `perfiles` | Perfil base de usuario (cliente o trabajador) | → `auth.users.id` (Supabase Auth) |
| `trabajadores` | Datos específicos del rol profesional | `id_usuario` → `perfiles.id` |
| `consentimientos_usuario` | Aceptación de términos y privacidad | `id_usuario` → `perfiles.id` |
| `bloqueos_usuario` | Suspensiones y reactivaciones | `id_usuario` → `perfiles.id` |
| `verificacion_eventos` | Histórico de verificaciones del profesional | `id_trabajador` → `trabajadores.id` |
| `invitaciones_colaborador` | Invitaciones a equipo interno (admin/soporte) | `email` → futuro `perfiles.email` |
| `direcciones_cliente` | Direcciones guardadas del cliente (web) | `id_usuario` → `perfiles.id` |
| `exportacion_datos` | Solicitudes de exportación GDPR | `id_usuario` → `perfiles.id` |
| `eliminacion_cuenta` | Solicitudes de eliminación GDPR | `id_usuario` → `perfiles.id` |

**Reglas de negocio:**
- Un `perfil` puede ser cliente, trabajador o ambos (campo `rol`)
- Un `trabajador` requiere verificación (`estado_verificacion`) para aparecer en catálogo
- Consentimientos obligatorios antes del primer uso (`terminos_aceptados_en`)

---

### 2. MÓDULO TRABAJOS/CITAS (12 tablas)

**Propósito:** Ciclo de vida completo del trabajo, desde reserva hasta cierre.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `trabajos` | Trabajo central (solicitud → ejecución → cierre) | `id_cliente` → `perfiles.id`<br>`id_trabajador` → `trabajadores.id`<br>`id_pago` → `pagos.id` |
| `trabajador_horarios` | Horario semanal publicado del profesional | `id_trabajador` → `trabajadores.id` |
| `trabajador_horas_publicadas` | Horas específicas disponibles para reservar | `id_trabajador` → `trabajadores.id` |
| `pines_inicio_trabajo` | PIN de 4 dígitos para iniciar trabajo | `id_trabajo` → `trabajos.id` |
| `intentos_pin_inicio` | Registro de intentos (máx 5, bloqueo 15min) | `id_trabajo` → `trabajos.id` |
| `bloqueos_pin_inicio` | Bloqueos tras 5 intentos fallidos | `id_trabajo` → `trabajos.id` |
| `fotos_trabajo` | Evidencia fotográfica/video (bucket privado) | `id_trabajo` → `trabajos.id` |
| `reprogramaciones_trabajo` | Cambios de hora acordados | `id_trabajo` → `trabajos.id` |
| `ordenes_cambio` | Cobros adicionales aprobados por cliente | `id_trabajo` → `trabajos.id`<br>`id_pago` → `pagos.id` |
| `propuestas_cotizacion` | Cotizaciones abiertas (RFP) | `id_trabajo` → `trabajos.id` |
| `propuesta_cotizacion_items` | Ítems desglosados de la cotización | `id_propuesta` → `propuestas_cotizacion.id` |
| `cancelaciones_trabajo` | Registro de cancelaciones con motivo | `id_trabajo` → `trabajos.id` |

**Máquina de estados de `trabajos.estado`:**
```
pendiente → esperando_pago → aceptado → en_camino → 
en_progreso → esperando_aprobacion_cliente → 
completado (o cancelado / disputa_activa)
```

**Reglas de negocio:**
- No se inicia sin PIN correcto (RN-11, RN-12)
- No se finaliza sin evidencia (RN-16)
- Imposible doble reserva del mismo profesional en el mismo minuto (RN-08)

---

### 3. MÓDULO PAGOS/ESCROW (8 tablas)

**Propósito:** Pago protegido con Transbank y liquidación al profesional.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `pagos` | Pago central con escrow | `id_cliente` → `perfiles.id`<br>`id_trabajo` → `trabajos.id` (nullable) |
| `liquidaciones` | Transferencia al profesional (manual) | `id_pago` → `pagos.id`<br>`id_trabajador` → `trabajadores.id` |
| `metodos_pago_oneclick` | Tarjeta inscrita (Transbank Oneclick) | `id_usuario` → `perfiles.id` |
| `cuentas_bancarias` | Cuenta bancaria del profesional | `id_trabajador` → `trabajadores.id` |
| `rate_limit_ventana` | Límite de tasa por IP/correo (anti-fraude) | Sin FK (clave = IP o correo) |
| `disputas` | Conflictos sobre trabajos | `id_trabajo` → `trabajos.id` |
| `disputa_mensajes` | Chat de la mediación | `id_disputa` → `disputas.id` |
| `acuerdos_trabajo` | Resolución de disputa | `id_trabajo` → `trabajos.id` |

**Estados de `pagos.estado_escrow`:**
```
pendiente → por_confirmar → autorizado (RETENIDO) → 
liberado (tras conformidad) OR reembolsado (tras disputa/cancelación)
```

**Comisión:** 5% del pago principal (mínimo $1.000, máximo el pago completo). Órdenes de cambio: 8%.

**Reglas de negocio:**
- Dinero retenido hasta conformidad del cliente o 48h de silencio con evidencia (RN-13)
- Reembolso solo una vez (RN-05)
- Pago se frena si descripción/dirección/chat contienen datos de contacto (RN-15, migración `20261120120000`)

---

### 4. MÓDULO CALIFICACIONES/REPUTACIÓN (7 tablas)

**Propósito:** Sistema de calificaciones bidireccional y algoritmo de ranking.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `calificaciones` | Cliente califica al profesional (1-5 estrellas) | `id_trabajo` → `trabajos.id`<br>`id_calificador` → `perfiles.id`<br>`id_trabajador` → `trabajadores.id` |
| `calificaciones_cliente` | Profesional califica al cliente | `id_trabajo` → `trabajos.id`<br>`id_calificador` → `trabajadores.id`<br>`id_cliente` → `perfiles.id` |
| `senales_resena` | Señales de sospecha de fraude/spam | `id_calificacion` → `calificaciones.id` |
| `ranking_config` | Configuración de pesos del algoritmo | Singleton (1 fila) |
| `ranking_aprendizaje` | Histórico de ajustes del ranking | Sin FK |
| `eventos_ranking` | Bitácora de cambios de ranking | `id_trabajador` → `trabajadores.id` |
| `encuestas_testing` | Encuesta SUS para validación | Sin FK |
| `encuesta_testing_respuestas` | Respuestas individuales | `id_encuesta` → `encuestas_testing.id` |

**Algoritmo de reputación:**
```
puntaje = Σ(estrellas × peso_confianza) / Σ(peso_confianza)
```

**Peso de confianza:** Se calcula con señales de la reseña (longitud, antigüedad de cuenta, coincidencia con otras reseñas, etc.).

---

### 5. MÓDULO GEOLOCALIZACIÓN (4 tablas)

**Propósito:** Ubicación en tiempo real, catálogo geográfico y traslados.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `ubicacion_en_vivo` | GPS del profesional (actualizado cada 20s) | `id_trabajo` → `trabajos.id` |
| `comunas` | Catálogo de comunas de Chile | `id_region` → `regiones.id` |
| `regiones` | Catálogo de regiones de Chile | `id_pais` → `paises.id` |
| `paises` | Catálogo de países | Sin FK |

**Orden del catálogo (función `listar_profesionales_catalogo`):**
1. Cercanía (bandas de 1 km desde ubicación del cliente)
2. Calificación (nota pública)
3. Precio (tarifa de visita)
4. ID (desempate estable)

---

### 6. MÓDULO CHAT/NOTIFICACIONES (3 tablas)

**Propósito:** Comunicación en tiempo real y notificaciones push.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `mensajes` | Chat por trabajo | `id_trabajo` → `trabajos.id`<br>`id_emisor` → `perfiles.id` |
| `notificaciones` | Centro de notificaciones | `id_usuario` → `perfiles.id` |
| `dispositivos_push` | Tokens FCM para push remoto | `id_usuario` → `perfiles.id` |

**Filtro de contacto:** El chat bloquea teléfonos, correos, URLs y usuarios de redes sociales (RN-15).

---

### 7. MÓDULO SERVICIOS/CATÁLOGO (6 tablas)

**Propósito:** Catálogo de oficios, precios y portafolio.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `servicios` | Catálogo de servicios (plomería, electricidad, etc.) | `id_categoria` → `categorias_servicio.id` |
| `categorias_servicio` | Categorías de alto nivel | Sin FK |
| `trabajador_servicios` | Servicios que ofrece el profesional (N:M) | `id_trabajador` → `trabajadores.id`<br>`id_servicio` → `servicios.id` |
| `trabajador_precios` | Precios por servicio del profesional | `id_trabajador` → `trabajadores.id`<br>`id_servicio` → `servicios.id` |
| `portafolio_trabajador` | Fotos del portafolio público | `id_trabajador` → `trabajadores.id` |
| `trabajador_zona_cobertura` | Zonas donde trabaja el profesional | `id_trabajador` → `trabajadores.id`<br>`id_comuna` → `comunas.id` |

**Regla 4NF aplicada aquí:** Ver sección siguiente.

---

### 8. MÓDULO ADMINISTRACIÓN (6 tablas)

**Propósito:** Configuración, bitácoras y herramientas operativas.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `auditoria_consola` | Bitácora inmutable de acciones de administración | `id_actor` → `perfiles.id` (sin FK físico) |
| `banderas_funcionalidad` | Feature flags (activar/desactivar funciones) | Sin FK |
| `registros_error_app` | Errores reportados desde las apps | `id_usuario` → `perfiles.id` |
| `eventos_analitica` | Eventos de uso (telemetría) | `id_usuario` → `perfiles.id` |
| `reportes` | Reportes de abuso | `id_reportante` → `perfiles.id` |
| `eventos_abuso` | Bitácora de sanciones | `id_usuario` → `perfiles.id` |

**Bitácora de auditoría:** Solo se inserta con `registrar_auditoria()`. Nadie tiene permiso de escritura directa.

---

### 9. MÓDULO SOPORTE (2 tablas)

**Propósito:** Sistema de tickets y soporte automático.

| Tabla | Descripción | Relaciones principales |
|-------|-------------|------------------------|
| `tickets_soporte` | Tickets de soporte técnico | `id_usuario` → `perfiles.id` |
| `app_config` | Configuración global (singleton) | Sin FK |

---

## Cuarta Forma Normal (4NF)

### ¿Qué es 4NF?

**Definición formal:**
> Una tabla está en **Cuarta Forma Normal (4NF)** si está en Tercera Forma Normal (3NF) y **no contiene dependencias multivaluadas no triviales**.

**Dependencia multivaluada:** Cuando una columna depende de otra pero no de la clave completa, y pueden existir múltiples valores independientes.

**Ejemplo de violación de 4NF:**

❌ **Incorrecto (viola 4NF):**
```sql
CREATE TABLE trabajadores_mal (
  id UUID PRIMARY KEY,
  nombre TEXT,
  servicios TEXT[],  -- Array: ['Plomería', 'Electricidad']
  precios INTEGER[]  -- Array: [15000, 20000]
);
```

**Problema:** Los servicios y los precios son independientes entre sí, pero están en la misma fila. Si queremos:
- Agregar un servicio → debemos tocar el array de precios
- Cambiar un precio → debemos sincronizar el índice con servicios
- Eliminar un servicio → debemos eliminar el precio correspondiente

Esto crea **anomalías de actualización y dependencias multivaluadas**.

---

### Aplicación de 4NF en MyWorksApp

✅ **Correcto (cumple 4NF):**

**Descomposición en 3 tablas:**

```sql
-- 1. Tabla principal (sin arrays)
CREATE TABLE trabajadores (
  id UUID PRIMARY KEY,
  nombre TEXT,
  -- ... otros campos
);

-- 2. Relación N:M con servicios (SIN precios)
CREATE TABLE trabajador_servicios (
  id UUID PRIMARY KEY,
  id_trabajador UUID REFERENCES trabajadores(id),
  id_servicio UUID REFERENCES servicios(id),
  UNIQUE(id_trabajador, id_servicio)
);

-- 3. Precios SEPARADOS (independientes de la relación N:M)
CREATE TABLE trabajador_precios (
  id UUID PRIMARY KEY,
  id_trabajador UUID REFERENCES trabajadores(id),
  id_servicio UUID REFERENCES servicios(id),
  tarifa_clp INTEGER NOT NULL,
  UNIQUE(id_trabajador, id_servicio)
);
```

**Beneficio:**
- ✅ Agregar un servicio sin afectar precios: `INSERT INTO trabajador_servicios`
- ✅ Cambiar un precio sin afectar servicios: `UPDATE trabajador_precios`
- ✅ Eliminar un servicio: `DELETE FROM trabajador_servicios` (precio opcional)
- ✅ Sin anomalías: cada concepto en su tabla

---

### Otras Aplicaciones de 4NF en el Modelo

**1. Horarios independientes de servicios:**

❌ **Mal:**
```sql
trabajadores (id, servicios[], horarios[])  -- Dependencia multivaluada
```

✅ **Bien:**
```sql
trabajadores (id, ...)
trabajador_servicios (id_trabajador, id_servicio)
trabajador_horarios (id_trabajador, dia_semana, hora_inicio, hora_fin)
```

**2. Dispositivos push independientes de notificaciones:**

❌ **Mal:**
```sql
perfiles (id, fcm_tokens[], notificaciones[])  -- Dependencia multivaluada
```

✅ **Bien:**
```sql
perfiles (id, ...)
dispositivos_push (id_usuario, fcm_token, plataforma)
notificaciones (id_usuario, titulo, cuerpo, creado_en)
```

**3. Eventos de verificación independientes del estado actual:**

❌ **Mal:**
```sql
trabajadores (id, estado_verificacion, eventos_verificacion[])  -- Anomalía
```

✅ **Bien:**
```sql
trabajadores (id, estado_verificacion)
verificacion_eventos (id_trabajador, evento, creado_en, motivo)
```

---

### Resumen: 4NF en MyWorksApp

| Tabla | Concepto descompuesto | Antes (violaba 4NF) | Después (cumple 4NF) |
|-------|----------------------|---------------------|----------------------|
| `trabajador_servicios` + `trabajador_precios` | Servicios vs Precios | `servicios[]` + `precios[]` en una tabla | 2 tablas independientes |
| `trabajador_horarios` | Horarios vs Servicios | `horarios[]` en `trabajadores` | Tabla separada |
| `dispositivos_push` | Dispositivos vs Notificaciones | `fcm_tokens[]` en `perfiles` | Tabla separada |
| `verificacion_eventos` | Histórico vs Estado actual | `eventos[]` en `trabajadores` | Tabla separada |

**Conclusión:** Las relaciones N:M descompuestas en listas propias **cumplen 4FN**. El esquema completo no se declara en 4FN: el piso auditado el 16-11 es 2FN y tres tablas se quedan ahí a propósito. Ver `MyWorksAppProyect/docs/normalizacion.md`.

---

## Diagrama ER Simplificado (Vista General)

```
┌─────────────────────────────────────────────────────────────────┐
│                    MÓDULO USUARIOS/AUTH (9)                     │
│  perfiles ─→ trabajadores ─→ verificacion_eventos              │
│     │                │                                           │
│     ├─→ consentimientos_usuario                                 │
│     ├─→ bloqueos_usuario                                        │
│     ├─→ direcciones_cliente                                     │
│     └─→ invitaciones_colaborador                                │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   MÓDULO TRABAJOS/CITAS (12)                    │
│         trabajos ←─ pines_inicio_trabajo                        │
│            │     ←─ intentos_pin_inicio                         │
│            │     ←─ bloqueos_pin_inicio                         │
│            │     ←─ fotos_trabajo                               │
│            │     ←─ reprogramaciones_trabajo                    │
│            │     ←─ ordenes_cambio                              │
│            │     ←─ propuestas_cotizacion                       │
│            │     ←─ cancelaciones_trabajo                       │
│            │                                                     │
│         trabajador_horarios                                     │
│         trabajador_horas_publicadas                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    MÓDULO PAGOS/ESCROW (8)                      │
│  pagos ─→ liquidaciones                                         │
│    │   ─→ metodos_pago_oneclick                                │
│    │                                                             │
│  disputas ─→ disputa_mensajes                                   │
│           ─→ acuerdos_trabajo                                   │
│                                                                 │
│  cuentas_bancarias                                              │
│  rate_limit_ventana                                             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│               MÓDULO CALIFICACIONES/REPUTACIÓN (7)              │
│  calificaciones ─→ senales_resena                               │
│  calificaciones_cliente                                         │
│  ranking_config                                                 │
│  ranking_aprendizaje                                            │
│  eventos_ranking                                                │
│  encuestas_testing ─→ encuesta_testing_respuestas              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                 MÓDULO GEOLOCALIZACIÓN (4)                      │
│  ubicacion_en_vivo                                              │
│  paises ─→ regiones ─→ comunas                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│               MÓDULO CHAT/NOTIFICACIONES (3)                    │
│  mensajes                                                        │
│  notificaciones                                                  │
│  dispositivos_push                                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                MÓDULO SERVICIOS/CATÁLOGO (6)                    │
│  categorias_servicio ─→ servicios ←─┐                          │
│                                      │                          │
│  trabajador_servicios ───────────────┤  (4NF aplicada aquí)    │
│  trabajador_precios ─────────────────┘                          │
│  portafolio_trabajador                                          │
│  trabajador_zona_cobertura                                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   MÓDULO ADMINISTRACIÓN (6)                     │
│  auditoria_consola (inmutable)                                  │
│  banderas_funcionalidad                                         │
│  registros_error_app                                            │
│  eventos_analitica                                              │
│  reportes                                                        │
│  eventos_abuso                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      MÓDULO SOPORTE (2)                         │
│  tickets_soporte                                                │
│  app_config (singleton)                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Seguridad: Row Level Security (RLS)

**Estado:** 60 de 60 tablas con RLS activo (100%)  
**Políticas:** 132 políticas activas

**Principio:** Cada usuario solo accede a sus propios datos.

**Ejemplos de políticas:**

1. **Tabla `trabajos`:**
   - Cliente lee solo sus propios trabajos
   - Profesional lee solo sus propios trabajos
   - Administrador lee todos los trabajos

2. **Tabla `pagos`:**
   - Cliente lee solo sus propios pagos
   - Solo `service_role` puede liberar/reembolsar

3. **Tabla `auditoria_consola`:**
   - Solo administradores pueden leer
   - Nadie puede escribir directamente (solo via `registrar_auditoria()`)

**Validación:** Suite de 207 pruebas SQL (pgTAP) que verifican accesos denegados por rol.

---

## Normalización

**Estado del modelo:**

| Forma Normal | Cumplimiento | Verificación |
|--------------|--------------|--------------|
| **1NF** | ✅ 100% | Valores atómicos, sin arrays de datos relacionales |
| **2NF** | ✅ 100% | Dependencias de toda la clave primaria |
| **3NF** | ✅ 100% | Sin dependencias transitivas |
| **4FN** | Solo las listas N:M | El resto del esquema no se declara en 4FN |

**Documento completo:** [`MyWorksAppProyect/docs/normalizacion.md`](../MyWorksAppProyect/docs/normalizacion.md)

---

## Referencias Técnicas

- **Diccionario completo:** `MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`
- **Modelo ER:** `Fase 2/modelo_entidad_relacion.dbml`
- **Migraciones:** `MyWorksAppProyect/myworksapp_app/supabase/migrations/`
- **Inventario de migraciones:** `MyWorksAppProyect/myworksapp_app/supabase/MIGRATIONS_INVENTORY.md`

---

**Documento generado:** 20 de noviembre de 2026  
**Versión:** 1.0 (definitiva para presentación)  
**Autores:** Equipo MyWorksApp — Duoc UC Puerto Montt
