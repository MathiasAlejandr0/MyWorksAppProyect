# Firma de release Android

La APK 1.0.1 se firmó con la clave **debug** y con el id `com.example.myworksapp`.
Google Play rechaza ambos, y una APK compilada en otro PC no se instala encima
(choque de firma). Desde este cambio el id es **`cl.myworksapp.app`**.

> Cambiar el `applicationId` crea una app distinta en el teléfono: hay que
> **desinstalar** la versión `com.example.myworksapp` antes de instalar la nueva
> (se pierde la sesión guardada; los datos están en Supabase, no se pierden).

## 1. Crear el keystore (una sola vez, lo hace una persona del equipo)

```bash
# Desde MyWorksAppProyect/myworksapp_app/android
mkdir -p keystore
keytool -genkeypair -v -keystore keystore/myworksapp-release.jks \
  -alias myworksapp -keyalg RSA -keysize 2048 -validity 10000
```

- Elige claves fuertes y guárdalas en un gestor de contraseñas.
- Respalda `myworksapp-release.jks` fuera del repo (si se pierde, no se puede
  actualizar la app publicada).
- `*.jks`, `*.keystore` y `key.properties` ya están en `android/.gitignore`.

## 2. Configurar `android/key.properties`

```bash
cp key.properties.example key.properties   # y completa las claves
```

## 3. Compilar

```bash
cd MyWorksAppProyect/myworksapp_app
REQUIRE_RELEASE_SIGNING=true flutter build apk --release --split-per-abi \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# Para Play Store: flutter build appbundle --release (con el mismo env)
```

Con `REQUIRE_RELEASE_SIGNING=true` el build falla si falta `key.properties`,
en vez de firmar con debug en silencio.

## 4. Después de crear el keystore

- Agrega el SHA-1 del keystore release (`keytool -list -v -keystore ...`) y el
  paquete `cl.myworksapp.app` a las restricciones de la clave de Google Maps.
- Si se usa Google Sign-In / OAuth, registra también ese SHA-1 y el paquete nuevo.
