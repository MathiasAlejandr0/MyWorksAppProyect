# MyWorksApp

Plataforma móvil Flutter para conectar **usuarios** con **trabajadores de oficios**. Esta versión está pensada como **demo funcional offline-first**: todo corre en el dispositivo con SQLite, sin backend remoto.

## Estructura del proyecto

```
MyWorksAppProyect/
└── myworksapp/          # App única (roles usuario + trabajador)
    └── lib/
        ├── bootstrap/   # Inicialización
        ├── core/        # BD, servicios, router, tema
        └── features/    # Pantallas por módulo
```

## Requisitos

- Flutter SDK 3.0+
- Android Studio / VS Code
- Dispositivo o emulador Android/iOS

## Ejecutar la demo

```bash
cd myworksapp
flutter pub get
flutter run
```

## Cuentas de demostración

Al iniciar la app se cargan automáticamente usuarios de prueba:

| Rol | Email | Contraseña |
|-----|-------|------------|
| Usuario | `usuario@demo.com` | `demo123` |
| Trabajador | `trabajador@demo.com` | `demo123` |

Trabajadores adicionales precargados: `pedro@demo.com`, `maria@demo.com` (misma contraseña).

En la pantalla de login hay un botón **Entrar con demo** para acceso rápido.

## Flujo recomendado para demostrar

1. Entra como **usuario demo** → elige un servicio → crea una solicitud.
2. Cierra sesión (Ajustes → Cerrar sesión).
3. Entra como **trabajador demo** → acepta el trabajo en la pestaña Pendientes.
4. Avanza el estado del trabajo (iniciar → completar).
5. Vuelve como usuario → califica, chatea y revisa el historial.

> Todo ocurre en el mismo dispositivo. Los datos persisten en SQLite local.

## Tecnologías

- **Flutter** + **Dart**
- **Riverpod** (estado)
- **GoRouter** (navegación)
- **SQLite** (persistencia local)
- **Google Maps** (ubicación en detalle de trabajo)

## Compilar APK

```bash
cd myworksapp
flutter build apk --debug
```

## Alcance de esta versión

Incluido en la demo:

- Registro e inicio de sesión local
- Catálogo de servicios (limpieza, plomería, electricidad, etc.)
- Solicitud de trabajos y matching de trabajadores
- Chat, fotos, calificaciones y notificaciones locales
- Perfil de trabajador y estadísticas básicas

No incluido (fuera de alcance demo):

- Backend remoto / sincronización entre dispositivos
- Pagos reales (mock local)
- Push notifications remotas
- Supabase / Firebase

## Licencia

MIT
