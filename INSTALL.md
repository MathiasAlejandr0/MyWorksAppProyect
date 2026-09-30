# Instalación — MyWorksApp

Guía para instalar la app en **Android** e **iPhone** sin depender del emulador.

---

## Android — APK

### Compilar la APK (Windows / macOS / Linux)

```bash
cd myworksapp_app
flutter pub get
flutter build apk --release
```

Salida:

```
myworksapp_app/build/app/outputs/flutter-apk/app-release.apk
```

También en Windows:

```powershell
cd myworksapp_app
.\scripts\build-apk.ps1
```

### Instalar en el teléfono

1. Copia `app-release.apk` al Android (USB, WhatsApp, Drive, email).
2. Abre el archivo en el teléfono.
3. Si lo pide, activa **Instalar apps desconocidas** para esa app.
4. Instala y abre **MyWorksApp**.

### Distribuir con QR (Android)

1. Sube el APK a un enlace público:
   - [GitHub Releases](https://github.com/MathiasAlejandr0/MyWorksAppProyect/releases) (recomendado)
   - Google Drive (enlace directo de descarga)
2. Genera un QR con la URL (ej. [qr-code-generator.com](https://www.qr-code-generator.com/)).
3. Quien escanea descarga e instala el APK.

> Los archivos `.apk` no se suben al repo por `.gitignore`. Compílalos o publícalos en Releases.

---

## iPhone — desde Mac

iOS **no** permite instalar con un QR + APK como Android. Opciones:

### Opción A — Tu iPhone con cable (desarrollo)

**Requisitos:** Mac, Xcode, Apple ID, cable USB.

```bash
git clone https://github.com/MathiasAlejandr0/MyWorksAppProyect.git
cd MyWorksAppProyect/myworksapp_app
flutter pub get
chmod +x scripts/install_ios_device.sh
./scripts/install_ios_device.sh
```

**Primera vez — firma en Xcode:**

1. `open ios/Runner.xcworkspace`
2. Target **Runner** → **Signing & Capabilities**
3. **Automatically manage signing** + tu **Team** (Apple ID)
4. Si falla el Bundle ID, usa uno único: `com.tunombre.myworksapp`

**En el iPhone:** Ajustes → General → VPN y gestión de dispositivos → **Confiar** en el desarrollador.

| Cuenta Apple | Duración de la app en el iPhone |
|--------------|----------------------------------|
| Apple ID gratis (Personal Team) | ~7 días, reinstalar después |
| Apple Developer (99 USD/año) | Hasta 1 año; TestFlight disponible |

### Opción B — Simulador en Mac (sin iPhone)

```bash
cd myworksapp_app
chmod +x scripts/run_ios.sh
./scripts/run_ios.sh
```

### Opción C — TestFlight (varios iPhones, presentaciones)

Para que un profesor o financista instale escaneando un QR:

1. Cuenta [Apple Developer](https://developer.apple.com) (99 USD/año).
2. Compila y sube a [App Store Connect](https://appstoreconnect.apple.com).
3. Activa **TestFlight** → enlace público o invitación.
4. QR apunta al enlace de TestFlight.
5. Instalan la app **TestFlight** y luego MyWorksApp.

**Plazo:** la primera build puede tardar 24–48 h en revisión de Apple. Planifica con anticipación.

---

## Web (PWA) — `myworksapp_web`

Versión web para **clientes** (rol `user` en Supabase). Usa el módulo compartido `shared/` para auth y datos reales.

El retorno de Webpay usa solo el puerto **5173**. Copia `.env.example` a `.env.local` (ya trae la URL y la clave publicable).

```bash
cd myworksapp_web
cp .env.example .env.local
npm install
npm run dev
```

En Windows PowerShell:

```powershell
cd myworksapp_web
Copy-Item .env.example .env.local
npm install
npm run dev
```

Acceso: `http://localhost:5173`

Cuentas de la demo (contraseña `Demo2026!`): `camila.soto@demo.myworksapp.cl` y el resto de `DEMO.md`. No uses `usuario@demo.com` ni `demo123`.

---

## Escritorio — `myworksapp_desktop`

Hub de **administración** (rol `admin` en Supabase). Soporte, métricas y DevSecOps leen datos reales.

### Modo navegador (desarrollo)

El panel en el navegador queda en `http://127.0.0.1:3001`.

```bash
cd myworksapp_desktop
cp .env.example .env.local
npm install
npm run dev
```

En Windows PowerShell:

```powershell
cd myworksapp_desktop
Copy-Item .env.example .env.local
npm install
npm run dev
```

Acceso: `http://127.0.0.1:3001`

Cuenta admin de la demo: `admin.ops@demo.myworksapp.cl` / `Demo2026!` (Valentina Riquelme). El segundo factor pide un QR la primera vez.

### App nativa con Tauri (Windows / macOS / Linux)

Requisitos: [Rust](https://rustup.rs/) instalado.

```bash
cd myworksapp_desktop
Copy-Item .env.example .env.local   # en bash: cp .env.example .env.local
npm install
npm run tauri:dev      # desarrollo con ventana nativa, mismo origen que http://127.0.0.1:3001
npm run tauri:build    # genera instalador en src-tauri/target/release/bundle/
```

---

## Inicio de sesión con Google y Apple (OAuth)

La **web** y la **app móvil** soportan inicio de sesión social vía **Supabase Auth**. Requiere configuración en el panel de Supabase y en Google / Apple (no basta con el código).

### 1. Supabase Dashboard

Proyecto: `https://supabase.com/dashboard/project/wxqrfcqifkfgawrnqmnj`

1. **Authentication → Providers**
   - Activar **Google** (Client ID + Client Secret de Google Cloud).
   - Activar **Apple** (Services ID, Key, Team ID, etc.).

2. **Authentication → URL Configuration** — añadir redirect URLs:
   - `http://127.0.0.1:5173` (web en desarrollo con Vite)
   - `http://localhost:5173`
   - Tu dominio de producción web (ej. `https://tudominio.cl`)
   - `cl.myworksapp.auth://login-callback` (app móvil Android + iOS)

3. Aplicar migración de perfiles OAuth (si aún no está en remoto):

```bash
cd myworksapp_app
supabase db push
```

`20261005000001_verificacion_profesional.sql` y `20261005000002_security_lockdown_rpc.sql` (el cierre de EXECUTE ya corrido en la base) están en el proyecto `wxqrfcqifkfgawrnqmnj`. Falta aplicar, en este orden, `20261006000001_gps_y_base_profesional.sql` (ubicación base, `en_camino`, GPS; la matriz de estados conserva el flujo de pago y solo agrega en camino), `20261006000002_ocultar_pin_listados.sql` y `20261007000001_rls_indices_asesores.sql` (initplan, políticas duplicadas e índices). El guion y las cuentas de la demo están en `DEMO.md`. El SQL de datos de prueba es `scripts/demo/seed_demo.sql` y no forma parte de las migraciones. El cliente usa `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` (web y escritorio) o `--dart-define=SUPABASE_URL` y `SUPABASE_ANON_KEY` (Flutter). Pagos de integración: `TBK_ENV=integration`; `TBK_COMMERCE_CODE` y `TBK_API_KEY` solo en secretos de Edge Functions. `WEBPAY_HANDOFF_SECRET` es obligatorio.

Invitaciones de RRHH (función `invitar-colaborador`, solo un administrador):

- `INVITE_PROVIDER=supabase` (por defecto) usa `inviteUserByEmail`. Hace falta el SMTP del proyecto Auth.
- `INVITE_PROVIDER=resend` exige `RESEND_API_KEY` y `RESEND_FROM`.
- `INVITE_REDIRECT_URL` es opcional (a dónde vuelve quien acepta).

Esos secretos viven en las Edge Functions, no en el escritorio.

### 2. Google Cloud Console

1. Crear proyecto (o usar uno existente).
2. **APIs & Services → Credentials → OAuth 2.0 Client ID**.
3. Tipo **Web application** — Authorized redirect URI:
   - `https://wxqrfcqifkfgawrnqmnj.supabase.co/auth/v1/callback`
4. Copiar Client ID y Secret en Supabase → Google provider.

### 3. Apple Developer (Sign in with Apple)

1. **Identifiers → Services ID** con Sign in with Apple.
2. Dominio y return URL: `https://wxqrfcqifkfgawrnqmnj.supabase.co/auth/v1/callback`
3. Crear **Key** con Sign in with Apple.
4. Completar Team ID, Key ID y `.p8` en Supabase → Apple provider.
5. En Xcode (iOS): target **Runner → Signing & Capabilities → + Sign in with Apple**.

> **Nota:** Apple Sign-In en la app solo aparece en **iPhone/iPad**. En Android solo Google está disponible como botón nativo; Apple funciona en la web.

### 4. Probar

**Web:**

```bash
cd myworksapp_web
npm run dev
```

Abrir login → **Continuar con Google** / **Continuar con Apple**.

**Móvil:** compilar e instalar la app; en login usar los mismos botones. Tras autenticarse en el navegador, la app vuelve sola al deep link `cl.myworksapp.auth://login-callback`.

---

## Claves Google Maps (opcional)

Sin clave, la app funciona pero **los mapas pueden no cargar**.

**Android:**

```powershell
cd myworksapp_app\android
copy secrets.properties.example secrets.properties
# Editar: GOOGLE_MAPS_API_KEY=tu_clave
```

**iOS:**

```bash
cd myworksapp_app/ios/Flutter
cp Secrets.xcconfig.example Secrets.xcconfig
# Editar: GOOGLE_MAPS_API_KEY=tu_clave
```

Ver restricciones y rotación de claves en [README.md](README.md#seguridad-y-claves-api).

---

## Desarrollo con emulador

**Windows + Android:**

```powershell
cd myworksapp_app
.\run.ps1 -LaunchEmulator
```

**macOS + iOS simulador:**

```bash
cd myworksapp_app
./scripts/run_ios.sh
```

---

## Solución de problemas

| Problema | Solución |
|----------|----------|
| Android bloquea instalación | Activar “orígenes desconocidos” / “instalar apps desconocidas” |
| iPhone: *Untrusted developer* | Ajustes → Confiar en certificado |
| iPhone: *No development team* | Configurar Team en Xcode |
| Mapas en blanco | Configurar `secrets.properties` / `Secrets.xcconfig` |
| Portafolio sin fotos | Conexión a internet (imágenes demo remotas) |

---

## Documentación relacionada

- Demo para presentaciones: [DEMO.md](DEMO.md)
- README principal: [README.md](README.md)
