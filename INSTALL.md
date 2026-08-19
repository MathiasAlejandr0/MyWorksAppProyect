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

```bash
cd myworksapp_web
copy .env.example .env
npm install
npm run dev -- --port 3000
```

Variables en `.env`:

```env
VITE_SUPABASE_URL=https://wxqrfcqifkfgawrnqmnj.supabase.co
VITE_SUPABASE_ANON_KEY=tu_anon_key
```

Acceso: `http://127.0.0.1:3000`

Cuenta demo: `usuario@demo.com` / `demo123`

---

## Escritorio — `myworksapp_desktop`

Hub de **administración** (rol `admin` en Supabase). Soporte, métricas y DevSecOps leen datos reales.

### Modo navegador (desarrollo)

```bash
cd myworksapp_desktop
copy .env.example .env
npm install
npm run dev -- --port 3001
```

Acceso: `http://127.0.0.1:3001`

Cuenta admin demo: `admin@demo.com` / `demo123`

### App nativa con Tauri (Windows / macOS / Linux)

Requisitos: [Rust](https://rustup.rs/) instalado.

```bash
cd myworksapp_desktop
npm install
npm run tauri:dev      # desarrollo con ventana nativa
npm run tauri:build    # genera instalador en src-tauri/target/release/bundle/
```

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
