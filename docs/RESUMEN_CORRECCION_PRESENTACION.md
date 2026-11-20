# Resumen de Correcciones — Presentación de Defensa MyWorksApp

**Fecha:** 20 de noviembre de 2026  
**Estado:** ✅ Completado y pusheado a GitHub  
**Repositorio:** https://github.com/nicoussj/Proyecto-Titulo-MyWorksApp

---

## PUNTOS CORREGIDOS SEGÚN RETROALIMENTACIÓN DEL PROFESOR

### ✅ 1. DEFINICIÓN CLARA DE LA SOLUCIÓN REAL VS FUNCIONALIDADES

**Error detectado:** Se confundían pasos/funcionalidades con la solución en sí.

**Corrección aplicada:**
- **Diapositiva 3** ahora define explícitamente la solución:
  > "Una plataforma multiplataforma (Web + App Móvil + Consola) que conecta clientes y especialistas locales con:
  > 1. PAGO RETENIDO (ESCROW): 0% de fraude en pagos
  > 2. AGENDA GARANTIZADA: 0% de conflictos de horario
  > 3. EVIDENCIA OBLIGATORIA: Trazabilidad completa
  > 4. VERIFICACIÓN DE PROFESIONALES: Confianza en el catálogo"

- **Diapositiva 4** separa claramente "Cómo funciona: Los 7 Módulos" (búsqueda, reserva, pago, ciclo de vida, conformidad, calificación, consola)

**Archivo:** `docs/presentacion_defensa_corregida.md` (Diapositivas 3-4)

---

### ✅ 2. OBJETIVOS ESPECÍFICOS MEDIBLES (ESTILO CIENTÍFICO/TÉCNICO)

**Error detectado:** Objetivos redactados como funcionalidades sin métricas medibles.

**Corrección aplicada:**
- **Diapositivas 6-7** reescriben los 6 objetivos específicos con:
  - **Verbos medibles:** "Implementar", "Diseñar", "Integrar", "Validar"
  - **Métricas concretas:** "100% de tablas con RLS", "p95 < 800ms", "0 pruebas fallidas"
  - **Validación:** Cómo se mide cada objetivo (consulta SQL, k6, GitHub Actions)
  - **Resultados:** Estado actual verificado (ej. "641 de 641 pruebas OK")

**Ejemplos concretos:**
- **OE1:** "100% de las tablas con RLS activo" → Resultado: **60 de 60 tablas**
- **OE3:** "100% de pagos siguen ciclo retenido → liberado/reembolsado" → Resultado: **100% correcto**
- **OE6:** "0 pruebas fallidas; p95 < 800ms; Lighthouse ≥90" → Resultado: **641/641 OK; p95=283ms; Lighthouse 94/99**

**Archivo:** `docs/presentacion_defensa_corregida.md` (Diapositivas 6-7)

---

### ✅ 3. METODOLOGÍA SCRUM APLICADA AL EQUIPO (NO SOLO TEORÍA)

**Error detectado:** Solo se mencionaba "metodología ágil" sin nombre exacto ni cómo se aplicó.

**Corrección aplicada:**
- **Diapositiva 8** declara explícitamente **"Metodología Ágil Scrum"**
- Detalla cómo se aplicó en la práctica:
  - **Roles:** Product Owner (Mathias), Scrum Master (Mathias), Desarrollo (Mathias, Gabriel, Nicolas)
  - **Herramientas:** GitHub Projects (tablero), Discord (Daily Scrum)
  - **Ceremonias:** Sprint Planning, Daily (15min), Sprint Review y Retrospective (fines de semana)
  - **Evidencia en repo:** 228 commits (144 Mathias, 47 Gabriel, 24 Nicolas), 74 PRs, 30 mergeadas
  - **Sprints:** 11 sprints completados (1 sem en Fase 1, 2 sem en desarrollo, 1 sem en cierre)
  - **Definition of Done:** Funciona + revisado + CI verde + documentado

**Archivo:** `docs/presentacion_defensa_corregida.md` (Diapositiva 8)

---

### ✅ 4. MODELO DE DATOS (CONSISTENCIA DE TABLAS, DIVISIONES POR MÓDULO Y 4NF)

**Error detectado:** Inconsistencia numérica ("90 tablas" vs "43 mostradas"), diagrama gigante ilegible, sigla 4NF sin explicar.

**Corrección aplicada:**

**A. Número único y definitivo:**
- **60 tablas** en el esquema `public` (no 43, no 90)
- Fuente: Migraciones del repositorio al 20-nov-2026 (`main` commit `d9d2c7c`)
- **Diapositiva 10** muestra este número como definitivo

**B. División en 2 diapositivas:**
- **Diapositiva 10:** Vista general panorámica con las 60 tablas agrupadas en 9 módulos
- **Diapositiva 11:** Sub-vistas detalladas de 3 módulos principales (Trabajos/Citas, Pagos/Escrow, Usuarios/Reseñas) con diagramas ER focalizados

**C. Explicación de 4NF:**
- **Diapositiva 11** explica qué es 4NF (Cuarta Forma Normal: elimina dependencias multivaluadas)
- **Ejemplo concreto:** 
  - ❌ Incorrecto: `trabajadores (servicios[], precios[])` → Dependencia multivaluada
  - ✅ Correcto: `trabajador_servicios` + `trabajador_precios` separados → Cumple 4NF
- **Beneficio:** Evita anomalías al actualizar servicios/precios independientemente
- **Otras aplicaciones:** Horarios, dispositivos push, eventos de verificación

**Archivos:**
- `docs/presentacion_defensa_corregida.md` (Diapositivas 10-11)
- `docs/modelo_datos_presentacion.md` (documento técnico completo)

---

### ✅ 5. GUIÓN DE VIDEO INTRODUCTORIO + DEMOSTRACIÓN EN VIVO EN PANTALLA DIVIDIDA

**Corrección aplicada:**

**A. Estructura de la demostración (Diapositiva 14):**
1. **Video HD introductorio (2-3 min):** Recorrido rápido de Web + App + Consola
2. **Demo en vivo con pantalla dividida (10-12 min):** 
   - Pantalla izquierda: Web de cliente (Nicolás)
   - Pantalla derecha: App móvil de profesional (Mathias), proyectada con USB-C / Enlace Móvil

**B. Guión coordinado por tiempos (Diapositiva 15 + documento completo):**

| Minuto | Integrante | Qué dice/muestra |
|--------|------------|------------------|
| 0-2 | NICOLÁS | Video HD introductorio |
| 2-3 | MATHIAS | Problema y solución (diapositivas) |
| 3-5 | GABRIEL | Objetivos medibles (diapositivas) |
| 5-7 | NICOLÁS | Metodología Scrum (diapositivas) |
| 7-10 | GABRIEL | Arquitectura y modelo de datos (diapositivas) |
| 10-12 | MATHIAS | Implementación y validación (diapositivas) |
| 12-25 | NICOLÁS + MATHIAS | **Demo en vivo sincronizada** (flujo completo) |
| 25-28 | GABRIEL | [Opcional] Consola de administración |

**C. Flujo de la demo en vivo (minuto a minuto):**
- 13:00-14:30: Nicolás busca y filtra profesionales (web)
- 14:30-15:30: Nicolás ve perfil y reserva hora (web)
- 15:30-17:00: Nicolás paga con Webpay (dinero RETENIDO) (web)
- 17:00-18:00: Mathias acepta y avisa "voy en camino" (app)
- 18:00-19:00: Mathias comparte GPS en tiempo real (app)
- 19:00-19:30: Nicolás ve profesional en mapa (web)
- 19:30-20:00: Nicolás muestra PIN: 4821 (web)
- 20:00-20:30: Mathias ingresa PIN 4821 (app)
- 20:30-21:30: Mathias sube evidencia y finaliza (app)
- 21:30-22:00: Nicolás ve evidencia (web)
- 22:00-22:30: Nicolás aprueba → PAGO LIBERADO (web)
- 22:30-23:00: Mathias recibe notificación de pago (app)
- 23:00-24:00: Nicolás califica 5★ (web)
- 24:00-25:00: Mathias ve nueva calificación (app)

**D. Checklist técnico (Diapositiva 16 + documento completo):**

**Día anterior:**
- ✅ Video HD 1080p (no comprimir por WhatsApp)
- ✅ Setup proyección dual (Enlace Móvil / USB-C / emulador)
- ✅ Cuentas demo: `camila.soto@demo.myworksapp.cl` (cliente), `carmen.lagos@demo.myworksapp.cl` (profesional)
- ✅ Tarjeta Transbank integración: 4051 8856 0000 0002
- ✅ Ensayo completo 2 veces con timer

**30 min antes:**
- ✅ Laptop + proyector + teléfono con batería 100%
- ✅ Navegador con 2 pestañas: web cliente + diapositivas
- ✅ App móvil instalada
- ✅ Limpiar datos demo anteriores
- ✅ WiFi estable (backup: hotspot)

**Archivos:**
- `docs/presentacion_defensa_corregida.md` (Diapositivas 14-16)
- `docs/guion_demo_sincronizado.md` (guión completo con diálogos palabra por palabra)

---

## COMMITS REALIZADOS

### Commit 1: Solución, objetivos y Scrum
```
commit c9134cb
docs(ppt): clarify core solution, measurable objectives and Scrum workflow

- Define explícitamente la solución vs funcionalidades (escrow + agenda garantizada)
- Reescriben objetivos específicos con verbos medibles y métricas concretas
- Declaran Metodología Ágil Scrum con roles, herramientas y evidencia en repo
- Incluyen guión coordinado por tiempos para los 3 integrantes
- Agregan checklist técnico para demo en vivo con pantalla dividida
```

### Commit 2: Modelo de datos y 4NF
```
commit c2a1d4b
docs(ppt): align exact database table count and modular ERD breakdown

- Fijan número definitivo y real: 60 tablas (no 43, no 90)
- Dividen modelo en 9 módulos funcionales para legibilidad
- Explican 4NF con ejemplos concretos (trabajador_servicios vs precios)
- Muestran descomposición N:M sin dependencias multivaluadas
- Incluyen diagrama ER simplificado por módulo
```

### Commit 3: Guión sincronizado y demo
```
commit 1ce4b55
docs(ppt): add synchronized speaker script and dual-screen demo guide

- Agregan guión coordinado por tiempos minuto a minuto (28 min total)
- Distribuyen responsabilidades por integrante (Nicolás, Mathias, Gabriel)
- Incluyen setup técnico para demo con pantalla dividida (Web + App móvil)
- Detallan checklist de preparación (video HD, cuentas demo, conectividad)
- Anticipan preguntas frecuentes con respuestas asignadas por integrante
- Documentan reglas de coordinación y sincronización de voces
```

---

## ARCHIVOS CREADOS/ACTUALIZADOS

| Archivo | Contenido | Estado |
|---------|-----------|--------|
| `docs/presentacion_defensa_corregida.md` | Presentación completa con 21 diapositivas corregidas | ✅ Creado |
| `docs/modelo_datos_presentacion.md` | Documento técnico: 60 tablas, 9 módulos, 4NF explicada | ✅ Creado |
| `docs/guion_demo_sincronizado.md` | Guión palabra por palabra (28 min) + checklist técnico | ✅ Creado |

**Total:** 3 archivos nuevos, 2.250+ líneas de contenido corregido y estructurado.

---

## RESUMEN EJECUTIVO PARA EL EQUIPO

### QUÉ SE CORRIGIÓ

✅ **Solución definida claramente:** Escrow + agenda garantizada (no solo "app con funcionalidades")  
✅ **Objetivos medibles:** Todos con métricas concretas y resultados verificados  
✅ **Scrum aplicado:** No solo teoría, sino roles, herramientas y evidencia en repo  
✅ **60 tablas definitivas:** Número real, no inconsistente (43 vs 90)  
✅ **4NF explicada:** Con ejemplos concretos del modelo (trabajador_servicios vs precios)  
✅ **Guión sincronizado:** 28 minutos minuto a minuto, sin hablar uno encima del otro  
✅ **Checklist técnico:** Preparación día anterior + 30 min antes  

### CÓMO USAR ESTOS DOCUMENTOS

1. **Para crear las diapositivas en PowerPoint/Google Slides:**
   - Copiar el contenido de `docs/presentacion_defensa_corregida.md`
   - Cada sección "### Diapositiva X" es una diapositiva
   - Usar el diseño visual del PPT original, pero con el texto corregido

2. **Para la demostración en vivo:**
   - Leer y memorizar `docs/guion_demo_sincronizado.md`
   - Practicar el flujo completo 2 veces el día anterior
   - Revisar el checklist técnico y preparar todo con anticipación

3. **Para responder preguntas técnicas:**
   - Consultar `docs/modelo_datos_presentacion.md` (sección 4NF)
   - Consultar la sección "Preguntas frecuentes anticipadas" del guión

### PRÓXIMOS PASOS

1. ✅ Documentos corregidos y pusheados a GitHub
2. ⏳ **Crear/actualizar el PPT** en PowerPoint/Google Slides con el contenido corregido
3. ⏳ **Grabar video HD** introductorio (2-3 min, 1080p, sin comprimir)
4. ⏳ **Ensayar demo en vivo** 2 veces con timer
5. ⏳ **Preparar setup técnico** (proyector, Enlace Móvil, cuentas demo)

---

## CONTACTO

Para cualquier duda sobre los cambios:

- **Nicolás Chiguay:** nicolas.chiguay@duoc.cl (Documentación y UX)
- **Mathias Jara:** mathias.jara@duoc.cl (Product Owner y Frontend)
- **Gabriel Valderas:** gabriel.valderas@duoc.cl (Backend y Base de Datos)

---

**Documento generado:** 20 de noviembre de 2026, 18:55 (hora de Chile)  
**Estado:** ✅ Completado y sincronizado con GitHub  
**Versión:** 1.0 (final)
