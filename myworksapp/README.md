# MyWorksApp — App Flutter

Demo móvil offline-first para conectar usuarios con trabajadores de oficios.

## Documentación del repositorio

| Archivo | Uso |
|---------|-----|
| [../README.md](../README.md) | Visión general, stack, alcance |
| [../ESTADO_DEL_PROYECTO.md](../ESTADO_DEL_PROYECTO.md) | Qué tiene / qué falta (MVP vs. producción) |
| [../INSTALL.md](../INSTALL.md) | APK Android, iPhone, TestFlight |
| [../DEMO.md](../DEMO.md) | Presentación a financistas / universidad |

## Inicio rápido

```powershell
# Windows + emulador Android
.\run.ps1 -LaunchEmulator
```

```powershell
# Compilar APK release (Windows)
.\scripts\build-apk.ps1
```

```bash
# macOS — simulador iOS
chmod +x scripts/run_ios.sh && ./scripts/run_ios.sh

# macOS — iPhone físico
chmod +x scripts/install_ios_device.sh && ./scripts/install_ios_device.sh
```

```bash
flutter pub get
flutter run
flutter analyze
```

## Módulos principales

| Módulo | Ruta |
|--------|------|
| Auth | `lib/features/auth/` |
| Usuario | `lib/features/user/` |
| Trabajador | `lib/features/worker/` |
| Trabajos | `lib/features/jobs/` |
| Chat | `lib/features/chat/` |
| Onboarding / Welcome | `lib/features/role_selector/` |

## Datos demo

- Credenciales: `lib/core/config/demo_credentials.dart`
- Seeder: `lib/core/services/demo_data_seeder.dart`
- Catálogo (versión): `lib/core/config/demo_catalog_config.dart`
- Medios demo (perfiles y portafolio): `lib/core/config/demo_free_media.dart`

## Diseño y sistema compartido

- Colores marca: `lib/core/theme/app_colors.dart`
- Breakpoints: `lib/core/design_system/app_breakpoints.dart`
- Widgets UI: `lib/core/widgets/design_system/`
- Portafolio: `lib/core/widgets/portfolio_media_tile.dart`

## Credenciales demo

| Rol | Email | Contraseña |
|-----|-------|------------|
| Usuario | `usuario@demo.com` | `demo123` |
| Administrador | `admin@demo.com` | `demo123` |
| Trabajador | `trabajador@demo.com` | `demo123` |

## Claves Google Maps (local)

No commitear claves. Ver [../README.md#seguridad-y-claves-api](../README.md#seguridad-y-claves-api).

```powershell
copy android\secrets.properties.example android\secrets.properties
```

```bash
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
```

## Scripts

| Script | Plataforma | Descripción |
|--------|------------|-------------|
| `run.ps1` | Windows | Flutter run en emulador Android |
| `scripts/build-apk.ps1` | Windows | Compila APK release → `../releases/` |
| `scripts/run_ios.sh` | macOS | Flutter run en simulador iOS |
| `scripts/install_ios_device.sh` | macOS | Instala en iPhone físico (release) |
