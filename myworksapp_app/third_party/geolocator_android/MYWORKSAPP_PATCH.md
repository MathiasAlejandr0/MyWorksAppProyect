# geolocator_android 5.1.1 (parcheado para MyWorksApp)

Copia de `geolocator_android` 5.1.1 de pub.dev (licencia MIT, ver LICENSE),
sha256 del archivo original `b449e3bd4ebdc7fcc1d8377848dd1486a07bfccd8eeff9c1bf66b1c6d8fde7d1`.
Se usa con `dependency_overrides` en `myworksapp_app/pubspec.yaml`.

Único cambio: `android/src/main/java/com/baseflow/geolocator/location/NmeaClient.java`.

- `start()` registra el listener NMEA y el callback de estado GNSS solo cuando
  `useMSLAltitude` es true (la app nunca lo activa).
- `stop()` solo los quita si se registraron.

Motivo: desde la 4.6.0 el plugin llama a `LocationManager.addNmeaListener` en el
hilo principal en cada `getCurrentPosition` o stream. En el emulador Android 14 el
HAL de GNSS puede quedar trabado (`GnssNmeaProvider` esperando a `stopNmea`), esa
llamada binder no vuelve nunca y la app entra en ANR ("no responde") en la
pantalla Solicitar servicio. Sin el listener la ubicación funciona igual
(no se pierde nada: la altitud MSL y el conteo de satélites no se usan).
Se eliminaron `example/`, `test/` y `android/src/test/` del paquete.
