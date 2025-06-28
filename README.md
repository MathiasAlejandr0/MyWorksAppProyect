# MyWorksApp - Sistema de Servicios al Hogar

Este repositorio contiene el sistema completo de MyWorksApp, una plataforma para conectar usuarios con profesionales de servicios al hogar.

## 📁 Estructura del Repositorio

```
MyWorksApp/
├── myworksapp-user/     # Aplicación para usuarios (clientes)
├── myworksapp-worker/   # Aplicación para trabajadores
└── README.md           # Este archivo
```

## 🏗️ Arquitectura del Sistema

### 📱 MyWorksApp User (Aplicación de Usuarios)
- **Ubicación**: `myworksapp-user/`
- **Propósito**: Permite a los usuarios solicitar servicios al hogar
- **Funcionalidades**:
  - Registro e inicio de sesión
  - Explorar servicios disponibles
  - Ver profesionales disponibles
  - Solicitar servicios
  - Gestionar solicitudes
  - Perfil de usuario

### 👷 MyWorksApp Worker (Aplicación de Trabajadores)
- **Ubicación**: `myworksapp-worker/`
- **Propósito**: Permite a los trabajadores registrarse y gestionar su disponibilidad
- **Funcionalidades**:
  - Registro de trabajadores con información detallada
  - Gestión de disponibilidad (disponible/ocupado)
  - Subida de fotos de trabajos previos
  - Certificados y títulos
  - Perfil profesional
  - Notificaciones

## 🔄 Integración de Base de Datos

El sistema utiliza una **base de datos compartida** que permite:
- Los trabajadores registrados en `myworksapp-worker` aparecen automáticamente en `myworksapp-user`
- Sincronización en tiempo real del estado de disponibilidad
- Compartir reseñas y calificaciones entre aplicaciones

## 🚀 Tecnologías Utilizadas

- **Framework**: Flutter
- **Base de Datos**: SQLite
- **Notificaciones**: Firebase Messaging
- **Estado**: Provider
- **Seguridad**: Crypto para hash de contraseñas
- **UI**: Material Design

## 📋 Requisitos

- Flutter SDK >= 3.4.4
- Dart SDK >= 3.4.4
- Android Studio / VS Code
- Dispositivo Android o emulador

## 🛠️ Instalación y Configuración

### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/MyWorksApp.git
cd MyWorksApp
```

### 2. Configurar la aplicación de usuarios
```bash
cd myworksapp-user
flutter pub get
flutter run
```

### 3. Configurar la aplicación de trabajadores
```bash
cd ../myworksapp-worker
flutter pub get
flutter run
```

## 📱 Compilación de APKs

### Aplicación de Usuarios
```bash
cd myworksapp-user
flutter build apk --debug
```

### Aplicación de Trabajadores
```bash
cd myworksapp-worker
flutter build apk --debug
```

## 🔧 Configuración de Firebase (Opcional)

Para habilitar las notificaciones push:

1. Crear proyecto en Firebase Console
2. Descargar `google-services.json` para Android
3. Colocar en `android/app/` de cada aplicación
4. Configurar Firebase Messaging

## 📊 Características Principales

### 🔐 Seguridad
- Hash de contraseñas con salt
- Validación de entrada de datos
- Gestión de sesiones segura

### 📱 Interfaz de Usuario
- Diseño Material Design
- Navegación intuitiva
- Estados de carga y error
- Filtros y búsqueda

### 🔄 Sincronización
- Base de datos compartida
- Actualización en tiempo real
- Gestión de conflictos

## 🧪 Testing

Cada aplicación incluye tests básicos:
```bash
cd myworksapp-user
flutter test

cd ../myworksapp-worker
flutter test
```

## 🤝 Contribución

1. Fork el proyecto
2. Crear una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir un Pull Request

## 📞 Contacto

- **Desarrollador**: Mathias Jara
- **Email**: tu-email@ejemplo.com
- **Proyecto**: [https://github.com/tu-usuario/MyWorksApp](https://github.com/tu-usuario/MyWorksApp)

## 🎯 Roadmap

- [ ] Implementar chat en tiempo real
- [ ] Sistema de pagos integrado
- [ ] Geolocalización de trabajadores
- [ ] Sistema de calificaciones avanzado
- [ ] Notificaciones push completas
- [ ] Modo offline
- [ ] Web dashboard para administradores

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

Desarrollado por Mathias Alejandro Jara Alvarado

## 📞 Soporte

Para soporte técnico o preguntas sobre el proyecto, por favor contacta al equipo de desarrollo.

---

⭐ Si este proyecto te resulta útil, ¡dale una estrella al repositorio!
