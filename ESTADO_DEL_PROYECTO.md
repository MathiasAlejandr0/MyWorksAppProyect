# Estado del proyecto — MyWorksApp

Documento de referencia para **presentaciones universitarias**, **financiamiento** y **planificación técnica**.  
Última actualización alineada con la versión demo **offline-first** en repositorio `main`.

---

## Resumen ejecutivo

| Aspecto | Estado |
|---------|--------|
| **Tipo de producto** | MVP móvil funcional (Flutter) |
| **Modo de operación** | Offline-first: datos en SQLite local del dispositivo |
| **Listo para demo en vivo** | Sí, en un solo teléfono |
| **Listo para producción / App Store** | No — requiere backend, pagos y despliegue en nube |
| **Documentación de uso e instalación** | Sí ([README.md](README.md), [DEMO.md](DEMO.md), [INSTALL.md](INSTALL.md)) |

**Mensaje clave para jurados o financistas:** la app demuestra el **modelo de negocio y la experiencia de usuario**; el financiamiento y las tecnologías universitarias permiten pasar de prototipo local a **plataforma multiusuario en la nube**.

---

## Lo que tiene la aplicación (implementado)

### 1. Plataforma y arquitectura base

| Componente | Detalle |
|------------|---------|
| Framework | Flutter / Dart 3+ |
| Estado | Riverpod |
| Navegación | GoRouter |
| Persistencia | SQLite con sqlcipher |
| Roles | Usuario y trabajador en una sola app |
| Inicialización | Bootstrap, migraciones de BD, seeder demo al arranque |
| Seguridad local | Contraseñas hasheadas (bcrypt / migración desde SHA-256) |
| Sesión | Persistencia de sesión entre aperturas de la app |

### 2. Autenticación y cuentas

| Funcionalidad | Estado |
|---------------|--------|
| Registro de usuario | ✅ |
| Registro de trabajador | ✅ (+ pantalla de perfil profesional) |
| Inicio y cierre de sesión | ✅ |
| Recuperación de contraseña (flujo local) | ✅ |
| Cuentas demo precargadas | ✅ (`usuario@demo.com`, `trabajador@demo.com`, `demo123`) |
| Botón “Entrar con demo” | ✅ |
| Selector de rol en login | ✅ |

### 3. Catálogo y descubrimiento

| Funcionalidad | Estado |
|---------------|--------|
| Catálogo de servicios (8 categorías) | ✅ |
| 16 trabajadores demo con datos completos | ✅ |
| Listado de trabajadores por categoría | ✅ |
| Filtros y orden (rating, búsqueda) | ✅ |
| Perfil del trabajador (foto, rating, descripción, tarifa de visita) | ✅ |
| Portafolio con fotos | ✅ (imágenes remotas estables) |
| Portafolio con videos | ⚠️ Miniatura + icono play (no reproductor real) |

**Categorías demo:** electricidad, gasfitería, limpieza, construcción, armado de muebles, soporte técnico, jardinería, mudanzas.

### 4. Flujo del cliente (usuario)

| Funcionalidad | Estado |
|---------------|--------|
| Home con servicios | ✅ |
| Ver trabajadores de una categoría | ✅ |
| Ver perfil y portafolio | ✅ |
| Agendar visita (reserva rápida) | ✅ |
| Solicitar servicio completo (descripción, mapa, fecha) | ✅ |
| Confirmación legal / disclaimer del servicio | ✅ |
| Historial de trabajos | ✅ |
| Detalle del trabajo | ✅ |
| Calificar trabajador | ✅ |
| Chat asociado al trabajo | ✅ |
| Notificaciones locales | ✅ |

### 5. Flujo del trabajador

| Funcionalidad | Estado |
|---------------|--------|
| Dashboard / home trabajador | ✅ |
| Solicitudes pendientes | ✅ |
| Aceptar / rechazar trabajo | ✅ |
| Estados del trabajo (pendiente → aceptado → en curso → completado) | ✅ |
| Máquina de estados con validaciones | ✅ |
| Chat con el cliente | ✅ |
| Estadísticas básicas | ✅ |
| Perfil y edición | ✅ |
| Portafolio (subir / gestionar ítems) | ✅ |
| Disponibilidad (ocupado al aceptar trabajo) | ✅ |
| Trabajos de muestra precargados | ✅ |

### 6. Diseño y experiencia

| Funcionalidad | Estado |
|---------------|--------|
| Identidad visual (naranja / azul marino) | ✅ |
| Pantallas welcome, login, home usuario, dashboard trabajador | ✅ |
| Componentes de diseño compartidos | ✅ |
| Responsive básico (tablet / ancho máximo) | ✅ |
| Escalado de texto accesible (0.85–1.4) | ✅ |
| Tour guiado demo | ✅ |
| App bar con estilo iOS/Android | ✅ |

### 7. Legal y privacidad (demo)

| Funcionalidad | Estado |
|---------------|--------|
| Política de privacidad | ✅ |
| Términos y condiciones | ✅ |
| Derechos del usuario (GDPR orientado) | ✅ |
| Registro de consentimiento | ✅ |
| Exportación / eliminación de datos (local) | ✅ |

### 8. Servicios preparados en código (arquitectura futura)

Están **diseñados en el código** pero operan en modo **local o mock**:

| Servicio | Propósito |
|----------|-----------|
| `PaymentService` | Pagos, escrow, reembolsos (mock) |
| `SubscriptionService` | Planes de suscripción (mock) |
| `SyncService` | Cola de acciones para sincronizar con servidor |
| `AnalyticsService` | Eventos de producto (local) |
| `MatchingService` | Matching usuario–trabajador |
| `PricingService` | Estimación de precios |
| `FeatureFlagsService` | Flags remotos (sync pendiente) |
| `TrustScoreService` | Puntuación de confianza |
| `BoostService` | Visibilidad de trabajadores |
| `JobStateMachine` | Transiciones válidas de estados |
| `AbuseProtectionService` | Límites anti-abuso de solicitudes |

### 9. Instalación y distribución

| Recurso | Estado |
|---------|--------|
| Compilación APK release | ✅ (`flutter build apk --release`) |
| Script `build-apk.ps1` (Windows) | ✅ |
| Script `run.ps1` (emulador Android) | ✅ |
| Script `run_ios.sh` (simulador macOS) | ✅ |
| Script `install_ios_device.sh` (iPhone físico) | ✅ |
| Claves Google Maps fuera del repositorio | ✅ (`secrets.properties` / `Secrets.xcconfig`) |
| Repositorio en GitHub | ✅ |

### 10. Documentación existente

| Documento | Contenido |
|-----------|-----------|
| [README.md](README.md) | Visión general, stack, alcance, seguridad |
| [DEMO.md](DEMO.md) | Guión de demostración y limitaciones |
| [INSTALL.md](INSTALL.md) | APK, iPhone, TestFlight, QR |
| [myworksapp/README.md](myworksapp/README.md) | Referencia para desarrolladores |
| **Este archivo** | Inventario: qué tiene / qué falta |

---

## Lo que falta (no implementado o incompleto)

### Crítico para producción (objetivo del financiamiento)

| Área | Situación actual | Qué se necesita |
|------|------------------|-----------------|
| **Backend / API REST o GraphQL** | No existe | Servidor + base de datos en nube (ej. Supabase, Firebase, Node + PostgreSQL) |
| **Sincronización entre dispositivos** | Cada teléfono tiene su propia BD | API + auth + sync de jobs, usuarios, chat |
| **Autenticación en la nube** | Solo local | Firebase Auth, Supabase Auth, o JWT propio |
| **Pagos reales** | Mock en `PaymentService` | Mercado Pago, Stripe, Webpay u otra pasarela |
| **Notificaciones push remotas** | Solo locales | FCM (Android) + APNs (iOS) |
| **Chat en tiempo real** | Mensajes locales por trabajo | WebSockets, Firestore o Supabase Realtime |
| **Publicación en tiendas** | No publicada | Google Play + App Store (+ cuentas developer) |
| **Matching geográfico real** | Limitado | Backend + geolocalización y radio de búsqueda |

### Importante para calidad y operación

| Área | Situación actual | Qué se necesita |
|------|------------------|-----------------|
| **Panel de administración** | No existe | Dashboard web para moderación y métricas |
| **Monitoreo de errores** | Firebase Crashlytics deshabilitado | Sentry, Crashlytics o similar |
| **CI/CD** | Manual | GitHub Actions, Codemagic, etc. |
| **Tests automatizados en repo** | Carpeta `test/` ignorada en git | Unit tests + widget tests + integración |
| **Email / SMS de verificación** | No | SendGrid, Twilio, Firebase Auth |
| **Almacenamiento de archivos en nube** | Fotos locales o URLs demo | S3, Firebase Storage, Supabase Storage |
| **Videos reales en portafolio** | Solo miniatura | Reproductor + hosting de video |
| **Precios dinámicos por servicio** | Parcial / defaults | Tabla `service_pricing` + API |
| **Trabajador nuevo en listados por categoría** | No aparece como los 16 demos | Enlazar `serviceCategory` al registrarse + API |

### Configuración y despliegue

| Área | Situación actual | Qué se necesita |
|------|------------------|-----------------|
| **Google Maps en producción** | Clave local opcional | Clave restringida por package/bundle + facturación GCP |
| **Dominio y API pública** | No | Hosting + HTTPS + certificados |
| **Variables de entorno por ambiente** | Solo archivos locales | dev / staging / prod |
| **Política de privacidad legal** | Texto en app (demo) | Revisión legal según jurisdicción (Chile, etc.) |

### Documentación pendiente (complementaria)

| Documento | Utilidad |
|-----------|----------|
| Diagrama de arquitectura (actual vs. futuro) | Presentación y memoria |
| Roadmap con fechas por fase | Comité de financiamiento |
| Plan de negocio / modelo de ingresos | Inversión y universidad |
| Manual de despliegue backend | Equipo de desarrollo |
| Política de seguridad y respuesta a incidentes | Producción |

---

## Limitaciones conocidas de la demo (decirlas en presentación)

1. **Un solo dispositivo:** usuario y trabajador se demuestran cerrando sesión en el mismo teléfono.
2. **Sin backend:** dos teléfonos no comparten datos.
3. **Pagos simulados:** no hay cobro real ni escrow operativo.
4. **Trabajadores registrados en vivo:** no sustituyen a los 16 demos en el listado por categoría.
5. **Portafolio:** requiere internet para cargar imágenes demo remotas.
6. **Mapas:** requieren configurar `GOOGLE_MAPS_API_KEY` localmente.
7. **Videos del portafolio:** no hay reproducción de video real.

---

## Roadmap sugerido (con financiamiento universitario)

### Fase 1 — Piloto en nube (2–3 meses)

- [ ] Backend (Supabase / Firebase / stack que entregue la universidad)
- [ ] Auth en la nube + sync de usuarios y trabajos
- [ ] Chat y notificaciones push
- [ ] Despliegue APK + TestFlight para prueba cerrada

### Fase 2 — Monetización (1–2 meses)

- [ ] Integración de pasarela de pagos
- [ ] Tarifa de visita y comisión en flujo real
- [ ] Panel admin básico

### Fase 3 — Escala (continuo)

- [ ] Publicación en Google Play y App Store
- [ ] Matching geográfico
- [ ] Analytics y monitoreo
- [ ] Tests automatizados y CI/CD

---

## Matriz rápida: demo vs. producción

| Capacidad | Demo actual | Producción objetivo |
|-----------|-------------|---------------------|
| Ver trabajadores y perfiles | ✅ | ✅ |
| Crear solicitud de servicio | ✅ | ✅ |
| Aceptar y completar trabajo | ✅ | ✅ |
| Chat | ✅ local | ✅ en tiempo real |
| Calificaciones | ✅ | ✅ |
| Pagos | ❌ mock | ✅ pasarela real |
| Varios usuarios en distintos teléfonos | ❌ | ✅ |
| Push remotas | ❌ | ✅ |
| Admin / moderación | ❌ | ✅ |
| App en tiendas | ❌ | ✅ |

---

## Credenciales para demostración

| Rol | Email | Contraseña |
|-----|-------|------------|
| Usuario | `usuario@demo.com` | `demo123` |
| Trabajador | `trabajador@demo.com` | `demo123` |

Ver guión completo en [DEMO.md](DEMO.md).

---

## Enlaces relacionados

- [README.md](README.md) — Documentación principal
- [DEMO.md](DEMO.md) — Cómo presentar la app
- [INSTALL.md](INSTALL.md) — Cómo instalar en dispositivos
- Repositorio: https://github.com/MathiasAlejandr0/MyWorksAppProyect
