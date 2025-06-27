# MyWorksApp - Servicios al Hogar

Una aplicación móvil desarrollada en Flutter para solicitar servicios profesionales al hogar como maestro constructor, cerrajero, jardinero, gasfiter y electricista.

## 🏠 Descripción

MyWorksApp es una plataforma que conecta a usuarios con profesionales calificados para realizar trabajos en el hogar. La aplicación permite a los usuarios solicitar servicios, hacer seguimiento de sus solicitudes y gestionar su perfil de usuario.

## 🛠️ Servicios Disponibles

- **Maestro Constructor**: Servicios de construcción, remodelación y reparaciones estructurales
- **Gasfiter**: Reparación e instalación de sistemas de agua, gas y alcantarillado
- **Cerrajero**: Servicios de cerrajería, instalación y reparación de cerraduras
- **Electricista**: Instalación y reparación de sistemas eléctricos
- **Jardinero**: Mantenimiento y diseño de jardines y áreas verdes

## ✨ Características Principales

### 🔐 Autenticación
- Registro de usuarios con validación de formularios
- Inicio de sesión seguro
- Recuperación de contraseña (pendiente de implementar)

### 🏠 Gestión de Servicios
- Catálogo completo de servicios disponibles
- Información detallada de cada servicio
- Formulario de solicitud con validación
- Selección de fecha y hora preferida

### 📋 Seguimiento de Solicitudes
- Vista de solicitudes activas
- Estado de cada solicitud (pendiente, aceptada, completada, cancelada)
- Historial de servicios solicitados

### 👤 Perfil de Usuario
- Información personal editable
- Gestión de direcciones
- Configuración de cuenta
- Cerrar sesión

## 🎨 Diseño y UX

- **Paleta de colores**: Azul principal (#1976D2) con acentos naranjas y verdes
- **Interfaz intuitiva**: Navegación clara y fácil de usar
- **Responsive**: Adaptable a diferentes tamaños de pantalla
- **Material Design**: Siguiendo las mejores prácticas de Google

## 📱 Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── models/
│   └── models.dart          # Modelos de datos (Service, ServiceRequest, User)
├── pages/
│   ├── login_page.dart      # Página de inicio de sesión
│   ├── register_page.dart   # Página de registro
│   ├── home_page.dart       # Página principal con navegación
│   ├── services_page.dart   # Catálogo de servicios
│   ├── service_detail_page.dart # Detalle de servicio
│   ├── request_service_page.dart # Formulario de solicitud
│   ├── requests_page.dart   # Lista de solicitudes
│   ├── profile_page.dart    # Perfil de usuario
│   └── dashboard_page.dart  # Dashboard principal
└── utils/
    └── app_colors.dart      # Definición de colores de la app
```

## 🚀 Instalación y Ejecución

### Prerrequisitos
- Flutter SDK (versión 3.8.0 o superior)
- Dart SDK
- Android Studio / VS Code
- Emulador Android o dispositivo físico

### Pasos de instalación

1. **Clonar el repositorio**
   ```bash
   git clone [URL_DEL_REPOSITORIO]
   cd MyWorksAppProyect
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## 📋 Dependencias

El proyecto utiliza las siguientes dependencias principales:

- **flutter**: Framework principal
- **cupertino_icons**: Iconos de iOS
- **flutter_lints**: Reglas de linting para código limpio

## 🔧 Configuración

### Archivos de configuración importantes:
- `pubspec.yaml`: Dependencias y configuración del proyecto
- `analysis_options.yaml`: Reglas de análisis de código
- `android/app/build.gradle.kts`: Configuración de Android
- `ios/Runner/Info.plist`: Configuración de iOS

## 🎯 Funcionalidades Pendientes

- [ ] Integración con backend real
- [ ] Sistema de notificaciones push
- [ ] Chat en tiempo real con profesionales
- [ ] Sistema de pagos
- [ ] Calificaciones y reseñas
- [ ] Geolocalización para encontrar profesionales cercanos
- [ ] Historial de transacciones
- [ ] Modo offline

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

Desarrollado por Mathias Alejandro Jara Alvarado

## 📞 Soporte

Para soporte técnico o preguntas sobre el proyecto, por favor contacta al equipo de desarrollo.

---

**Nota**: Esta es una versión de demostración. Para uso en producción, se requiere implementar un backend real y configurar las APIs correspondientes.
