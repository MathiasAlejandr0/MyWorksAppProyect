# Casos de uso de MyWorksApp (UML)

Diagramas de casos de uso derivados de `docs/casos_de_uso.md` (34 casos, CU-01 a CU-34).
Están pensados para imprimirse en **papel carta** (ancho útil ≈ 16,5 cm) con texto de al menos 14 pt.

No hay un diagrama «completo» con los 34 casos: esa vista resulta ilegible a tamaño carta.
En su lugar hay un **diagrama de contexto** (actores ↔ paquetes) y **un diagrama por paquete**.

## Archivos

| Archivo | Contenido |
| --- | --- |
| `00_contexto` | Contexto: 7 paquetes, sin casos individuales. Generalización Cliente invitado / Cliente registrado → Visitante. |
| `01_busqueda_reserva` | CU-05, CU-06, CU-07. CU-08 aparece fuera del límite (include). |
| `02_gestion_profesional` | CU-25, CU-26, CU-27. |
| `03_pagos_escrow` | CU-08, CU-09, CU-10, CU-15, CU-17, CU-20. Include 09→08, extend 10→09. |
| `04a_seguimiento` | CU-11, CU-12, CU-13, CU-14, CU-16. |
| `04b_comunicacion` | CU-18, CU-19, CU-21, CU-23, CU-24. CU-17 aparece fuera del límite (extend). |
| `05_reagendamiento` | CU-33. |
| `06_administracion` | CU-22, CU-28, CU-29, CU-30, CU-31, CU-32, CU-34. CU-21 aparece fuera del límite (extend 22→21). |
| `07_seguridad_auth` | CU-01, CU-02, CU-03, CU-04. |

Cada diagrama tiene fuente PlantUML (`.puml`), figura de impresión PNG (2400 px de ancho) y SVG.

El modelo semántico (actores, casos, asociaciones, include, extend, paquetes y generalizaciones) está en:

- `MyWorksApp_casos_de_uso.mdj` — proyecto nativo de StarUML, con los 9 diagramas ya posicionados (actores a los lados, casos en una columna, sin solaparse).
- `casos_de_uso.xmi` — XMI 2.1, UML 2.4.1, espacio de nombres `http://www.omg.org/spec/UML/20110701`.

## Cómo abrirlos

- **StarUML (recomendado):** Archivo → Abrir → `MyWorksApp_casos_de_uso.mdj`. En el explorador del modelo aparecen los nueve diagramas. Los nombres de los casos son «CU-xx Nombre completo».
- **Importar XMI** (StarUML, Enterprise Architect o Visual Paradigm): Archivo → Importar → XMI y elige `casos_de_uso.xmi`. La importación trae el modelo; los diagramas con layout de impresión están en el `.mdj` y en los PNG/SVG.
- **PlantUML:** cada `00_…`–`07_….puml` es la fuente del diagrama correspondiente (`left to right`, fuente 16, `linetype ortho`). Las figuras de tesis son los PNG/SVG, renderizados para que el texto siga siendo legible al bajar el ancho a 16,5 cm.
- **Imprimir en carta:** coloca el PNG a 16,5 cm de ancho (márgenes laterales de 2 cm en hoja letter). El texto de los casos queda en torno a 14 pt.

## Relaciones entre paquetes

- CU-07 *incluye* CU-08 (el pago queda en el paquete de pagos; en el diagrama 01 aparece fuera del límite).
- CU-09 *incluye* CU-08; CU-10 *extiende* CU-09.
- CU-18 y CU-21 *extienden* CU-17 (el conformidad/pago queda en pagos; en el diagrama 04b aparece fuera del límite).
- CU-22 *extiende* CU-21 (la apertura de la disputa queda en comunicación; en el diagrama 06 aparece fuera del límite).
