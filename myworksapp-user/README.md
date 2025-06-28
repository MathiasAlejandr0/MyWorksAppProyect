# MyWorksApp User - Aplicación de Usuarios

Aplicación móvil para usuarios que necesitan servicios al hogar. Permite explorar servicios, ver profesionales disponibles y solicitar trabajos.

## 🚀 Características

### 👤 Gestión de Usuario
- Registro e inicio de sesión seguro
- Perfil de usuario personalizable
- Historial de solicitudes
- Gestión de direcciones

### 🔍 Exploración de Servicios
- Catálogo de servicios disponibles
- Filtros por categoría
- Búsqueda de profesionales
- Información detallada de servicios

### 👷 Profesionales
- Lista de trabajadores disponibles
- Filtros por profesión y ubicación
- Perfiles detallados con reseñas
- Calificaciones y estadísticas

### 📋 Solicitudes
- Crear solicitudes de servicio
- Seguimiento de estado
- Historial de trabajos
- Calificaciones y reseñas

## 🏗️ Arquitectura

### 📁 Estructura del Proyecto
```
lib/
├── models/                 # Modelos de datos
│   ├── models.dart        # Modelos principales
│   ├── review.dart        # Modelo de reseñas
│   └── notification_model.dart
├── pages/                 # Páginas de la aplicación
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── home_page.dart
│   ├── dashboard_page.dart
│   ├── services_page.dart
│   ├── professionals_page.dart
│   ├── professional_detail_page.dart
│   ├── request_service_page.dart
│   ├── requests_page.dart
│   └── profile_page.dart
├── services/              # Servicios
│   ├── worker_sync_service.dart  # Sincronización con trabajadores
│   ├── notification_service.dart
│   └── security_service.dart
├── database/              # Base de datos
│   └── database_helper.dart
├── utils/                 # Utilidades
│   └── app_colors.dart
└── main.dart             # Punto de entrada
```

## 🔄 Integración con Trabajadores

Esta aplicación se integra con `myworksapp-worker` mediante:

- **Base de datos compartida**: Lee trabajadores registrados
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
cd MyWorksApp/myworksapp-user
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
La aplicación utiliza SQLite local y se sincroniza con la base de datos de trabajadores.

## 🧪 Testing

```bash
flutter test
```

## 📊 Funcionalidades Detalladas

### Autenticación
- Registro con validación completa
- Inicio de sesión seguro
- Recuperación de contraseña
- Sesiones persistentes

### Exploración
- Catálogo de servicios
- Filtros avanzados
- Búsqueda por texto
- Ordenamiento por relevancia

### Profesionales
- Lista con filtros
- Perfiles detallados
- Reseñas y calificaciones
- Información de contacto

### Solicitudes
- Formulario de solicitud
- Programación de fechas
- Seguimiento de estado
- Historial completo

## 🔐 Seguridad

- Hash de contraseñas con salt
- Validación de datos de entrada
- Sanitización de información
- Gestión segura de sesiones

## 🎨 UI/UX

- Material Design 3
- Temas personalizables
- Navegación intuitiva
- Estados de carga y error
- Accesibilidad mejorada

## 📈 Estadísticas

- Métricas de uso
- Análisis de comportamiento
- Reportes de rendimiento
- Monitoreo de errores

## 🚀 Futuras Mejoras

- [ ] Chat en tiempo real
- [ ] Sistema de pagos
- [ ] Geolocalización
- [ ] Notificaciones push
- [ ] Modo offline
- [ ] Múltiples idiomas
- [ ] Temas personalizables

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

---

⭐ ¡Dale una estrella si te resulta útil! 