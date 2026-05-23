# MyWorksApp

App Flutter de demostración. Documentación principal en [../README.md](../README.md).

## Comandos útiles

```bash
flutter pub get
flutter run
flutter analyze
flutter build apk --debug
```

## Módulos principales

| Módulo | Ruta |
|--------|------|
| Auth | `lib/features/auth/` |
| Usuario | `lib/features/user/` |
| Trabajador | `lib/features/worker/` |
| Trabajos | `lib/features/jobs/` |
| Chat | `lib/features/chat/` |

## Datos demo

El seeder `lib/core/services/demo_data_seeder.dart` crea usuarios y trabajadores al primer arranque. Credenciales en `lib/core/config/demo_credentials.dart`.
