# Roadmap de IA (fases 5 a 8)

Estas fases **no están implementadas**. Hace falta más historia real de la que hay hoy. La base de las fases 0 a 4 (`eventos`, `mv_stats_profesional`, embeddings y las alertas) es la que después las alimenta.

Nada de esto se entrena con RUT ni con datos que identifiquen a una persona. El conjunto de entrenamiento sale anonimizado: identificadores opacos, comuna agregada, categoría y conteos. El consentimiento `ia-datos-2026` tiene que cubrir el uso para mejorar el ranking y los precios.

## Fase 5. Ranking con LightGBM

**Cuándo.** Entre 300 y 500 contrataciones con resultado conocido (completada, cancelada o en disputa).

**Datos, ya previstos.**

- `eventos` de tipo `busqueda`, `click`, `vista_perfil` y `contratacion`, con `categoria` y `comuna`.
- `mv_stats_profesional`: nota, trabajos, tasa de cancelación, tiempo de respuesta y disputas.
- Distancia que ya calcula `buscar_profesionales_hibrido`.
- Embedding del perfil, solo cuando `embedding_origen` es `gte-small`. Si el modelo no corrió, la columna está vacía.

**Etiqueta.** Hubo contratación después del click, en la misma sesión o en 7 días.

**Cómo se conecta.** Un job offline entrena LightGBM y escribe pesos en `ia_pesos_busqueda` o en una tabla nueva de scores. `buscar_profesionales_hibrido` ya lee esos pesos. Hasta entonces el orden sigue siendo la fórmula fija (similitud, cercanía, nota, confiabilidad). El modelo no publica solo: un administrador carga los pesos con `consola_editar_peso_busqueda`, que deja bitácora.

## Fase 6. Precios y demanda

**Cuándo.** Unos 6 meses de `trabajos` con `instantanea_precio`, comuna y categoría, más las cancelaciones.

**Datos.** Precio cobrado, categoría, comuna, mes, urgencia que el asistente haya sugerido y si el pedido se completó.

**Cómo se conecta.** El asistente hoy devuelve un rango fijo por categoría (`precio_min_clp`, `precio_max_clp`). Esa salida se reemplaza por un intervalo estimado, siempre marcado como sugerencia. No cambia la tarifa guardada del profesional.

## Fase 7. Bandits y aprendizaje por refuerzo

**Cuándo.** El ranking de la fase 5 ya está en producción y hay tráfico de búsqueda cada semana. Antes, un bandit no tiene qué explorar.

**Datos.** La lista que se mostró, la posición y el `click` o la `contratacion` en `eventos`.

**Cómo se conecta.** El bandit elige entre variantes de pesos ya auditadas. No inventa una acción que bloquee a alguien. El premio es el click o la contratación, no el monto en bruto, para no empujar precios.

## Fase 8. Agentes

**Cuándo.** Después de las fases 5 a 7, con las herramientas de solo lectura ya medidas.

**Límite.** Un agente puede armar un borrador de solicitud, un resumen o una alerta. No libera pagos, no cierra disputas y no aprueba documentos. Esas acciones siguen en la consola, con motivo y bitácora, como el módulo de Seguridad de hoy.

## Qué mirar antes de empezar

1. Volumen de `eventos` por tipo, sin datos personales.
2. Porcentaje de perfiles con embedding `gte-small`. El resto está en null, en la cola.
3. Que `mv_stats_profesional` se refresque cada hora.
4. Consentimiento vigente y un conjunto anonimizado aparte del de producción.
