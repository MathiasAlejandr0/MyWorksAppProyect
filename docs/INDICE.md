# Índice de la documentación de MyWorksApp

Este índice ordena toda la documentación del repositorio por tema. Fase vigente: Fase 3 del Capstone PTY4614 (pruebas, informe final y demostración), al 22 de noviembre de 2026, 23:07 hora de Chile. El detalle vivo está en `MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`. No hay carpeta ni plantilla de estudiante de la Fase 3.

**Si es tu primera vez, lee en este orden:**

1. [`README.md`](../README.md): qué es el proyecto y cómo está organizado el repositorio.
2. [`MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`](../MyWorksAppProyect/ESTADO_DEL_PROYECTO.md): qué funciona hoy, qué falta y qué está en ramas sin integrar.
3. [`Fase 2/Myworksapp_Informe_Final_PTY4614.pdf`](../Fase%202/Myworksapp_Informe_Final_PTY4614.pdf): el informe final del proyecto de título.

## Contenido

- [1. Producto y estado](#1-producto-y-estado)
- [2. Instalar, demostrar y desplegar](#2-instalar-demostrar-y-desplegar)
- [3. Componentes del software](#3-componentes-del-software)
- [4. Requisitos y casos de uso](#4-requisitos-y-casos-de-uso)
- [5. Base de datos](#5-base-de-datos)
- [6. Pagos, correo y operación](#6-pagos-correo-y-operación)
- [7. Pruebas](#7-pruebas)
- [8. Gestión del proyecto (Scrum)](#8-gestión-del-proyecto-scrum)
- [9. Entregables académicos](#9-entregables-académicos)
- [10. Documentos históricos](#10-documentos-históricos)

## 1. Producto y estado

| Documento | Para qué sirve |
|---|---|
| [`README.md`](../README.md) | Resumen del proyecto, objetivos, arquitectura y estructura del repositorio |
| [`MyWorksAppProyect/README.md`](../MyWorksAppProyect/README.md) | El monorepo de software: partes, arquitectura y cómo ejecutarlo |
| [`MyWorksAppProyect/ESTADO_DEL_PROYECTO.md`](../MyWorksAppProyect/ESTADO_DEL_PROYECTO.md) | Estado vigente, inventario contado desde el código, pendientes y ramas sin integrar |
| [`docs/product_vision.md`](product_vision.md) | Visión del producto |

## 2. Instalar, demostrar y desplegar

| Documento | Para qué sirve |
|---|---|
| [`MyWorksAppProyect/INSTALL.md`](../MyWorksAppProyect/INSTALL.md) | Instalar la app, la web y la consola; secretos de las Edge Functions |
| [`MyWorksAppProyect/DEMO.md`](../MyWorksAppProyect/DEMO.md) | Guion de la demostración y cuentas demo |
| [`MyWorksAppProyect/docs/deploy_web.md`](../MyWorksAppProyect/docs/deploy_web.md) | Despliegue de la web en Vercel, dominio, Turnstile y correo |
| [`MyWorksAppProyect/docs/FIRMA_RELEASE_ANDROID.md`](../MyWorksAppProyect/docs/FIRMA_RELEASE_ANDROID.md) | Firma del APK de Android |

## 3. Componentes del software

| Componente | Documento |
|---|---|
| App móvil Flutter | [`MyWorksAppProyect/myworksapp_app/README.md`](../MyWorksAppProyect/myworksapp_app/README.md) |
| Web de clientes | [`MyWorksAppProyect/myworksapp_web/README.md`](../MyWorksAppProyect/myworksapp_web/README.md) |
| Consola de escritorio | [`MyWorksAppProyect/myworksapp_desktop/README.md`](../MyWorksAppProyect/myworksapp_desktop/README.md) |
| Arquitectura de cobro | [`MyWorksAppProyect/docs/ARQUITECTURA_MODALIDADES_COBRO.md`](../MyWorksAppProyect/docs/ARQUITECTURA_MODALIDADES_COBRO.md) |
| Notificaciones push (no desplegadas) | [`MyWorksAppProyect/docs/PUSH_NOTIFICACIONES.md`](../MyWorksAppProyect/docs/PUSH_NOTIFICACIONES.md) |
| Perfiles, ranking y reseñas | [`AUTOMATIZACION_PERFILES_TRABAJADOR.md`](../MyWorksAppProyect/docs/AUTOMATIZACION_PERFILES_TRABAJADOR.md) y [`AUTOMATIZACION_RANKING_Y_RESENAS.md`](../MyWorksAppProyect/docs/AUTOMATIZACION_RANKING_Y_RESENAS.md) |
| Maquetas y video | [`docs/mockups/`](../MyWorksAppProyect/docs/mockups/README.md) y [`docs/video/flujo_app.md`](../MyWorksAppProyect/docs/video/flujo_app.md) |

## 4. Requisitos y casos de uso

| Documento | Para qué sirve |
|---|---|
| [`docs/objetivos.md`](objetivos.md) | Objetivo general y objetivos específicos |
| [`docs/requisitos_no_funcionales.md`](requisitos_no_funcionales.md) | Requisitos no funcionales |
| [`MyWorksAppProyect/docs/casos_de_uso.md`](../MyWorksAppProyect/docs/casos_de_uso.md) | Los 34 casos de uso, las reglas RN-01 a RN-23 y la trazabilidad al código |
| [`MyWorksAppProyect/docs/uml/`](../MyWorksAppProyect/docs/uml/README.md) | Modelos UML; los diagramas por paquete están en `uml/paquetes/` |
| [`docs/solucion.md`](solucion.md) | Cómo resuelve cada módulo los casos de uso |

## 5. Base de datos

| Documento | Para qué sirve |
|---|---|
| [`MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md`](../MyWorksAppProyect/docs/DICCIONARIO_BASE_DATOS.md) | Diccionario: 60 tablas con columnas y, en la sección 0-bis, las 15 leídas el 22-11 |
| [`MyWorksAppProyect/docs/MODELO_ENTIDAD_RELACION.md`](../MyWorksAppProyect/docs/MODELO_ENTIDAD_RELACION.md) | Modelo entidad-relación. Las figuras siguen en 60 tablas; el catálogo del 22-11 midió 76 |
| [`MyWorksAppProyect/docs/modelo-datos.md`](../MyWorksAppProyect/docs/modelo-datos.md) y [`normalizacion.md`](../MyWorksAppProyect/docs/normalizacion.md) | Modelo de datos y formas normales |
| [`myworksapp_app/supabase/MIGRATIONS_INVENTORY.md`](../MyWorksAppProyect/myworksapp_app/supabase/MIGRATIONS_INVENTORY.md) | Inventario de migraciones. El 22-11 el repo tiene 133 archivos y la base viva llega a `20261123020000` |
| [`Fase 2/Anexo_A_Diccionario_de_tablas.md`](../Fase%202/Anexo_A_Diccionario_de_tablas.md) | Anexo A del informe: una tabla por cada tabla de la base |

## 6. Pagos, correo y operación

| Documento | Para qué sirve |
|---|---|
| [`MyWorksAppProyect/docs/RUNBOOK_TRANSBANK_PRODUCCION.md`](../MyWorksAppProyect/docs/RUNBOOK_TRANSBANK_PRODUCCION.md) | Paso de Transbank a producción |
| [`MyWorksAppProyect/docs/RUNBOOK_PAYOUT.md`](../MyWorksAppProyect/docs/RUNBOOK_PAYOUT.md) | Liquidación al profesional |
| [`MyWorksAppProyect/docs/deploy_web.md`](../MyWorksAppProyect/docs/deploy_web.md) | Correo con Resend, soporte@ e invitaciones |
| [`MyWorksAppProyect/docs/RUNBOOK_CAPACIDAD_CARGA.md`](../MyWorksAppProyect/docs/RUNBOOK_CAPACIDAD_CARGA.md) y [`RUNBOOK_ESCALA_20K_USUARIOS.md`](../MyWorksAppProyect/docs/RUNBOOK_ESCALA_20K_USUARIOS.md) | Capacidad y escala |

## 7. Pruebas

| Documento | Para qué sirve |
|---|---|
| [`MyWorksAppProyect/docs/PRUEBAS.md`](../MyWorksAppProyect/docs/PRUEBAS.md) | **Empieza aquí.** Pruebas unitarias, de rendimiento y estrés del 19 y 20-11 (P-17): 641 de 641, punto de quiebre, cuello de botella, hallazgo H1 y recomendaciones |
| [`anexos/2026-11-20-pruebas-unitarias-rendimiento/`](../MyWorksAppProyect/docs/anexos/2026-11-20-pruebas-unitarias-rendimiento/INFORME_PRUEBAS.md) | Informe completo de esas pruebas y las figuras del informe final |
| [`MyWorksAppProyect/docs/anexos/2026-11-15-pruebas/REGISTRO.md`](../MyWorksAppProyect/docs/anexos/2026-11-15-pruebas/REGISTRO.md) | Registro de pruebas del 15-11 (histórico) |
| [`MyWorksAppProyect/docs/pruebas/`](../MyWorksAppProyect/docs/pruebas/) | Pruebas de seguridad, rendimiento, estrés, carga y auditoría de la base (históricas) |
| Informe final, capítulo de pruebas | Fichas P-01 a P-17; la P-16 es la revisión del 20-11 y la P-17, las pruebas unitarias, de rendimiento y estrés |

## 8. Gestión del proyecto (Scrum)

| Documento | Para qué sirve |
|---|---|
| [`docs/metodologia.md`](metodologia.md) | Metodología y sprints |
| [`docs/product_backlog.md`](product_backlog.md) | Product backlog |
| [`docs/sprint_backlog.md`](sprint_backlog.md) | Sprint 10 y lo pendiente para cerrarlo |
| [`docs/retrospectiva.md`](retrospectiva.md) | Retrospectiva y lo que queda abierto |

## 9. Entregables académicos

Cada carpeta tiene un README con el mismo listado. El informe vigente es
[`Fase 2/Myworksapp_Informe_Final_PTY4614.docx`](../Fase%202/Myworksapp_Informe_Final_PTY4614.docx)
y su [PDF](../Fase%202/Myworksapp_Informe_Final_PTY4614.pdf). No hay carpeta `Fase 3/`.

### Fase 1

| Documento | Ruta |
|---|---|
| Definición del proyecto | [`Fase 1/Evidencias Grupales/Definicion Proyecto APT - Fase 1_ My Works App.docx`](../Fase%201/Evidencias%20Grupales/Definicion%20Proyecto%20APT%20-%20Fase%201_%20My%20Works%20App.docx) |
| Guía del estudiante (Fase 1) | [`1.5_GuiaEstudiante_…docx`](../Fase%201/Evidencias%20Grupales/1.5_GuiaEstudiante_Fase%201_Definicion%20Proyecto%20APT%20(Español).docx) |
| Formativa 1.4 | [`1.4_APT122_FormativaFase1.docx`](../Fase%201/Evidencias%20Grupales/1.4_APT122_FormativaFase1.docx) |
| Planilla de evaluación | [`PLANILLA DE EVALUACIÓN FASE 1.xlsx`](../Fase%201/Evidencias%20Grupales/PLANILLA%20DE%20EVALUACIÓN%20FASE%201.xlsx) |
| Presentación | [`Presentación Proyecto.pptx`](../Fase%201/Evidencias%20Grupales/Presentación%20Proyecto.pptx) |
| Evidencias individuales | [`Fase 1/Evidencias Individual/`](../Fase%201/Evidencias%20Individual/) |

### Fase 2

| Documento | Ruta |
|---|---|
| Informe final (vigente) | [`.docx`](../Fase%202/Myworksapp_Informe_Final_PTY4614.docx) y [`.pdf`](../Fase%202/Myworksapp_Informe_Final_PTY4614.pdf) |
| Guía del estudiante (informe final) | [`2.6_GuiaEstudiante_…docx`](../Fase%202/2.6_GuiaEstudiante_Fase%202_Informe%20Final%20Proyecto%20APT.docx) |
| Desarrollo del proyecto 2.4 | [`2.4_DesarrolloProyecto_APT_MyWorksApp.docx`](../Fase%202/2.4_DesarrolloProyecto_APT_MyWorksApp.docx) |
| Guía de usuario | [`.pdf`](../Fase%202/Guia_de_Usuario_MyWorksApp.pdf) y [`.docx`](../Fase%202/Guia_de_Usuario_MyWorksApp.docx) |
| Casos de uso | [`Casos_de_uso_MyWorksApp.docx`](../Fase%202/Casos_de_uso_MyWorksApp.docx) |
| Anexo A (diccionario) | [`Anexo_A_Diccionario_de_tablas.md`](../Fase%202/Anexo_A_Diccionario_de_tablas.md) |
| Auditoría de la base | [`.pdf`](../Fase%202/Auditoria_BD_MyWorksApp.pdf) y [`.docx`](../Fase%202/Auditoria_BD_MyWorksApp.docx) |
| Prueba de carga | [`Prueba_de_carga_MyWorksApp.docx`](../Fase%202/Prueba_de_carga_MyWorksApp.docx) |
| Presentación final | [`.pdf`](../Fase%202/Presentacion_final_MyWorksApp.pdf) y [`.pptx`](../Fase%202/Presentacion_final_MyWorksApp.pptx) |
| Pauta de la demo | [`.pdf`](../Fase%202/Pauta_presentacion_demo.pdf) |
| Diarios de reflexión | [`Fase 2/`](../Fase%202/) (Chiguay, Jara, Valderas) |
| Modelo ER y figuras | [`modelo_entidad_relacion/`](../Fase%202/modelo_entidad_relacion/) y [`figuras/`](../Fase%202/figuras/) |

### Guías y planificación

| Documento | Ruta |
|---|---|
| Autenticación por roles | [`Documentos Guia/`](../Documentos%20Guia/) |
| Políticas RLS | [`Documentos Guia/`](../Documentos%20Guia/) |
| Plantilla de autoevaluación Fase 1 | [`1.3_APT122_AutoevaluacionFase1_plantilla.docx`](../Documentos%20Guia/1.3_APT122_AutoevaluacionFase1_plantilla.docx) |
| Carta Gantt (markdown) | [`CARTA_GANTT_ACTUALIZADA.md`](CARTA_GANTT_ACTUALIZADA.md) |
| Carta Gantt (MS Project) | [`Capstone_Project.mpp`](Capstone_Project.mpp) |
| Defensa (guion y corrección) | [`guion_demo_sincronizado.md`](guion_demo_sincronizado.md), [`presentacion_defensa_corregida.md`](presentacion_defensa_corregida.md) |

## 10. Documentos históricos

Los documentos que empiezan con «**Documento histórico.**» registran el estado a una fecha y no se actualizan. Sirven como evidencia, no como referencia del estado actual. Son, entre otros: `AUDITORIA_*`, `APLICAR_*`, `CHECKLIST_REPARACIONES`, `REMEDIACION_AUDITORIA`, `VERIFICACION_BD_REMOTA`, `schema_inferido_backup`, `mapa_esquema_en_es`, `PLAN_MIGRACIONES`, los archivos de `docs/pruebas/` y los anexos de pruebas del 08-11 y del 15-11.
