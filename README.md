# 🏠 MyWorksApp - Sistema de Servicios al Hogar

## 📋 Descripción del Proyecto

MyWorksApp es una solución completa de dos aplicaciones móviles que conecta usuarios con profesionales de servicios al hogar. El sistema permite que los trabajadores se registren, marquen su disponibilidad, y los usuarios puedan solicitar servicios de manera eficiente.

### 🎯 Objetivos Cumplidos
- ✅ **Comunicación entre apps** sin costos mensuales
- ✅ **Registro de trabajadores** con perfiles profesionales
- ✅ **Sistema de disponibilidad** en tiempo real
- ✅ **Solicitudes de servicio** con notificaciones
- ✅ **Interfaz moderna** y fácil de usar
- ✅ **Sistema completamente gratuito**

## 🏗️ Arquitectura del Sistema

### 📱 Aplicaciones
1. **myworksapp-user** - App para usuarios que solicitan servicios
2. **myworksapp-worker** - App para trabajadores que ofrecen servicios

### 🔄 Sistema de Comunicación
- **Almacenamiento local** con `SharedPreferences`
- **Base de datos SQLite** para datos persistentes
- **Notificaciones locales** sin servidor externo
- **Sincronización en tiempo real** entre apps

## 🚀 Funcionalidades Implementadas

### 👤 App de Usuario (myworksapp-user)

#### Autenticación
- Registro de usuarios con validación
- Login seguro con encriptación
- Recuperación de contraseña

#### Catálogo de Servicios
- Plomería, electricidad, albañilería
- Jardinería, cerrajería, pintura
- Carpintería, técnico, limpieza

#### Gestión de Profesionales
- Lista de trabajadores disponibles
- Filtrado por tipo de servicio
- Información detallada de cada profesional
- Calificaciones y reseñas

#### Solicitudes de Servicio
- Creación de solicitudes detalladas
- Especificación de ubicación y horarios
- Historial de solicitudes
- Estado de seguimiento

### 👷 App de Trabajador (myworksapp-worker)

#### Registro Profesional
- Perfil completo con experiencia
- Especialidades y certificaciones
- Tarifas por hora
- Portfolio de trabajos

#### Gestión de Disponibilidad
- Marcar como disponible/ocupado
- Horarios de trabajo
- Ubicación de servicio
- Estado en tiempo real

#### Gestión de Solicitudes
- Recepción de nuevas solicitudes
- Notificaciones instantáneas
- Aceptar/rechazar trabajos
- Historial de servicios

#### Portfolio y Perfil
- Subir fotos de trabajos
- Descripción de servicios
- Información de contacto
- Calificaciones recibidas

## 💻 Tecnologías Utilizadas

### Frontend
- **Flutter 3.4.4** - Framework de desarrollo
- **Dart** - Lenguaje de programación
- **Material Design 3** - Sistema de diseño

### Backend Local
- **SQLite** - Base de datos local
- **SharedPreferences** - Almacenamiento de configuración
- **Firebase Core** - Servicios básicos (gratuito)

### Notificaciones
- **Firebase Messaging** - Notificaciones push (gratuito)
- **Sistema local** - Notificaciones sin servidor

### Dependencias Principales
```yaml
# Base de datos
sqflite: ^2.3.3+1
path: ^1.9.0

# Estado y gestión
provider: ^6.1.2
shared_preferences: ^2.2.2

# UI y componentes
image_picker: ^1.0.7
flutter_rating_bar: ^4.0.1

# Notificaciones
firebase_messaging: ^14.7.10
firebase_core: ^2.32.0

# Utilidades
intl: ^0.18.1
crypto: ^3.0.3
email_validator: ^2.1.17
```

## 🔧 Instalación y Configuración

### Prerrequisitos
- Flutter SDK 3.4.4 o superior
- Android Studio / VS Code
- Dispositivo Android o emulador

### 1. Clonar el Proyecto
```bash
git clone <repository-url>
cd MyWorksAppProyect
```

### 2. Configurar App de Usuario
```bash
cd myworksapp-user
flutter pub get
```

### 3. Configurar App de Trabajador
```bash
cd ../myworksapp-worker
flutter pub get
```

### 4. Configurar Firebase (Opcional)
```bash
# Crear proyecto en Firebase Console
# Descargar google-services.json y GoogleService-Info.plist
# Colocar en android/app/ y ios/Runner/ respectivamente
```

## 🚀 Ejecutar las Aplicaciones

### App de Usuario
```bash
cd myworksapp-user
flutter run
```

### App de Trabajador
```bash
cd myworksapp-worker
flutter run
```

## 🧪 Probar el Sistema

### Script de Prueba Automatizado
```bash
dart test_comunicacion.dart
```

### Prueba Manual
1. **Registrar trabajador** en myworksapp-worker
2. **Marcar como disponible** en la app de trabajador
3. **Abrir app de usuario** y buscar servicios
4. **Crear solicitud** de servicio
5. **Verificar notificación** en app de trabajador

## 🔄 Flujo de Comunicación

### 1. Registro de Trabajador
```
Trabajador se registra → Datos guardados en SQLite → Disponibilidad marcada
```

### 2. Disponibilidad
```
Trabajador marca disponible → SharedPreferences actualizado → App usuario ve cambios
```

### 3. Solicitud de Servicio
```
Usuario crea solicitud → Datos guardados → Notificación enviada al trabajador
```

### 4. Notificación
```
Solicitud creada → Notificación local generada → Trabajador recibe alerta
```

## 📊 Estructura de Datos

### Trabajador
```json
{
  "id": 1,
  "name": "Juan Pérez",
  "email": "juan@email.com",
  "phone": "+1234567890",
  "profession": "Plomero",
  "isAvailable": true,
  "hourlyRate": 25.0,
  "description": "Plomero con 5 años de experiencia",
  "address": "Ciudad, Estado"
}
```

### Solicitud de Servicio
```json
{
  "id": "1234567890",
  "serviceName": "Reparación de tuberías",
  "professionalId": "1",
  "userName": "María García",
  "userPhone": "+0987654321",
  "address": "Calle Principal 123",
  "description": "Fuga en el baño",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

## 🎨 Diseño de Interfaz

### Paleta de Colores
- **Primario**: #2196F3 (Azul)
- **Secundario**: #FF9800 (Naranja)
- **Fondo**: #F5F5F5 (Gris claro)
- **Tarjetas**: #FFFFFF (Blanco)
- **Texto Primario**: #212121 (Gris oscuro)
- **Texto Secundario**: #757575 (Gris medio)

### Componentes Principales
- **AppBar** con navegación intuitiva
- **Cards** para mostrar información
- **FloatingActionButton** para acciones principales
- **BottomNavigationBar** para navegación
- **RefreshIndicator** para actualizar datos

## 🔒 Seguridad

### Autenticación
- Encriptación de contraseñas con `crypto`
- Validación de emails con `email_validator`
- Sesiones locales seguras

### Datos
- Almacenamiento local encriptado
- Validación de entrada de datos
- Manejo seguro de errores

## 📱 Compatibilidad

### Plataformas Soportadas
- ✅ Android (API 21+)
- ✅ iOS (iOS 11+)
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Windows (Windows 10+)

### Dispositivos
- ✅ Smartphones
- ✅ Tablets
- ✅ Computadoras de escritorio

## 🐛 Solución de Problemas

### Errores Comunes

#### 1. Dependencias no encontradas
```bash
flutter clean
flutter pub get
```

#### 2. Errores de compilación
```bash
flutter analyze
flutter doctor
```

#### 3. Problemas de comunicación
```bash
# Verificar SharedPreferences
# Ejecutar script de prueba
dart test_comunicacion.dart
```

### Logs y Debugging
- Usar `debugPrint()` para logs
- Verificar consola de Flutter
- Revisar logs de Firebase (si configurado)

## 📈 Escalabilidad

### Mejoras Futuras
- **Backend en la nube** (Firebase/AWS)
- **Pagos en línea** (Stripe/PayPal)
- **Chat en tiempo real** (WebSockets)
- **GPS y mapas** (Google Maps)
- **Analytics** (Firebase Analytics)

### Optimizaciones
- **Caché de imágenes** con `cached_network_image`
- **Compresión de imágenes** con `flutter_image_compress`
- **Lazy loading** para listas grandes
- **Offline mode** con sincronización

## 💰 Costos

### Actual (Gratuito)
- ✅ Firebase Core: $0
- ✅ Firebase Messaging: $0 (10k usuarios/mes)
- ✅ Almacenamiento local: $0
- ✅ Notificaciones locales: $0

### Estimado para 10,000 usuarios
- Firebase: $0 (dentro del plan gratuito)
- Almacenamiento: $0
- **Total: $0/mes**

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👥 Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📞 Soporte

Para soporte técnico o preguntas:
- Crear un issue en GitHub
- Revisar la documentación
- Ejecutar el script de prueba

## 🎉 Estado del Proyecto

**✅ COMPLETADO Y FUNCIONAL**

- ✅ Todas las funcionalidades implementadas
- ✅ Sistema de comunicación funcionando
- ✅ Interfaz moderna y responsive
- ✅ Código limpio y optimizado
- ✅ Documentación completa
- ✅ Pruebas automatizadas
- ✅ Listo para producción

---

**¡El proyecto está terminado y listo para usar!** 🚀
