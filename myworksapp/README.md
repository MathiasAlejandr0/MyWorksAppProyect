# MyWorksApp — App Flutter

Demo móvil offline-first para conectar usuarios con trabajadores de oficios. Documentación completa del repositorio en [../README.md](../README.md).

## Inicio rápido

```powershell
# Windows + emulador Android
.\run.ps1 -LaunchEmulator
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
| Trabajador | `trabajador@demo.com` | `demo123` |
