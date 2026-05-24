# MyWorksApp

Plataforma móvil **Flutter** para conectar **usuarios** con **trabajadores de oficios**. Esta versión es una **demo funcional offline-first**: todos los datos viven en el dispositivo (SQLite), sin backend remoto ni sincronización entre teléfonos.

## Documentación

| Documento | Contenido |
|-----------|-----------|
| **[INSTALL.md](INSTALL.md)** | Instalar APK en Android, iPhone desde Mac, TestFlight, QR |
| **[DEMO.md](DEMO.md)** | Guión de demo para financistas, universidad, limitaciones |
| **[myworksapp/README.md](myworksapp/README.md)** | Referencia rápida para desarrolladores |

## Descripción

MyWorksApp permite a un usuario buscar servicios del hogar, ver perfiles de trabajadores con portafolio y tarifas, agendar visitas y gestionar trabajos de punta a punta. Los trabajadores pueden aceptar ofertas, actualizar el estado del trabajo, chatear y mostrar su experiencia en un perfil profesional.

Incluye **16 trabajadores demo** repartidos en 8 categorías (electricidad, gasfitería, limpieza, construcción, armado de muebles, soporte técnico, jardinería y mudanzas), con fotos de perfil y portafolio precargado.

## Características

- **Diseño renovado** con identidad visual naranja / azul marino (welcome, login, home usuario y dashboard trabajador)
- **Dos roles** en una sola app: usuario y trabajador
- **Catálogo demo** sincronizado al arranque con perfiles, portafolios y trabajos de muestra
- **Flujo completo**: servicio → listado de trabajadores → perfil → agendar visita → chat → calificación
- **Portafolio multimedia** con fotos y miniaturas de video demo
- **Responsive básico** para tablet y escritorio (breakpoints + ancho máximo)
- **Accesibilidad**: escalado de texto del sistema respetado (0.85–1.4)
- **Permisos** actualizados en Android e iOS (cámara, fotos, ubicación, notificaciones)
- **Tour guiado** opcional para nuevos usuarios demo
- **SQLite cifrado** y persistencia local entre sesiones

## Estructura del proyecto

```
MyWorksAppProyect/
├── README.md                      # Este archivo
├── INSTALL.md                     # Instalación APK / iPhone
├── DEMO.md                        # Guía de demostración
└── myworksapp/                    # App Flutter (usuario + trabajador)
    ├── assets/images/             # Imágenes locales (hero welcome, etc.)
    ├── lib/
    │   ├── bootstrap/             # Inicialización de la app
    │   ├── core/                  # BD, router, tema, servicios, widgets compartidos
    │   └── features/              # Pantallas por módulo (auth, user, worker, jobs…)
    ├── run.ps1                    # Ejecutar en emulador Android (Windows)
    └── scripts/
        ├── build-apk.ps1          # Compilar APK (Windows)
        ├── run_ios.sh             # Ejecutar en simulador iOS (macOS)
        └── install_ios_device.sh  # Instalar en iPhone físico (macOS)
```

## Requisitos

- Flutter SDK 3.0+
- Android Studio / Xcode (iOS) / VS Code
- Dispositivo o emulador Android / iOS

## Ejecutar la demo

### Windows (Android — emulador)

```powershell
cd myworksapp
.\run.ps1 -LaunchEmulator
```

### macOS (iOS — simulador)

```bash
cd myworksapp
chmod +x scripts/run_ios.sh
./scripts/run_ios.sh
```

### macOS (iPhone físico)

Ver [INSTALL.md](INSTALL.md) o:

```bash
cd myworksapp
chmod +x scripts/install_ios_device.sh
./scripts/install_ios_device.sh
```

### Comandos estándar

```bash
cd myworksapp
flutter pub get
flutter run
flutter analyze
```

## Cuentas de demostración

Al iniciar la app se cargan automáticamente usuarios de prueba:

| Rol | Email | Contraseña |
|-----|-------|------------|
| Usuario | `usuario@demo.com` | `demo123` |
| Trabajador | `trabajador@demo.com` | `demo123` |

Trabajadores adicionales precargados: `pedro@demo.com`, `maria@demo.com` (misma contraseña).

En la pantalla de login puedes usar **Entrar con demo** o el selector de rol Usuario / Trabajador.

También puedes **registrar cuentas nuevas** (usuario recomendado para onboarding; trabajadores nuevos no aparecen en listados por categoría como los 16 demos).

## Flujo recomendado para demostrar

Resumen rápido; guión completo en **[DEMO.md](DEMO.md)**.

1. Entra como **usuario demo** → elige un servicio (ej. Armado de muebles) → abre un perfil (ej. Tomás IKEA Pro).
2. Revisa tarifa de visita, descripción y **trabajos anteriores** del portafolio.
3. Crea una solicitud o **agenda una visita**.
4. Cierra sesión (Ajustes → Cerrar sesión).
5. Entra como **trabajador demo** → acepta el trabajo en Pendientes → avanza el estado.
6. Vuelve como usuario → califica, chatea y revisa el historial.

> Todo ocurre en el mismo dispositivo. Los datos persisten en SQLite local.

## Tecnologías

| Área | Stack |
|------|--------|
| UI | Flutter, Material 3, Google Fonts |
| Estado | Riverpod |
| Navegación | GoRouter |
| Persistencia | SQLite (sqflite + sqlcipher) |
| Imágenes | cached_network_image, image_picker |
| Mapas | Google Maps, Geolocator |
| Notificaciones | flutter_local_notifications (locales) |

## Compilar e instalar APK (Android)

```bash
cd myworksapp
flutter build apk --release
```

Windows (copia también a `releases/`):

```powershell
cd myworksapp
.\scripts\build-apk.ps1
```

Salida: `myworksapp/build/app/outputs/flutter-apk/app-release.apk`

Instrucciones de instalación en teléfono: **[INSTALL.md](INSTALL.md)**

## Alcance de esta versión

**Incluido**

- Registro e inicio de sesión local
- Catálogo de servicios y trabajadores demo por categoría
- Perfil de trabajador con portafolio y tarifa de visita
- Solicitud de trabajos, chat, fotos, calificaciones y notificaciones locales
- Dashboard trabajador con estadísticas básicas
- Diseño responsive y accesibilidad de texto

**No incluido** (fuera de alcance demo)

- Backend remoto / sync entre dispositivos
- Pagos reales (mock local; ver `lib/core/services/payment_service.dart`)
- Push notifications remotas
- Reproducción de video real en portafolio (solo miniaturas demo)
- Supabase / Firebase
- Trabajadores registrados en el listado por categoría (solo demos precargados)

## Seguridad y claves API

**No subas claves de Google Maps ni otros secretos a GitHub.** El correo de Google suele referirse a **API keys de Maps** expuestas en el código.

### Si recibiste alerta de Google

1. Entra a [Google Cloud Console → Credenciales](https://console.cloud.google.com/google/maps-apis/credentials).
2. **Elimina o regenera** las claves que estuvieron en el repositorio (ya no están en el código actual, pero siguen en el historial de Git hasta que las revoques).
3. Crea claves **nuevas** con restricciones:
   - **Android:** app `com.example.myworksapp` + huella SHA-1 de tu keystore.
   - **iOS:** bundle ID de tu app.
   - Limita APIs solo a **Maps SDK for Android/iOS** (y las que uses).

### Configurar claves en local (desarrollo)

**Android** — copia el ejemplo y pega tu clave:

```powershell
cd myworksapp\android
copy secrets.properties.example secrets.properties
# Edita secrets.properties y añade: GOOGLE_MAPS_API_KEY=tu_clave_nueva
```

**iOS (macOS):**

```bash
cd myworksapp/ios/Flutter
cp Secrets.xcconfig.example Secrets.xcconfig
# Edita Secrets.xcconfig con GOOGLE_MAPS_API_KEY=tu_clave_nueva
```

También puedes usar la variable de entorno `GOOGLE_MAPS_API_KEY` en Android.

Los archivos `secrets.properties` y `Secrets.xcconfig` están en `.gitignore` y **no se suben** al repositorio.

## Licencia

MIT
