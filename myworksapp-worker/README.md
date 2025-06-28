# MyWorksApp Worker - Aplicación de Trabajadores

Aplicación móvil para trabajadores de servicios al hogar. Permite registrarse, gestionar el perfil profesional y controlar la disponibilidad para recibir solicitudes de trabajo.

## 🚀 Características

### 👤 Registro y Perfil
- Registro completo con información personal y profesional
- Perfil detallado con foto y descripción
- Gestión de títulos y certificados
- Información de contacto y ubicación

### 📸 Portafolio
- Subida de fotos de trabajos anteriores
- Gestión de certificados profesionales
- Visualización de portafolio personal
- Organización por categorías

### 🔄 Gestión de Disponibilidad
- Toggle para marcar disponibilidad
- Estado visible en tiempo real
- Sincronización automática con la aplicación de usuarios
- Historial de cambios de estado

### 📊 Estadísticas y Calificaciones
- Sistema de calificaciones y reseñas
- Estadísticas de trabajos realizados
- Historial de actividad
- Métricas de rendimiento

### 🔔 Notificaciones
- Sistema de notificaciones push
- Notificaciones locales para eventos importantes
- Gestión de notificaciones no leídas
- Configuración de preferencias

## 🏗️ Arquitectura

### 📁 Estructura del Proyecto
```
lib/
├── models/                 # Modelos de datos
│   ├── worker.dart        # Modelo de trabajador
│   ├── review.dart        # Modelo de reseñas
│   └── notification_model.dart
├── pages/                 # Páginas de la aplicación
│   ├── worker_login_page.dart
│   ├── worker_register_page.dart
│   ├── worker_home_page.dart
│   └── worker_profile_page.dart
├── services/              # Servicios
│   ├── worker_security_service.dart
│   ├── worker_notification_service.dart
│   └── worker_database_helper.dart
├── utils/                 # Utilidades
│   └── app_colors.dart
└── main.dart             # Punto de entrada
```

## 🔄 Integración con Usuarios

Esta aplicación se integra con `myworksapp-user` mediante:

- **Base de datos compartida**: Los datos aparecen en la app de usuarios
- **Sincronización en tiempo real**: Estado de disponibilidad
- **Reseñas compartidas**: Sistema de calificaciones unificado

## 🛠️ Instalación

### Prerrequisitos
- Flutter SDK >= 3.4.4
- Dart SDK >= 3.4.4
- Android Studio / VS Code

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/MyWorksApp.git
cd MyWorksApp/myworksapp-worker
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Ejecutar la aplicación**
```bash
flutter run
```

## 📱 Compilación

### APK de Debug
```bash
flutter build apk --debug
```

### APK de Release
```bash
flutter build apk --release
```

## 🔧 Configuración

### Firebase (Opcional)
Para notificaciones push:

1. Crear proyecto en Firebase Console
2. Descargar `google-services.json`
3. Colocar en `android/app/`
4. Configurar Firebase Messaging

### Base de Datos
La aplicación utiliza SQLite local y comparte datos con la aplicación de usuarios.

## 🧪 Testing

```bash
flutter test
```

## 📊 Funcionalidades Detalladas

### Registro de Trabajadores
- Formulario completo con validación
- Subida de foto de perfil
- Información profesional detallada
- Títulos y certificados opcionales
- Fotos de trabajos anteriores

### Gestión de Perfil
- Información personal editable
- Actualización de datos profesionales
- Gestión de portafolio
- Configuración de preferencias

### Disponibilidad
- Toggle para marcar disponibilidad
- Estado visible en tiempo real
- Sincronización automática
- Historial de cambios

### Notificaciones
- Notificaciones push para nuevas solicitudes
- Notificaciones locales para eventos
- Gestión de notificaciones no leídas
- Configuración de alertas

## 🔐 Seguridad

- Hash de contraseñas con SHA-256
- Validación de datos en frontend y backend
- Sesiones seguras con tokens
- Validación de tipos de archivo
- Sanitización de datos de entrada

## 🎨 UI/UX

- Material Design 3
- Interfaz intuitiva y moderna
- Navegación fluida
- Estados de carga y error
- Accesibilidad mejorada

## 📈 Base de Datos

### Tablas Principales

#### Workers
- Información personal y profesional
- Estado de disponibilidad
- Calificaciones y estadísticas
- Rutas de archivos (fotos, certificados)

#### Reviews
- Reseñas de clientes
- Calificaciones
- Comentarios y fechas

#### Notifications
- Notificaciones del sistema
- Estado de lectura
- Datos adicionales

## 🚀 Futuras Mejoras

- [ ] Integración con backend remoto
- [ ] Chat en tiempo real con clientes
- [ ] Sistema de pagos integrado
- [ ] Geolocalización para trabajos cercanos
- [ ] Calendario de disponibilidad
- [ ] Sistema de citas programadas
- [ ] Backup en la nube
- [ ] Modo offline mejorado
- [ ] Temas personalizables
- [ ] Múltiples idiomas

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama para feature
3. Commit cambios
4. Push a la rama
5. Abrir Pull Request

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/tu-usuario/MyWorksApp/issues)
- **Email**: soporte@myworksapp.com
- **Documentación**: [Wiki](https://github.com/tu-usuario/MyWorksApp/wiki)

## 📝 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

⭐ ¡Dale una estrella si te resulta útil!
