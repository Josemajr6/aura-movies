# 🎬 AuraMovies

<p align="center">
  <img src="App/AuraMovies/App/Assets.xcassets/AppIcon.appiconset/appiconauramovies.png" width="120" alt="Logo AuraMovies">
  <br>
  <b>Explora, descubre y organiza tu vida cinematográfica en iOS 🍿</b>
</p>

**AuraMovies** es una aplicación nativa de iOS desarrollada en **SwiftUI** con backend en **Vapor** que ofrece una experiencia inmersiva para descubrir películas. Utilizando la API de **TMDB (The Movie Database)** y un sistema completo de autenticación con MongoDB, la app permite navegar entre películas, actores y géneros, gestionando tu perfil de usuario de forma segura.

---

## ✨ Características Principales

### 🎭 Exploración de Películas
- **Listas Dinámicas**: "Estrenos", "Populares", "Top Rated" y la exclusiva "Selección AuraMovies" (Trending)
- **Detalle Completo**: Sinopsis, puntuación, año, trailers de YouTube integrados y reparto
- **Navegación Recursiva**: Película → Actor → Filmografía → Película (navegación infinita)
- **Búsqueda Inteligente**: Buscador en tiempo real con *debounce* para optimizar llamadas a la API
- **Categorías con Iconos**: Explora películas por género con iconos únicos y scroll infinito

### 👤 Sistema de Usuario
- **Autenticación Segura**: Registro, login y verificación por email
- **Login Flexible**: Inicia sesión con usuario o email
- **Verificación por Email**: Código de 6 dígitos enviado a tu correo
- **Validaciones Robustas**: Usuario, email y contraseña validados en tiempo real
- **Sign in with Apple**: Autenticación rápida con tu Apple ID
- **Recuperación de Contraseña**: Sistema completo vía email
- **Persistencia**: Sesiones guardadas de forma segura

### 🤝 Sistema Social
- **Perfiles de Usuario**: Ver perfiles de otros usuarios con películas favoritas y reseñas
- **Seguir Usuarios**: Sistema de seguidores y seguidos
- **Cuentas Privadas**: Opción de perfil privado con solicitudes de seguimiento
- **Gestión de Seguidores**: Acepta/rechaza solicitudes, elimina seguidores
- **Búsqueda de Usuarios**: Encuentra otros cinéfilos por nombre

### 🔔 Sistema de Notificaciones
- **Notificaciones Push Reales**: Recibe notificaciones en tu dispositivo incluso con la app cerrada
- **Notificaciones en la App**: Badge con contador de no leídas
- **Tipos de Notificaciones**:
  - 🔵 Nuevo seguidor
  - ✅ Solicitud de seguimiento aceptada
  - ⏰ Nueva solicitud de seguimiento pendiente
  - ✨ Recomendaciones de películas
  - 🔥 Películas en tendencia
- **Sincronización Automática**: Verifica nuevas notificaciones cada 30 segundos
- **Gestión Completa**: Marcar como leídas, eliminar, ver detalles

### 📱 Gestión Personal
- ❤️ **Favoritos**: Guarda las películas que amas
- ⭐ **Reseñas**: Escribe valoraciones (1-5 estrellas) y opiniones de las películas que has visto
- 👁️ **Historial**: Películas que has visto con tus reseñas completas
- 📊 **Estadísticas**: Contador de favoritos, películas vistas, seguidores y siguiendo
- 💾 **Sincronización**: Datos guardados localmente y en el servidor

### 🎨 Diseño Moderno
- **UI Adaptativa**: Soporte nativo para **Modo Oscuro**
- **Animaciones Fluidas**: Transiciones y efectos visuales
- **Diseño Premium**: Gradientes, sombras y elementos modernos
- **Iconos por Género**: Cada categoría tiene su icono único (⚡ 🗺️ 😊 ❤️ 🌙)
- **Responsive**: Optimizado para iPhone y iPad

---

## 🛠️ Stack Tecnológico

### Frontend (iOS)
- **Lenguaje**: Swift 5.9+
- **Framework**: SwiftUI con iOS 17+
- **Arquitectura**: MVVM + Framework `@Observable`
- **Concurrencia**: Swift Concurrency (`async/await`)
- **Networking**: `URLSession` + `Codable`
- **Persistencia**: UserDefaults + MongoDB (sincronización)
- **Autenticación**: AuthenticationServices (Sign in with Apple)
- **Notificaciones**: UserNotifications + APNs

### Backend
- **Framework**: Vapor 4.x
- **Lenguaje**: Swift 5.9+
- **Base de Datos**: MongoDB con FluentMongoDriver
- **Email**: SMTP con Gmail
- **Seguridad**: Bcrypt para hashing de contraseñas
- **API**: RESTful con JSON
- **Notificaciones Push**: Apple Push Notification service (APNs)

### APIs Externas
- **TMDB API**: The Movie Database
- **Gmail SMTP**: Envío de correos de verificación
- **Apple APNs**: Notificaciones push

---

## 🚀 Instalación y Configuración

### Requisitos Previos
- macOS 13+
- Xcode 15+
- Swift 5.9+
- MongoDB 6.0+
- Cuenta de Gmail (para envío de emails)

### Instalación Paso a Paso

#### 1. Clonar el repositorio
```bash
git clone https://github.com/tu-usuario/aura-movies.git
cd aura-movies
```

#### 2. Instalar MongoDB
```bash
# Con Homebrew (macOS)
brew tap mongodb/brew
brew install mongodb-community

# Iniciar MongoDB
brew services start mongodb-community

# Verificar instalación
mongosh
show dbs
exit
```

#### 3. Configurar Gmail para SMTP

**Importante**: Necesitas una "Contraseña de Aplicación", NO tu contraseña normal de Gmail.

1. Ve a [myaccount.google.com](https://myaccount.google.com/)
2. Navega a **Seguridad**
3. Activa la **Verificación en dos pasos** (si no la tienes)
4. Busca **Contraseñas de aplicación**
5. Genera una nueva para "Correo"
6. Copia la contraseña (16 caracteres sin espacios)

#### 4. Configurar Variables de Entorno

Edita el archivo `Backend/.env`:

```env
# MongoDB
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DATABASE=auramovies_db

# Servidor
PORT=8080

# Gmail SMTP (¡USA LA CONTRASEÑA DE APLICACIÓN!)
SMTP_EMAIL=tucorreo@gmail.com
SMTP_PASSWORD=xxxx xxxx xxxx xxxx

# TMDB API
TMDB_API_KEY=e415922e4ce74a94f75e5e34e1ae9a26
```

#### 5. Configurar la App iOS

**a) Crear archivo de configuración**

`App/AuraMovies/App/Config.xcconfig`:
```text
TMDB_API_KEY = e415922e4ce74a94f75e5e34e1ae9a26
```

**b) Añadir permisos en Info.plist**

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>Recibe notificaciones sobre seguimientos y actividad de películas</string>
```

**c) Habilitar Push Notifications en Xcode**

1. Abre el proyecto en Xcode
2. Selecciona el target **AuraMovies**
3. Ve a **Signing & Capabilities**
4. Haz clic en **+ Capability**
5. Busca y añade **Push Notifications**

#### 6. Iniciar el Backend

```bash
cd Backend
swift build
swift run
```

**Deberías ver:**
```
🔗 Conectando a MongoDB: mongodb://localhost:27017/auramovies_db
✅ Migraciones completadas
📬 Tabla 'notifications' creada
📱 Tabla 'device_tokens' creada
🚀 Servidor iniciado en http://localhost:8080
```

#### 7. Ejecutar la App iOS

```bash
cd ../App
open AuraMovies.xcodeproj
```

En Xcode:
1. Selecciona un simulador (iPhone 15 Pro recomendado)
2. Presiona **⌘R** para ejecutar
3. Al abrir, la app solicitará permisos de notificaciones → **Permitir**

---

## 📖 Uso de la Aplicación

### Sistema de Notificaciones

#### En Inicio (HomeView)
- Icono de **campana 🔔** en esquina superior derecha
- **Badge rojo** muestra el número de notificaciones no leídas
- Toca para ver todas las notificaciones

#### En Perfil
- Mismo botón de notificaciones disponible
- Ve estadísticas de seguidores y solicitudes pendientes
- **Badge rojo** en "Solicitudes" si hay pendientes

#### Notificaciones Push
- Aparecen en **pantalla de bloqueo** incluso con la app cerrada
- Banner en la parte superior si la app está abierta
- Toca la notificación para abrir la app y ver detalles

### Sistema Social

#### Buscar Usuarios
1. Ve a pestaña **"Buscar"**
2. Selecciona filtro **"Usuarios"**
3. Escribe el nombre del usuario
4. Toca un perfil para verlo

#### Seguir a Alguien
1. Entra en el perfil de un usuario
2. Toca **"Seguir"** (cuentas públicas) o **"Solicitar Seguir"** (cuentas privadas)
3. Si es privado, espera a que acepte tu solicitud
4. Recibirás una notificación cuando te acepte

#### Gestionar Solicitudes
1. Ve a tu **Perfil**
2. Si tienes solicitudes, verás un botón con badge rojo
3. Toca **"Solicitudes"**
4. **Acepta** o **Rechaza** cada solicitud
5. El usuario será notificado si aceptas

#### Eliminar Seguidores/Seguidos
1. Ve a tu **Perfil**
2. Toca **"Seguidores"** o **"Siguiendo"**
3. Al lado de cada usuario verás un botón **"X" rojo**
4. Toca para eliminar:
   - En "Seguidores": Quitas a alguien que te sigue
   - En "Siguiendo": Dejas de seguir a alguien

#### Cancelar Solicitud Pendiente
1. Ve al perfil del usuario al que enviaste solicitud
2. Verás botón **"Cancelar Solicitud"** en rojo
3. Toca para cancelar

### Reseñas de Películas

#### Crear una Reseña
1. Ve al detalle de una película
2. Toca el icono **👁️ (Ojo)**
3. Se abre la hoja de valoración
4. Selecciona **estrellas** (1-5)
5. Escribe tu **opinión** (opcional, máx. 280 caracteres)
6. Toca **"Publicar Valoración"**

#### Ver Reseñas de Otros
1. Busca un usuario
2. Entra en su perfil
3. Selecciona pestaña **"Reseñas"**
4. Verás sus películas con estrellas y textos completos

---

## 🏗️ Arquitectura del Proyecto

```
aura-movies/
│
├── App/                           # 📱 Aplicación iOS
│   ├── AuraMovies/
│   │   ├── App/                   # Configuración principal
│   │   │   ├── AuraMoviesApp.swift
│   │   │   ├── AppDelegate.swift  # ⭐ NUEVO: Manejo de notificaciones
│   │   │   ├── Assets.xcassets/
│   │   │   └── Config.xcconfig
│   │   │
│   │   ├── Core/                  # Lógica central
│   │   │   ├── FavoritesManager.swift
│   │   │   ├── HistoryManager.swift
│   │   │   ├── NotificationManager.swift  # ⭐ NUEVO
│   │   │   └── Networking/
│   │   │       ├── AuthService.swift
│   │   │       ├── MovieService.swift
│   │   │       └── UserService.swift
│   │   │
│   │   ├── Features/              # Módulos funcionales
│   │   │   ├── Auth/
│   │   │   │   ├── LoginView.swift
│   │   │   │   ├── VerificationView.swift
│   │   │   │   └── ResetPasswordView.swift
│   │   │   │
│   │   │   ├── MoviesList/
│   │   │   │   ├── Models/
│   │   │   │   ├── ViewModels/
│   │   │   │   └── Views/
│   │   │   │       ├── HomeView.swift  # ⭐ ACTUALIZADO: Notificaciones
│   │   │   │       ├── ProfileView.swift  # ⭐ ACTUALIZADO: Stats + Notif
│   │   │   │       ├── SearchView.swift
│   │   │   │       ├── NotificationsView.swift  # ⭐ NUEVO
│   │   │   │       ├── UserProfileView.swift  # ⭐ NUEVO
│   │   │   │       └── FollowRequestsView.swift  # ⭐ NUEVO
│   │   │   │
│   │   │   └── MovieDetail/
│   │   │       ├── MovieDetailView.swift
│   │   │       ├── ActorDetailView.swift
│   │   │       └── RateMovieSheet.swift  # ⭐ NUEVO
│   │   │
│   │   └── Info.plist
│   │
│   └── AuraMovies.xcodeproj
│
└── Backend/                       # 🖥️ Servidor Vapor
    ├── Sources/
    │   └── Backend/
    │       ├── Controllers/
    │       │   ├── AuthController.swift
    │       │   ├── MoviesInteractionController.swift
    │       │   ├── UserSearchController.swift  # ⭐ ACTUALIZADO
    │       │   ├── NotificationController.swift  # ⭐ NUEVO
    │       │   └── PushNotificationController.swift  # ⭐ NUEVO
    │       │
    │       ├── Models/
    │       │   ├── User.swift
    │       │   ├── Token.swift
    │       │   ├── UserMovie.swift
    │       │   ├── UserFollow.swift  # ⭐ NUEVO
    │       │   ├── Notification.swift  # ⭐ NUEVO
    │       │   └── DeviceToken.swift  # ⭐ NUEVO
    │       │
    │       ├── Migrations/
    │       │   ├── CreateUser.swift
    │       │   ├── CreateToken.swift
    │       │   ├── CreateUserMovie.swift
    │       │   ├── CreateUserFollow.swift  # ⭐ NUEVO
    │       │   ├── CreateNotification.swift  # ⭐ NUEVO
    │       │   └── CreateDeviceToken.swift  # ⭐ NUEVO
    │       │
    │       └── main.swift
    │
    ├── Package.swift
    └── .env
```

---

## 📡 Endpoints de la API

### Autenticación
```
POST   /auth/register              # Crear cuenta
POST   /auth/verify                # Verificar código email
POST   /auth/login                 # Iniciar sesión
POST   /auth/check-email           # Verificar si email existe
POST   /auth/forgot-password       # Solicitar reset de contraseña
POST   /auth/reset-password        # Confirmar reset
PUT    /auth/update-profile        # Actualizar perfil
PUT    /auth/change-password       # Cambiar contraseña
POST   /auth/upload-avatar         # Subir foto de perfil
PUT    /auth/update-privacy        # Cambiar privacidad
```

### Sistema Social
```
GET    /users/search?q=...         # Buscar usuarios
GET    /users/:id/profile          # Ver perfil
POST   /users/:id/follow           # Seguir usuario
DELETE /users/:id/unfollow         # Dejar de seguir
DELETE /users/:id/remove-follower  # ⭐ Eliminar seguidor
GET    /users/follow-requests      # Ver solicitudes
POST   /users/follow-requests/:id/accept   # Aceptar
POST   /users/follow-requests/:id/reject   # Rechazar
GET    /users/:id/followers        # Lista de seguidores
GET    /users/:id/following        # Lista de siguiendo
GET    /users/stats                # Estadísticas propias
```

### Notificaciones
```
GET    /notifications              # Obtener todas
PUT    /notifications/:id/read     # Marcar como leída
PUT    /notifications/read-all     # Marcar todas
DELETE /notifications/:id          # Eliminar una
GET    /notifications/unread-count # Contador no leídas
```

### Push Notifications
```
POST   /users/device-token         # Registrar token APNs
DELETE /users/device-token         # Eliminar token
```

### Películas
```
GET    /movies/profile             # Mis películas (favoritas/vistas)
GET    /movies/public-profile/:id  # Películas de otro usuario
POST   /movies/interact            # Marcar fav/vista/reseña
```

---

## 🔔 Sistema de Notificaciones - Flujo Completo

### 1. Registro del Dispositivo
```
App abre → AppDelegate solicita permisos
         → Usuario acepta
         → iOS genera Device Token
         → Token enviado a Backend
         → Backend guarda en DB
```

### 2. Evento (Ej: Alguien te sigue)
```
Usuario A → Sigue a Usuario B
          → Backend crea Follow
          → Backend crea Notification en DB
          → Backend busca device_tokens de B
          → Backend envía Push via APNs
          → iOS de B recibe Push
          → Aparece en pantalla de bloqueo
```

### 3. Usuario Abre la App
```
Usuario toca notificación Push
→ App se abre
→ AppDelegate llama a NotificationManager
→ NotificationManager sincroniza con backend
→ Actualiza badge y lista
→ Usuario ve notificación en la app
```

---

## 🧪 Testing

### Probar Notificaciones Push

#### En Simulador (Push Locales)
```bash
# Las notificaciones locales funcionan
# Verás banners en la parte superior
```

#### En Dispositivo Real (Push Reales)
```bash
# 1. Conecta iPhone físico
# 2. Configura certificado .p8 de Apple (ver sección Producción)
# 3. Ejecuta la app
# 4. Acepta permisos
# 5. Cierra la app completamente
# 6. Desde otra cuenta, sigue al usuario
# 7. Notificación aparece en pantalla de bloqueo
```

### Probar Sistema Social

#### Crear Cuentas de Prueba
```
Usuario A (Público):
- Email: testA@gmail.com
- Username: testA

Usuario B (Privado):
- Email: testB@gmail.com  
- Username: testB
- Activar "Cuenta Privada" en Editar Perfil
```

#### Flujo de Seguimiento
```
1. testA busca a testB
2. testA ve perfil de testB (candado 🔒)
3. testA toca "Solicitar Seguir"
4. testB recibe notificación push
5. testB abre app → Ve badge rojo en Solicitudes
6. testB acepta solicitud
7. testA recibe notificación "Solicitud aceptada"
8. testA puede ver películas de testB
```

---

## 🔐 Seguridad

- ✅ **Contraseñas hasheadas** con Bcrypt (factor 12)
- ✅ **Tokens UUID** únicos por sesión
- ✅ **Validaciones** en frontend y backend
- ✅ **Variables sensibles** en `.env` (excluido de Git)
- ✅ **CORS** configurado para desarrollo
- ✅ **Device tokens** almacenados de forma segura
- ✅ **Permisos de notificaciones** gestionados por iOS
- ⚠️ En producción, usa **HTTPS** siempre

---

## 📝 Roadmap

### ✅ Completado
- [x] Sistema de autenticación completo
- [x] Exploración de películas (TMDB)
- [x] Favoritos y películas vistas
- [x] Sistema de reseñas con estrellas
- [x] Perfiles de usuario con avatar
- [x] Sistema social (seguir/seguidores)
- [x] Cuentas privadas con solicitudes
- [x] Notificaciones en la app
- [x] Notificaciones push reales
- [x] Eliminar seguidores/seguidos
- [x] Login con email
- [x] Iconos en categorías
- [x] Recuperación de contraseña

### 🚧 En Desarrollo
- [ ] Comentarios en películas
- [ ] Feed de actividad de seguidos
- [ ] Listas personalizadas de películas

### 🔮 Futuras Funcionalidades
- [ ] Modo offline con caché
- [ ] Compartir películas con amigos
- [ ] Integración con servicios de streaming
- [ ] Widget de iOS
- [ ] Dark theme personalizable
- [ ] Mensajes directos entre usuarios

---

## 📞 Soporte

¿Necesitas ayuda?

1. **Revisa la documentación** en este README
2. **Abre un Issue** en GitHub con:
   - Descripción del problema
   - Logs del backend y la app
   - Versión de Xcode y macOS
3. **Consulta la documentación oficial**:
   - [TMDB API Docs](https://developers.themoviedb.org/3)
   - [Vapor Docs](https://docs.vapor.codes/4.0/)
   - [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)
   - [APNs Guide](https://developer.apple.com/documentation/usernotifications)

---

## 👨‍💻 Autor

**José Manuel Jiménez**

---

## 🙏 Agradecimientos

- **TMDB** por su increíble API de películas
- **Vapor** por el excelente framework de backend
- **Apple** por SwiftUI y las herramientas de desarrollo
- **MongoDB** por la base de datos flexible y potente
- La comunidad de Swift por su apoyo continuo

---

<p align="center">
  <b>¡Disfruta explorando el mundo del cine con AuraMovies! 🍿</b>
  <br><br>
  Desarrollado con ❤️ usando Swift, SwiftUI y Vapor
  <br>
  <b>v2.0 - Sistema Social y Notificaciones Push</b>
</p>
