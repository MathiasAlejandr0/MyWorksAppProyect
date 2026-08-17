# MyWorksApp — App Flutter

App móvil online-first (Supabase) para conectar usuarios con trabajadores de oficios.

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

Solo visibles en **modo debug** (`kDebugMode`) en la pantalla de login.

| Rol | Email | Contraseña |
|-----|-------|------------|
| Usuario | `usuario@demo.com` | `demo123` |
| Administrador | `admin@demo.com` | `demo123` |
| Trabajador | `trabajador@demo.com` | `demo123` |

## Tests y CI

```bash
flutter test
flutter analyze --no-fatal-infos
```

Workflow: `.github/workflows/flutter_ci.yml`

## Migraciones Supabase

SQL versionado en `supabase/migrations/`. Aplicar con Supabase CLI o dashboard.

### Seguridad Auth — contraseñas filtradas (Have I Been Pwned)

**No está en “Auth → Email” genérico.** La opción vive en el proveedor Email:

1. Abre: `https://supabase.com/dashboard/project/<PROJECT_REF>/auth/providers`
2. Entra en **Email** (o URL directa: `.../auth/providers?provider=Email`)
3. Busca el toggle **“Prevent use of leaked passwords”** (no dice “Leaked password protection” en la UI)
4. También puedes ver un aviso en **Authentication → Attack Protection** que enlaza a esta misma opción

**Importante:** esa función solo está disponible en **plan Pro o superior**. En plan Free el toggle aparece **deshabilitado** o no se puede guardar — no es un error de navegación.

Documentación: [Password security](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)

### Notas de seguridad Supabase (proyecto `wxqrfcqifkfgawrnqmnj`)

| Tema | Estado |
|------|--------|
| `protect_profile_sensitive_fields` | `EXECUTE` revocado a `anon`/`authenticated` (solo trigger) |
| `is_admin()` ejecutable por `authenticated` | Intencional: lo usan las políticas RLS del panel admin |
| Prevent use of leaked passwords | Requiere **plan Pro+**; en Free queda pendiente hasta upgrade |

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
