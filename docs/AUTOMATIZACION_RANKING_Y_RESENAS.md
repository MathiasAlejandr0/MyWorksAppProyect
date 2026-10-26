# Automatización de ranking y reseñas

**Proyecto:** MyWorksApp  
**Módulo:** Orden del marketplace y confianza de las calificaciones  
**Versión:** 1.1  
**Fecha:** 2026-10-05  
**Alcance:** score de listado, prioridad manual, aprendizaje por resultados, detección de reseñas dudosas y corrección de falsos positivos  
**Migración:** `20261010000001_ranking_y_resenas.sql`  
**Documento hermano:** [AUTOMATIZACION_PERFILES_TRABAJADOR.md](AUTOMATIZACION_PERFILES_TRABAJADOR.md) (alta de ficha y nota derivada)

---

## 1. Objetivo

Documentar la **automatización que decide qué profesional aparece antes que otro** en MyWorksApp, y cómo el sistema **aprende solo** y **revisa reseñas dudosas** sin borrar opiniones reales por error (falso positivo).

El orden del marketplace no es un campo que el profesional edite. Es un score derivado (`trabajadores.score_listado`) que combina:

1. **Pesos configurables** por el administrador (qué importa más: nota, historial, verificación…).
2. **Prioridad manual** por persona (mostrar a A delante de B).
3. **Aprendizaje** a partir de trabajos bien cerrados frente a disputas y cancelaciones del profesional.
4. **Confianza de cada reseña** (`calificaciones.peso_confianza`), no el promedio crudo de estrellas.

La automatización cubre tres capas:

| Capa | Dónde ocurre | Qué resuelve |
|------|----------------|--------------|
| Configuración | Tabla `ranking_config` + panel admin | El operador elige los pesos y puede fijar prioridad para que un profesional salga primero |
| Aprendizaje | `aprender_pesos_ranking` + `eventos_ranking` | Los pesos se mueven solos según cierres reales; cada cambio queda en `ranking_aprendizaje` |
| Confianza | `evaluar_resena` + `senales_resena` | Cada reseña nueva se puntúa. Si es dudosa baja de peso; **no se oculta** hasta confirmar fraude |

Complementa la automatización de perfil: allí se **crea** la ficha y se **deriva** `calificacion`. Aquí se **ordena** el listado y se **filtra el ruido** de las reseñas.

---

## 2. Problema de negocio

Sin esta automatización:

1. El cliente ve primero a quien tiene más estrellas, aunque sean pocas o infladas.
2. Un administrador no puede decir “este profesional sale primero esta semana” sin editar a mano la nota. Esa nota es derivada: **no se debe editar**.
3. Una ráfaga de 5★, un comentario copiado o una cuenta nueva mueven el ranking.
4. Si el detector oculta de inmediato, se cometen **falsos positivos**: se esconden reseñas reales y el profesional baja sin motivo.
5. La penalización por rechazos vivía solo en Flutter (`WorkerReputationService`). Dos clientes o el catálogo RPC podían ordenar distinto.

La automatización **no inventa la nota pública**. El cliente sigue viendo estrellas desde `calificaciones`. Cambia el **orden** (`score_listado`) y el **peso** de cada reseña (`peso_confianza`).

Qué queda deliberadamente humano:

- Subir o bajar los pesos del listado.
- Fijar prioridad manual de un profesional.
- Marcar una reseña como fraude o como falsa alarma.
- Encender o apagar el aprendizaje automático.

---

## 3. Modelo de datos

```
ranking_config (1 fila: 'default')
        │
        │  pesos, umbrales, pesos_senal
        ▼
trabajadores.score_listado  ◄── refrescar_ranking_trabajador()
        ▲
        │  prioridad_manual, score_desglose
        │
calificaciones ──► senales_resena
        │                │
        │ peso_confianza │  pendiente | fraude_confirmado | falso_positivo
        │ estado_revision│
        ▼                ▼
   nota pública      cola admin
        │
trabajos / disputas / cancelaciones
        │
        ▼
eventos_ranking ──► aprender_pesos_ranking() ──► ranking_aprendizaje
```

### 3.1 Columnas nuevas en fichas ya existentes

| Tabla | Columna | Tipo | Rol |
|-------|---------|------|-----|
| `trabajadores` | `score_listado` | numeric(8,4) | Orden del marketplace. Mayor = más arriba |
| `trabajadores` | `prioridad_manual` | integer −50…50 | Override de admin. Se suma `× 2` al score |
| `trabajadores` | `score_desglose` | jsonb | Factores 0–1 usados en la fórmula y en el aprendizaje |
| `trabajadores` | `ranking_actualizado_en` | timestamptz | Último recálculo |
| `calificaciones` | `peso_confianza` | numeric 0–1 | Peso en el promedio y en Bayes |
| `calificaciones` | `estado_revision` | text | `vigente` \| `en_revision` \| `excluida` |
| `calificaciones` | `motivo_revision` | text | Señales que dispararon la revisión |

`calificacion` **sigue** en `trabajadores`. Ahora es el promedio **ponderado** de reseñas no excluidas, no el promedio simple.

### 3.2 Tablas nuevas

**`ranking_config`** — una sola fila `id = 'default'`.

| Campo | Default | Significado |
|-------|---------|-------------|
| `peso_calificacion` | 0,32 | Peso de la nota Bayesiana |
| `peso_completados` | 0,18 | Historial de trabajos terminados |
| `peso_rechazos` | 0,12 | Menos rechazos = más score |
| `peso_verificacion` | 0,10 | Cuenta verificada |
| `peso_impulso` | 0,08 | Boost vigente en `impulsos` |
| `peso_recencia` | 0,08 | Actividad reciente |
| `peso_confianza` | 0,12 | Calidad media de las reseñas |
| `prior_bayes` | 3,80 | Media a priori (como “8 reseñas invisibles”) |
| `n_bayes` | 8 | Tamaño de esa muestra a priori |
| `umbral_revision` | 0,55 | A partir de aquí la reseña entra a cola |
| `umbral_auto_excluir` | 0,90 | Riesgo para excluir sin esperar al admin |
| `aprendizaje_activo` | 1 | 0 = no mueve pesos solo |
| `tasa_aprendizaje` | 0,15 | Mezcla entre pesos actuales y aprendidos |
| `pesos_senal` | jsonb | Peso de cada tipo de señal de reseña |

Al guardar, los siete `peso_*` se **normalizan**: suman 1; ninguno baja de 0,03 ni sube de 0,50.

**`senales_resena`** — una fila por (reseña, tipo de señal).

| Campo | Valores |
|-------|---------|
| `tipo_senal` | ver sección 6 |
| `estado` | `pendiente` \| `fraude_confirmado` \| `falso_positivo` \| `descartada` |
| `puntaje` | Intensidad 0–1 de esa señal |
| `resuelto_por` / `resuelto_en` | Admin que cerró la cola |

**`eventos_ranking`** — foto de `score_desglose` en el momento del resultado.

| `tipo_evento` | Cuándo se inserta |
|---------------|-------------------|
| `contratado` | `trabajos.id_trabajador` pasa de nulo a un profesional |
| `completado_ok` | Estado `completado` y no hay disputa abierta |
| `disputado` | Alta en `disputas` |
| `cancelado_trabajador` | Canceló el profesional (`cancelaciones_trabajo`) |

**`ranking_aprendizaje`** — auditoría de cada recálculo de pesos (`pesos_antes`, `pesos_despues`, `metricas`).

---

## 4. Cómo se calcula quién aparece primero

### 4.1 Fórmula de `score_listado`

```
score_listado =
    100 × (
      w_calificación × f_calificacion
    + w_completados  × f_completados
    + w_rechazos     × f_rechazos
    + w_verificación × f_verificacion
    + w_impulso      × f_impulso
    + w_recencia     × f_recencia
    + w_confianza    × f_confianza
    )
  + prioridad_manual × 2
```

Cada `f_*` está en 0–1. El bloque ponderado queda en 0–100. La prioridad manual suma o resta hasta 100 puntos (±50 × 2), suficiente para **poner a un profesional delante** de pares con nota parecida.

El catálogo y la app ordenan `score_listado DESC`. A igualdad, `id_usuario ASC`.

### 4.2 Factores

| Factor | Cálculo | Lectura de negocio |
|--------|---------|-------------------|
| `f_calificacion` | `Bayes / 5` | Nota estable, no una sola 5★ |
| `f_completados` | `tanh(completados / 12)` | Crece rápido al inicio y se aplana |
| `f_rechazos` | `1 − min(rechazos × 0,12, 1)` | Rechazar invitaciones baja el puesto |
| `f_verificacion` | verificado 1 / en revisión 0,55 / otro 0,35 | Premia la cuenta revisada |
| `f_impulso` | 1 si hay `impulsos` vigente, si no 0 | Boost de visibilidad |
| `f_recencia` | `exp(−días_desde_último_completado / 45)` | Quien no cierra trabajos baja despacio |
| `f_confianza` | promedio de `peso_confianza` (0,50 si no hay reseñas) | Reseñas dudosas restan |

Esos valores se guardan en `score_desglose` para el aprendizaje y para auditoría.

### 4.3 Nota Bayesiana (por qué una 5★ no basta)

Sean:

- `m = prior_bayes` (3,80)
- `C = n_bayes` (8)
- `n` = suma de `peso_confianza` de reseñas no excluidas
- `avg` = promedio ponderado de esas reseñas

```
si n = 0:     Bayes = m × 0,55     (arranque frío, por debajo del prior)
si n > 0:     Bayes = (C × m + n × avg) / (C + n)
```

Ejemplo: un profesional con **una** reseña de 5,0 obtiene Bayes ≈ 3,91. Otro con **40** reseñas de 4,6 queda cerca de 4,6. El segundo sale antes en el factor de calificación.

### 4.4 Nota pública (`calificacion`)

```
calificacion = round( Σ(puntaje × peso_confianza) / Σ(peso_confianza) , 2)
```

solo con `estado_revision <> 'excluida'`. Si no hay reseñas vigentes, queda `0`. El cliente ve esa columna en la tarjeta; **no** ve `score_listado`.

### 4.5 Prioridad manual (mostrar a uno antes que a otro)

| Acción en **Trabajadores** | Efecto |
|----------------------------|--------|
| Mostrar más arriba | `prioridad_manual += 5` |
| Mostrar más abajo | `prioridad_manual −= 5` |
| Quitar prioridad manual | vuelve a `0` |

Rango −50…50. Solo el administrador, por RPC `fijar_prioridad_trabajador`. El profesional no puede escribir esa columna (REVOKE + trigger `proteger_campos_trabajador`).

Ejemplo: A tiene score automático 72 y B 70. Con `prioridad_manual = 5` sobre B, B pasa a 80 y **aparece primero**.

---

## 5. Aprendizaje automático

No es una red neuronal. Es un ajuste de pesos **dentro de PostgreSQL**, reproducible y auditable.

### 5.1 Qué observa

Cada evento de resultado guarda el `score_desglose` **de ese momento** (no el score actual, que ya habría cambiado).

Etiquetas usadas para aprender:

- Positivo: `completado_ok`
- Negativo: `disputado`, `cancelado_trabajador`

`contratado` se registra para trazabilidad; no entra en el recálculo de pesos.

### 5.2 Cuándo corre

- En automático: hay **al menos 12** eventos etiquetados en 120 días **y** el total etiquetado es múltiplo de 8.
- A mano: botón **Aprender ahora** en el panel (`aprender_pesos_ranking_admin`).
- Si `aprendizaje_activo = 0`, no se mueven los pesos solos. El admin sigue pudiendo configurarlos.

### 5.3 Cómo mueve los pesos

Para cada factor `f_i`:

1. Promedio de `f_i` en cierres buenos (`ok_i`) y en fallos (`bad_i`).
2. `delta_i = max(ok_i − bad_i + 0,08, 0,03)` y se normaliza para que sume 1.
3. Mezcla: `w_nuevo = (1 − tasa) × w_actual + tasa × delta` (`tasa` = 0,15 por defecto).
4. Se vuelve a aplicar el clamp 0,03–0,50 y la suma 1.
5. Se escribe `ranking_aprendizaje` y se recalcula `score_listado` de todos.

Lectura: si los profesionales que **cierran bien** tienen más verificación y más confianza de reseñas que los que entran en disputa, esos pesos **suben**. Si la nota cruda no separa buenos de malos, `peso_calificacion` **baja** un poco.

### 5.4 Lo que el aprendizaje no hace

- No cambia `prioridad_manual`.
- No borra reseñas.
- No entrena fuera de la base (no hay modelo pickle ni servicio Python).
- No corre si la muestra es chica (evita mover el marketplace con 3 trabajos).

---

## 6. Reseñas dudosas y falsos positivos

### 6.1 Señales (`evaluar_resena`)

Se ejecuta en el `INSERT` (y en cambios de puntaje/comentario) de `calificaciones`.

| Señal | Qué busca | Peso inicial |
|-------|-----------|--------------|
| `auto_resena` | El profesional se calificó a sí mismo | 1,00 |
| `sin_trabajo_valido` | El trabajo no está `completado` o el autor no es el cliente | 0,95 |
| `rafaga` | 3 o más reseñas extra al mismo profesional en 6 h | 0,45 |
| `cuenta_nueva` | Cuenta con menos de 48 h y nota 1 o 5 | 0,25 |
| `texto_vacio_extremo` | 1★ o 5★ sin comentario de al menos 8 caracteres | 0,20 |
| `duplicado_texto` | Mismo texto (normalizado) que otra reseña | 0,40 |
| `outlier` | Se aleja más de 2σ de la media del profesional (n ≥ 5) | 0,22 |
| `granja_cinco_estrellas` | El mismo cliente dio 5★ a 3 o más profesionales en 24 h | 0,50 |

Las reseñas **históricas no se re-evalúan** al aplicar la migración. Re-escanear el pasado llenaría la cola de falsos positivos. Solo entran las reseñas **nuevas**.

### 6.2 Riesgo combinado

```
riesgo = 1 − Π (1 − peso_señal_i)
```

solo con señales `pendiente` o `fraude_confirmado`.

| Riesgo | `estado_revision` | `peso_confianza` | Qué ve el cliente |
|--------|-------------------|------------------|-------------------|
| &lt; 0,55 | `vigente` | `max(1 − riesgo, 0,35)` | Se muestra |
| 0,55 … 0,90 | `en_revision` | `max(1 − riesgo, 0,15)` | **Se sigue mostrando** (peso bajo) |
| `auto_resena` / trabajo inválido, o riesgo ≥ 0,90 | `excluida` | 0 | No se lista en el perfil |

La regla de oro del falso positivo: **en revisión no se oculta**. El detector avisa; no ejecuta.

El insert de calificación del cliente ya exige trabajo `completado` y autor = cliente (RLS). `auto_resena` y `sin_trabajo_valido` son defensa en profundidad.

### 6.3 Cola del administrador

Panel → **Ranking y reseñas** → pestaña **Reseñas dudosas**.

| Acción | Efecto sobre la reseña | Efecto sobre el detector |
|--------|------------------------|--------------------------|
| **Es falsa alarma** (`falso_positivo`) | Si no quedan otras señales vivas, vuelve a `vigente` con peso 1 | El peso de **esa** señal baja ~15 % (mínimo 0,05) |
| **Confirmar fraude** (`fraude_confirmado`) | `excluida`, peso 0 | Esa señal **sube** (~12 % + 0,02, tope 0,90) |
| **Descartar** | Cierra la señal sin tratarla como fraude | No mueve `pesos_senal` |

`auto_resena` y `sin_trabajo_valido` **no** bajan de peso: son reglas duras, no heurísticas.

Cada resolución deja fila en `ranking_aprendizaje` con motivo `resolucion_senal`.

### 6.4 Definición de falso positivo (para la memoria)

En este módulo, **falso positivo** = reseña **legítima** que el detector marcó. El diseño asume que va a ocurrir (ráfagas reales después de un servicio masivo, notas extremas honestas sin texto, etc.). Por eso:

1. La cola es humana.
2. La reseña sigue visible mientras está `en_revision`.
3. Marcar falsa alarma **enseña** al detector (baja esa señal).

Fraude confirmado es el caso contrario: la reseña deja de contar y esa señal se vuelve más estricta.

---

## 7. Flujos de punta a punta

### 7.1 Calificación → listado

```
Cliente                 Flutter                    PostgreSQL
  │                        │                            │
  │  enviar reseña         │                            │
  │───────────────────────►│  INSERT calificaciones     │
  │                        │───────────────────────────►│
  │                        │                            │  evaluar_resena
  │                        │                            │  INSERT senales_resena
  │                        │                            │  UPDATE peso_confianza
  │                        │                            │  refrescar_ranking_trabajador
  │                        │  OK                        │
  │                        │◄───────────────────────────│
  │  estrellas públicas    │                            │
  │◄───────────────────────│                            │
```

La app **no** recalcula el ranking. Lee `score_listado` y `calificacion` ya escritos.

### 7.2 Resultado de trabajo → aprendizaje

```
Cambio de estado en trabajos / alta de disputa
        │
        ▼
_registrar_evento_ranking  (snapshot de score_desglose)
        │
        ▼
refrescar_ranking_trabajador
        │
        ▼
¿≥ 12 etiquetas y total múltiplo de 8?
        │ sí
        ▼
aprender_pesos_ranking
  UPDATE ranking_config
  INSERT ranking_aprendizaje
  refrescar_ranking_todos
```

### 7.3 Admin: “este sale primero”

```
Admin → Trabajadores → Mostrar más arriba
        │
        ▼
RPC fijar_prioridad_trabajador(id, prioridad)
        │
        ▼
UPDATE trabajadores.prioridad_manual
        │
        ▼
Trigger refrescar_ranking_ficha
        │
        ▼
score_listado incluye prioridad × 2
        │
        ▼
El siguiente listado ya lo muestra antes
```

---

## 8. Qué ve cada rol

| Rol | Qué puede hacer |
|-----|-----------------|
| Cliente | Ver estrellas públicas y reseñas no `excluida`. El orden del listado ya viene del servidor |
| Profesional | No edita nota, score ni prioridad. Ve su propia nota pública |
| Administrador | Pesos, aprendizaje on/off, “Aprender ahora”, prioridad por persona, cola de reseñas |

Pantallas:

| Pantalla | Ruta | Uso |
|----------|------|-----|
| Ranking y reseñas | `/admin/ranking` | Pesos (sliders), aprendizaje, cola de señales |
| Trabajadores | `/admin/workers` | Mostrar más arriba / abajo / quitar prioridad |
| Panel | `/admin` | Acceso + badge con señales pendientes |

En **Pesos del listado**, guardar **normaliza** los sliders y recalcula a todos los profesionales.

---

## 9. Seguridad

| Control | Detalle |
|---------|---------|
| `is_admin()` | Todas las RPC de config, prioridad, cola y aprendizaje |
| RLS | `ranking_config`, `senales_resena`, `ranking_aprendizaje`: SELECT solo admin |
| `eventos_ranking` | Sin GRANT a `authenticated`; solo el trigger `SECURITY DEFINER` |
| REVOKE UPDATE | `score_listado`, `prioridad_manual`, `score_desglose`, `ranking_actualizado_en` |
| Trigger | `proteger_campos_trabajador` también cubre esas columnas |
| `evaluar_resena` / `aprender_pesos_ranking` | Sin EXECUTE para `anon`/`authenticated` (salvo wrappers admin) |
| Catálogo | `listar_profesionales_catalogo` ordena por score; no expone `pesos_senal` |

El cliente **no** puede inflarse el ranking escribiendo su ficha.

---

## 10. Invariantes

| Invariante | Cómo se sostiene |
|------------|------------------|
| La nota pública no la escribe el profesional | Trigger + REVOKE de `calificacion` |
| El orden no depende de una sola 5★ | Bayes + `n` efectivo con `peso_confianza` |
| Un admin puede poner a A delante de B | `prioridad_manual` |
| Una reseña dudosa no desaparece sola | `en_revision` sigue visible |
| El detector se suaviza si se equivoca | Falsa alarma baja `pesos_senal` |
| El cliente no configura pesos | RPC con `is_admin()` |
| El aprendizaje es auditable | `ranking_aprendizaje` |
| El mismo orden en app y catálogo | Ambos usan `score_listado` |

---

## 11. RPCs y triggers

| Función | Quién la llama | Para qué |
|---------|----------------|----------|
| `refrescar_ranking_trabajador(uuid)` | Triggers | Recalcula un profesional |
| `refrescar_ranking_todos_admin()` | Admin | Recalcula todos |
| `evaluar_resena(text)` | Trigger de `calificaciones` | Señales + peso |
| `obtener_config_ranking()` | Panel | Leer pesos |
| `guardar_config_ranking(jsonb)` | Panel | Guardar pesos y recalcular |
| `fijar_prioridad_trabajador(uuid, int)` | Panel trabajadores | Override −50…50 |
| `listar_senales_resena(estado, limit)` | Panel cola | Listado de señales |
| `resolver_senal_resena(id, estado)` | Panel cola | Fraude / falsa alarma / descartar |
| `aprender_pesos_ranking_admin()` | Botón Aprender ahora | Ciclo de pesos |
| `listar_profesionales_catalogo(...)` | Catálogo público | `ORDER BY score_listado DESC` |

Triggers:

| Trigger | Tabla | Efecto |
|---------|-------|--------|
| `calificaciones_refrescar_trabajador` | `calificaciones` | Evalúa reseña + refresca ranking |
| `trabajos_eventos_ranking` | `trabajos` | Eventos contratado / completado / cancelado |
| `disputas_eventos_ranking` | `disputas` | Evento `disputado` |
| `impulsos_refrescar_ranking` | `impulsos` | Recalcula al crear/cambiar boost |
| `trabajadores_refrescar_ranking` | `trabajadores` | Recalcula si cambian rechazos, verificación o prioridad |

---

## 12. Cómo aplicarlo y cómo probarlo

1. Aplicar en Supabase la migración  
   `MyWorksAppProyect/myworksapp_app/supabase/migrations/20261010000001_ranking_y_resenas.sql`.
2. Entrar al panel como administrador.
3. Abrir **Ranking y reseñas**: deben verse los sliders (32 % calificación, etc.).
4. En **Trabajadores**, “Mostrar más arriba” a un profesional y comprobar que su `prioridad_manual` sube y que en el listado de clientes aparece antes.
5. Completar un trabajo y calificar: la reseña entra a `calificaciones`; si dispara señal, aparece en la cola **sin desaparecer del perfil** (salvo exclusión dura).
6. Marcar **Es falsa alarma** y verificar que `pesos_senal` de esa heurística bajó.
7. Con 12+ cierres etiquetados, **Aprender ahora**: debe aparecer una fila nueva en `ranking_aprendizaje`.

Sin la migración, la app falla al ordenar por `score_listado` (la columna no existe).

---

## 13. Límites y trabajo futuro

1. El aprendizaje usa el desglose **en el momento del evento**, no un modelo externo.
2. No hay cron: un impulso vencido se refleja cuando alguien recalcula (evento de trabajo, guardar pesos, o “Aprender ahora”).
3. `listar_profesionales_catalogo` pagina por `score_listado`; el parámetro sigue llamándose `p_cursor_calificacion` por compatibilidad.
4. No hay job que re-evalue reseñas viejas (a propósito).
5. Futuro posible: snapshot de ranking visto por el cliente (`impresion_listado`) para medir si el orden predice la contratación, no solo el cierre.

---

## 14. Archivos de implementación

| Pieza | Ubicación |
|-------|-----------|
| Migración SQL | `myworksapp_app/supabase/migrations/20261010000001_ranking_y_resenas.sql` |
| Este documento | `Fase 2/AUTOMATIZACION_RANKING_Y_RESENAS.md` |
| Copia en docs | `MyWorksAppProyect/docs/AUTOMATIZACION_RANKING_Y_RESENAS.md` |
| Panel de pesos y cola | `lib/features/admin/presentation/pages/admin_ranking_page.dart` |
| Prioridad por persona | `lib/features/admin/presentation/pages/admin_workers_page.dart` |
| Entrada del panel | `lib/features/admin/presentation/pages/admin_dashboard_page.dart` |
| Modelos | `lib/core/database/models/ranking_models.dart` |
| RPC Flutter | `lib/core/database/repositories/ranking_repository.dart` |
| Orden en listados | `lib/core/services/worker_reputation_service.dart` |
| Consultas de trabajadores | `lib/core/database/repositories/worker_repository.dart` |
| Reseñas públicas (oculta `excluida`) | `lib/core/database/repositories/rating_repository.dart` |
| ER | `Fase 2/MODELO_ENTIDAD_RELACION.md` (v2.3, 41 tablas) y `modelo_entidad_relacion.dbml` |

---

## 15. Glosario

| Término | Significado en este módulo |
|---------|----------------------------|
| Score de listado | Número interno de orden; no se muestra al cliente |
| Prioridad manual | Entero de admin para forzar el puesto |
| Bayes | Nota suavizada con prior 3,80 y 8 “reseñas” a priori |
| Peso de confianza | 0–1 con el que esa reseña entra al promedio |
| Señal | Heurística que sugiere que una reseña es rara |
| En revisión | Dudosa pero **visible** |
| Excluida | No cuenta ni se muestra |
| Falso positivo | Reseña real marcada por el detector |
| Aprendizaje | Ajuste de `w_*` según cierres vs disputas |

---

## 16. Conclusión

La automatización de ranking y reseñas en MyWorksApp es **híbrida**:

- El **administrador** configura qué vale más y puede poner a un profesional delante de otro.
- El **servidor** calcula el score, suaviza las notas nuevas, baja el peso de reseñas dudosas y, con muestra suficiente, mueve los pesos según resultados reales.
- El **cliente** ve estrellas y un listado ya ordenado; no ve el score interno ni las señales.
- El **falso positivo** se trata como error del detector: la reseña sigue visible y, al corregirse, esa heurística pierde fuerza.

Con eso, el marketplace deja de ser “el que tenga más 5★ sube” y pasa a un orden **explicable, configurable y auditable**, alineado con el cierre real del trabajo.
