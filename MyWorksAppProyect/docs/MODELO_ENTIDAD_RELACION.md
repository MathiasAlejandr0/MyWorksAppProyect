# Modelo entidad-relación

El modelo ER vigente (52 tablas, 78 claves foráneas, migración `20261116044049`) está en
[`Fase 2/modelo_entidad_relacion/`](../../Fase%202/modelo_entidad_relacion/LEEME.txt):

- `figuras/er_00_dominios`: mapa de los 7 dominios.
- `figuras/er_00_general`: las 52 tablas con su PK y todas las FK.
- `figuras/er_01` a `er_07`: un diagrama por dominio con columnas, tipos, PK/FK y cardinalidad.
- `modelo_er.dbml` (dbdiagram.io), `modelo_er_postgres.sql`, `modelo_er_mysql_workbench.sql` y `fuentes/*.dot`.
- `LEEME.txt` explica la notación, los dominios, las relaciones lógicas sin FK y cómo regenerar todo.

La explicación de cada dominio, el flujo de pago y escrow y las decisiones de diseño están en la
sección 2b de [`DICCIONARIO_BASE_DATOS.md`](DICCIONARIO_BASE_DATOS.md) (3b en el `.docx`).

![Mapa de dominios](../../Fase%202/modelo_entidad_relacion/figuras/er_00_dominios.png)
