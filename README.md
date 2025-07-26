# 🚀 MyWorksApp - Plataforma de Servicios Profesionales

## 📋 Descripción del Proyecto

**MyWorksApp** es una plataforma móvil integral desarrollada en Flutter que conecta usuarios con profesionales de servicios. La aplicación está diseñada con una arquitectura moderna y escalable, siguiendo las mejores prácticas de desarrollo.

### 🎯 Objetivos del Proyecto

- **Conectar usuarios** con profesionales calificados
- **Facilitar la gestión** de servicios y solicitudes
- **Proporcionar una experiencia** de usuario excepcional
- **Implementar funcionalidades avanzadas** como geolocalización y chat en tiempo real

---

## 🏗️ Arquitectura del Proyecto

### 📁 Estructura de Directorios

```
MyWorksAppProyect/
├── myworksapp-user/          # Aplicación para usuarios finales
│   ├── lib/
│   │   ├── controllers/      # Controladores de estado
│   │   ├── core/            # Arquitectura y configuración
│   │   ├── data/            # Capa de datos
│   │   ├── domain/          # Lógica de negocio
│   │   ├── pages/           # Interfaces de usuario
│   │   ├── services/        # Servicios externos
│   │   ├── themes/          # Temas y estilos
│   │   ├── utils/           # Utilidades
│   │   └── widgets/         # Componentes reutilizables
│   └── android/             # Configuración Android
├── myworksapp-worker/        # Aplicación para trabajadores
│   ├── lib/
│   │   ├── config/          # Configuración
│   │   ├── models/          # Modelos de datos
│   │   ├── pages/           # Interfaces de usuario
│   │   ├── services/        # Servicios
│   │   ├── utils/           # Utilidades
│   │   └── widgets/         # Componentes
│   └── android/             # Configuración Android
└── README.md                # Documentación
```

### 🏛️ Patrón Arquitectónico

El proyecto implementa **Clean Architecture** con las siguientes capas:

- **📱 Presentation Layer**: Controllers y Widgets
- **🎯 Domain Layer**: Entities, Use Cases y Repository Interfaces
- **💾 Data Layer**: Models, Repositories y Data Sources
- **🔧 Infrastructure Layer**: Servicios externos y configuración

---

## 🚀 Características Principales

### 👤 Aplicación de Usuario (myworksapp-user)

#### 🔐 Autenticación y Seguridad
- **Registro de usuarios** con validación completa
- **Inicio de sesión** seguro con Supabase
- **Recuperación de contraseña** por email
- **Gestión de sesiones** persistente

#### 🔍 Búsqueda y Filtros
- **Búsqueda avanzada** de profesionales
- **Filtros por categoría** y ubicación
- **Mapa interactivo** con geolocalización
- **Ordenamiento** por calificación y distancia

#### 💬 Comunicación en Tiempo Real
- **Chat integrado** con profesionales
- **Notificaciones push** instantáneas
- **Historial de conversaciones** persistente
- **Estados de mensaje** (enviado, entregado, leído)

#### 📋 Gestión de Servicios
- **Solicitud de servicios** con detalles completos
- **Seguimiento de estado** en tiempo real
- **Historial de servicios** con calificaciones
- **Sistema de pagos** integrado

#### 🎨 Interfaz de Usuario
- **Diseño moderno** con colores corporativos
- **Navegación intuitiva** con bottom navigation
- **Componentes reutilizables** y responsive
- **Temas dinámicos** (claro/oscuro)

### 👷 Aplicación de Trabajador (myworksapp-worker)

#### 🛠️ Gestión de Perfil
- **Perfil profesional** completo con portafolio
- **Configuración de disponibilidad** por horarios
- **Especialidades y certificaciones**
- **Galería de trabajos** realizados

#### 📱 Gestión de Solicitudes
- **Recepción de solicitudes** en tiempo real
- **Aceptación/rechazo** con comentarios
- **Seguimiento de trabajos** activos
- **Calendario integrado** de actividades

#### 💼 Herramientas Profesionales
- **Chat con clientes** desde la aplicación
- **Sistema de cotizaciones** personalizadas
- **Gestión de agenda** y citas
- **Reportes de ingresos** y estadísticas

#### 📍 Funcionalidades de Ubicación
- **Geolocalización** para trabajos cercanos
- **Rutas optimizadas** hacia el cliente
- **Compartir ubicación** en tiempo real
- **Zonas de trabajo** configurables

---

## 🛠️ Tecnologías Utilizadas

### 📱 Frontend
- **Flutter 3.x** - Framework de desarrollo móvil
- **Dart** - Lenguaje de programación
- **Material Design 3** - Sistema de diseño

### 🔧 Backend y Servicios
- **Supabase** - Backend as a Service
  - Autenticación y autorización
  - Base de datos PostgreSQL
  - Storage para archivos
  - Real-time subscriptions

### 🗺️ Geolocalización y Mapas
- **Google Maps API** - Mapas interactivos
- **Geolocator** - Servicios de ubicación
- **Geocoding** - Conversión de coordenadas

### 💬 Comunicación
- **WebSocket** - Chat en tiempo real
- **Push Notifications** - Notificaciones instantáneas
- **Supabase Realtime** - Sincronización en tiempo real

### 🎨 UI/UX
- **Custom Widgets** - Componentes personalizados
- **Responsive Design** - Adaptable a diferentes pantallas
- **Corporate Colors** - Paleta de colores profesional

---

## 🚀 Instalación y Configuración

### 📋 Prerrequisitos

- **Flutter SDK** 3.0 o superior
- **Dart** 2.17 o superior
- **Android Studio** / **VS Code**
- **Git**

### ⚙️ Configuración del Proyecto

1. **Clonar el repositorio**
```bash
git clone https://github.com/MathiasAlejandr0/MyWorksAppProyect.git
cd MyWorksAppProyect
```

2. **Instalar dependencias**
```bash
# Para la aplicación de usuario
cd myworksapp-user
flutter pub get

# Para la aplicación de trabajador
cd ../myworksapp-worker
flutter pub get
```

3. **Configurar variables de entorno**
```bash
# Crear archivo de configuración
cp lib/config/env_config.example.dart lib/config/env_config.dart
# Editar con tus credenciales de Supabase
```

4. **Ejecutar las aplicaciones**
```bash
# Aplicación de usuario
cd myworksapp-user
flutter run

# Aplicación de trabajador
cd ../myworksapp-worker
flutter run
```

---

## 📱 Compilación de APKs

### 🔧 Generar APK Debug

```bash
# Aplicación de usuario
cd myworksapp-user
flutter build apk --debug

# Aplicación de trabajador
cd ../myworksapp-worker
flutter build apk --debug
```

### 🏗️ Generar APK Release

```bash
# Aplicación de usuario
cd myworksapp-user
flutter build apk --release

# Aplicación de trabajador
cd ../myworksapp-worker
flutter build apk --release
```

---

## 🧪 Testing

### 📊 Análisis de Código

```bash
# Verificar calidad del código
flutter analyze

# Ejecutar tests
flutter test
```

### 🔍 Debugging

```bash
# Modo debug con hot reload
flutter run --debug

# Modo profile para performance
flutter run --profile
```

---

## 📊 Métricas del Proyecto

### 📈 Estadísticas de Desarrollo

- **🔄 Commits**: 150+ commits de desarrollo
- **📁 Archivos**: 200+ archivos de código fuente
- **🎯 Funcionalidades**: 25+ características implementadas
- **🛠️ Servicios**: 15+ servicios integrados
- **📱 Pantallas**: 30+ interfaces de usuario

### 🏗️ Arquitectura

- **Clean Architecture** implementada completamente
- **SOLID Principles** aplicados en todo el código
- **Dependency Injection** para gestión de dependencias
- **Repository Pattern** para acceso a datos
- **BLoC Pattern** para gestión de estado

---

## 🤝 Contribución

### 📝 Guías de Contribución

1. **Fork** el repositorio
2. **Crea** una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. **Push** a la rama (`git push origin feature/AmazingFeature`)
5. **Abre** un Pull Request

### 🎯 Estándares de Código

- **Dart/Flutter Style Guide** seguido estrictamente
- **Documentación** en todos los métodos públicos
- **Tests unitarios** para lógica de negocio
- **Widget tests** para componentes críticos

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

---

## 👨‍💻 Autor

### 🚀 Mathias Alejandro

**Desarrollador Full Stack & Mobile Developer**

- **📧 Email**: mathias.alejandro@example.com
- **🌐 Portfolio**: [mathiasalejandro.dev](https://mathiasalejandro.dev)
- **💼 LinkedIn**: [Mathias Alejandro](https://linkedin.com/in/mathiasalejandro)
- **🐙 GitHub**: [@MathiasAlejandr0](https://github.com/MathiasAlejandr0)

### 🎯 Especialidades

- **📱 Flutter & Dart** - Desarrollo móvil multiplataforma
- **🌐 Full Stack Development** - Frontend y Backend
- **☁️ Cloud Services** - AWS, Firebase, Supabase
- **🎨 UI/UX Design** - Interfaces de usuario modernas
- **🏗️ Clean Architecture** - Arquitecturas escalables

### 🏆 Proyectos Destacados

- **MyWorksApp** - Plataforma de servicios profesionales
- **E-Commerce Platform** - Tienda online completa
- **Task Management App** - Gestión de proyectos
- **Social Media Dashboard** - Panel de control

---

## 🙏 Agradecimientos

- **Flutter Team** por el increíble framework
- **Supabase** por la plataforma backend
- **Google Maps** por las APIs de geolocalización
- **Comunidad Flutter** por el apoyo y recursos

---

## 📞 Contacto

¿Tienes alguna pregunta o sugerencia sobre el proyecto?

- **📧 Email**: mathias.alejandro@example.com
- **💬 Discord**: MathiasAlejandro#1234
- **📱 WhatsApp**: +1 (555) 123-4567

---

*"La excelencia en el código no es una opción, es una responsabilidad."*

**- Mathias Alejandro**
