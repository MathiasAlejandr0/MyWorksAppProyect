# MyWorksApp - Sistema de Servicios al Hogar

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
</div>

## 📋 Descripción

MyWorksApp es un sistema completo de servicios al hogar que conecta usuarios con profesionales calificados. El proyecto incluye dos aplicaciones móviles desarrolladas en Flutter:

- **MyWorksApp User**: Aplicación para clientes que necesitan servicios
- **MyWorksApp Worker**: Aplicación para profesionales que ofrecen servicios

## 🏗️ Arquitectura del Sistema

### 📱 MyWorksApp User (Aplicación de Usuarios)
- **Ubicación**: `myworksapp-user/`
- **Propósito**: Permite a los usuarios solicitar servicios al hogar
- **Funcionalidades**:
  - Registro e inicio de sesión local
  - Explorar servicios disponibles
  - Ver profesionales disponibles con calificaciones
  - Solicitar servicios con detalles específicos
  - Gestionar solicitudes activas
  - Sistema de notificaciones push (Firebase)
  - Perfil de usuario personalizable
  - Historial de servicios

### 👷 MyWorksApp Worker (Aplicación de Trabajadores)
- **Ubicación**: `myworksapp-worker/`
- **Propósito**: Permite a los profesionales gestionar sus servicios
- **Funcionalidades**:
  - Registro de profesionales con verificación local
  - Gestión de perfil profesional
  - Recepción de solicitudes de trabajo
  - Aceptar/rechazar servicios
  - Sistema de notificaciones push (Firebase)
  - Historial de trabajos realizados
  - Gestión de disponibilidad

## 🚀 Características Principales

### 🔐 Seguridad
- Autenticación local con encriptación
- Validación de datos sensibles
- Gestión de permisos por rol

### 💾 Base de Datos
- **SQLite local** como base de datos principal
- Almacenamiento offline completo
- Gestión eficiente de datos locales
- Sincronización manual (no automática)

### 🔔 Notificaciones
- **Firebase Cloud Messaging** para notificaciones push
- Notificaciones locales para eventos importantes
- Alertas de nuevos servicios
- Recordatorios de citas

### 🎨 Interfaz de Usuario
- Diseño Material Design 3
- Interfaz intuitiva y responsive
- Modo oscuro/claro
- Accesibilidad mejorada

## 📁 Estructura del Repositorio

```
MyWorksApp/
├── myworksapp-user/          # Aplicación para usuarios (clientes)
│   ├── lib/
│   │   ├── pages/           # Páginas de la aplicación
│   │   ├── models/          # Modelos de datos
│   │   ├── services/        # Servicios y lógica de negocio
│   │   ├── database/        # Configuración SQLite
│   │   └── utils/           # Utilidades y constantes
│   ├── assets/              # Recursos (imágenes, iconos)
│   └── pubspec.yaml         # Dependencias del proyecto
├── myworksapp-worker/        # Aplicación para trabajadores
│   ├── lib/
│   │   ├── pages/           # Páginas de la aplicación
│   │   ├── models/          # Modelos de datos
│   │   ├── services/        # Servicios y lógica de negocio
│   │   ├── database/        # Configuración SQLite
│   │   └── utils/           # Utilidades y constantes
│   ├── assets/              # Recursos (imágenes, iconos)
│   └── pubspec.yaml         # Dependencias del proyecto
├── README.md                # Este archivo
└── .gitignore              # Archivos ignorados por Git
```

## 🛠️ Tecnologías Utilizadas

### Frontend
- **Flutter**: Framework de desarrollo multiplataforma
- **Dart**: Lenguaje de programación
- **Material Design 3**: Sistema de diseño

### Backend & Base de Datos
- **SQLite**: Base de datos local principal
- **Firebase Cloud Messaging**: Notificaciones push únicamente
- **Shared Preferences**: Almacenamiento de configuraciones

### Herramientas de Desarrollo
- **Android Studio / VS Code**: IDEs
- **Git**: Control de versiones
- **GitHub**: Repositorio remoto

## 📱 Requisitos del Sistema

### Para Desarrollo
- Flutter SDK 3.32.5 o superior
- Dart SDK 3.4.4 o superior
- Android Studio / VS Code
- Git

### Para Ejecución
- Android 5.0 (API 21) o superior
- iOS 11.0 o superior
- Conexión a internet para notificaciones push (opcional)

## ⚙️ Instalación y Configuración

### 1. Clonar el Repositorio
```bash
git clone https://github.com/MathiasAlejandr0/MyWorksAppProyect.git
cd MyWorksAppProyect
```

### 2. Configurar MyWorksApp User
```bash
cd myworksapp-user
flutter pub get
```

### 3. Configurar MyWorksApp Worker
```bash
cd ../myworksapp-worker
flutter pub get
```

### 4. Configurar Firebase (Opcional - Solo para notificaciones)
1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Descargar `google-services.json` para Android
3. Descargar `GoogleService-Info.plist` para iOS
4. Colocar archivos en las carpetas correspondientes
5. Habilitar Firebase Cloud Messaging

### 5. Ejecutar las Aplicaciones
```bash
# Para MyWorksApp User
cd myworksapp-user
flutter run

# Para MyWorksApp Worker
cd myworksapp-worker
flutter run
```

## 🔧 Configuración de Base de Datos

### SQLite (Base de Datos Principal)
- **Ubicación**: Base de datos local en el dispositivo
- **Tablas principales**:
  - `users`: Información de usuarios
  - `professionals`: Información de profesionales
  - `services`: Catálogo de servicios
  - `service_requests`: Solicitudes de servicio
  - `reviews`: Evaluaciones y comentarios
  - `notifications`: Notificaciones locales

### Firebase (Solo Notificaciones)
- **Firebase Cloud Messaging**: Para notificaciones push
- **Configuración mínima**: Solo para recibir notificaciones

## 📊 Funcionalidades por Aplicación

### MyWorksApp User
- [x] Registro e inicio de sesión local
- [x] Explorar servicios disponibles
- [x] Ver profesionales con calificaciones
- [x] Solicitar servicios
- [x] Gestionar solicitudes
- [x] Sistema de notificaciones push
- [x] Perfil de usuario
- [x] Historial de servicios

### MyWorksApp Worker
- [x] Registro de profesionales local
- [x] Gestión de perfil
- [x] Recepción de solicitudes
- [x] Aceptar/rechazar servicios
- [x] Notificaciones push
- [x] Historial de trabajos
- [x] Gestión de disponibilidad

## 🚀 Roadmap

### Próximas Funcionalidades
- [ ] Sincronización con servidor remoto
- [ ] Sistema de pagos integrado
- [ ] Chat en tiempo real
- [ ] Geolocalización de servicios
- [ ] Backup automático de datos
- [ ] Modo offline mejorado

## 📝 Notas Importantes

- **Base de Datos**: El sistema funciona completamente offline con SQLite
- **Notificaciones**: Requieren configuración de Firebase para funcionar
- **Datos**: Se almacenan localmente en el dispositivo
- **Sincronización**: Manual, no automática entre dispositivos

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 Soporte

Si tienes alguna pregunta o necesitas ayuda:

- 📧 Email: [tu-email@ejemplo.com]
- 🐛 Issues: [Crear un issue](https://github.com/MathiasAlejandr0/MyWorksAppProyect/issues)
- 📖 Documentación: [Wiki del proyecto](https://github.com/MathiasAlejandr0/MyWorksAppProyect/wiki)

## 🙏 Agradecimientos

- Flutter team por el excelente framework
- Firebase por la infraestructura backend
- Comunidad de desarrolladores Flutter
- Todos los contribuidores del proyecto

---

<div align="center">
  <p><strong>Desarrollado con ❤️ por</strong></p>
  <h3>Mathias Alejandro Jara Alvarado</h3>
  <p>Desarrollador Full Stack | Flutter Developer</p>
  
  [![GitHub](https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white)](https://github.com/MathiasAlejandr0)
  [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://linkedin.com/in/mathias-jara)
  
  <p><em>© 2025 MyWorksApp. Todos los derechos reservados.</em></p>
</div>
