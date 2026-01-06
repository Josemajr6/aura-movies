# 🎬 AuraMovies

<p align="center">
  <img src="App/AuraMovies/App/Assets.xcassets/AppIcon.appiconset/appiconauramovies.png" width="120" alt="Logo AuraMovies">
  <br>
  <b>Explora, descubre y organiza tu vida cinematográfica en iOS 🍿</b>
</p>

**AuraMovies** es una aplicación nativa de iOS desarrollada en **SwiftUI** con backend en **Vapor** que ofrece una experiencia inmersiva para descubrir películas. Utilizando la API de **TMDB (The Movie Database)** y un sistema completo de autenticación con MongoDB, la app permite navegar entre películas, actores y géneros, gestionando tu perfil de usuario de forma segura.

---

## 📸 Capturas de Pantalla

<p align="center">
  <img src="screenshots/home.png" width="200" alt="Inicio"/>
  <img src="screenshots/detail.png" width="200" alt="Detalle"/>
  <img src="screenshots/profile.png" width="200" alt="Perfil"/>
  <img src="screenshots/notifications.png" width="200" alt="Notificaciones"/>
</p>

<p align="center">
  <img src="screenshots/search.png" width="200" alt="Búsqueda"/>
  <img src="screenshots/reviews.png" width="200" alt="Reseñas"/>
  <img src="screenshots/categories.png" width="200" alt="Categorías"/>
  <img src="screenshots/social.png" width="200" alt="Social"/>
</p>

### 🎯 Características Destacadas

| Característica | Descripción | Screenshot |
|---------------|-------------|------------|
| **🏠 Inicio** | Explora listas curadas de películas: Trending, Estrenos, Populares y Top Rated | `screenshots/home.png` |
| **🎬 Detalle de Película** | Sinopsis completa, trailers, reparto y recomendaciones | `screenshots/detail.png` |
| **⭐ Sistema de Reseñas** | Valora películas con estrellas y escribe opiniones | `screenshots/reviews.png` |
| **👤 Perfil de Usuario** | Gestiona tus favoritas, reseñas y seguidores | `screenshots/profile.png` |
| **🔔 Notificaciones** | Push reales y solicitudes de seguimiento integradas | `screenshots/notifications.png` |
| **🔍 Búsqueda Avanzada** | Busca películas, actores y usuarios | `screenshots/search.png` |
| **🎭 Categorías** | Explora por géneros con iconos únicos | `screenshots/categories.png` |
| **🤝 Red Social** | Sigue usuarios, perfiles públicos/privados | `screenshots/social.png` |

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
- **Perfiles de Usuario**: Ver perfiles de otros usuarios con películas favoritas y reseñas completas
- **Seguir Usuarios**: Sistema de seguidores y seguidos
- **Cuentas Privadas**: Opción de perfil privado con solicitudes de seguimiento
- **Gestión de Seguidores**: Acepta/rechaza solicitudes desde notificaciones, elimina seguidores
- **Búsqueda de Usuarios**: Encuentra otros cinéfilos por nombre

### 🔔 Sistema de Notificaciones
- **Notificaciones Push Reales**: Recibe notificaciones en tu dispositivo incluso con la app cerrada
- **Badge Inteligente**: Contador de notificaciones + solicitudes pendientes
- **Solicitudes Integradas**: Gestiona solicitudes directamente desde la campana 🔔
- **Tipos de Notificaciones**:
  - 🔵 Nuevo seguidor
  - ✅ Solicitud de seguimiento aceptada
  - ⏰ Nueva solicitud de seguimiento pendiente
  - ✨ Recomendaciones de películas
  - 🔥 Películas en tendencia
- **Sincronización Automática**: Verifica nuevas notificaciones cada 30 segundos
- **Gestión Completa**: Marcar como leídas, eliminar, aceptar/rechazar solicitudes

### 📱 Gestión Personal
- ❤️ **Favoritos**: Guarda las películas que amas
- ⭐ **Reseñas Completas**: Escribe valoraciones (1-5 estrellas) y opiniones de hasta 280 caracteres
- 👁️ **Historial Detallado**: Películas vistas con estrellas y comentarios completos visibles
- 📊 **Estadísticas**: Contador de favoritos, películas vistas, seguidores y siguiendo
- 💾 **Sincronización**: Datos guardados localmente y en el servidor

### 🎨 Diseño Moderno
- **UI Adaptativa**: Soporte nativo para **Modo Oscuro**
- **Animaciones Fluidas**: Transiciones y efectos visuales
- **Diseño Premium**: Gradientes, sombras y elementos modernos
- **Iconos por Género**: Cada categoría tiene su icono único (⚡ 🗺️ 😊 ❤️ 🌙)
- **Responsive**: Optimizado para iPhone y iPad

---

## 📷 Guía para Añadir Capturas

### Crear carpeta de screenshots

```bash
# En la raíz del proyecto
mkdir screenshots
```

### Tomar capturas en Xcode

1. **Ejecuta la app** en simulador (iPhone 15 Pro recomendado)
2. **Navega a cada pantalla**:
   - Inicio (HomeView)
   - Detalle de película
   - Perfil
   - Notificaciones con solicitudes
   - Búsqueda
   - Reseñas con estrellas
   - Categorías
   - Perfil de otro usuario
3. **Captura**: `⌘ + S` (se guarda en Escritorio)
4. **Renombra** los archivos:
   ```
   home.png
   detail.png
   profile.png
   notifications.png
   search.png
   reviews.png
   categories.png
   social.png
   ```
5. **Mueve** a la carpeta `screenshots/`

### Formato recomendado

- **Resolución**: 1170 x 2532 (iPhone 15 Pro)
- **Formato**: PNG
- **Orientación**: Vertical
- **Modo**: Claro o Oscuro (consistente)

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

### Instalación Rápida

```bash
# 1. Clonar repositorio
git clone https://github.com/tu-usuario/aura-movies.git
cd aura-movies

# 2. Instalar MongoDB
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb-community

# 3. Configurar Backend
cd Backend
cp .env.example .env
# Edita .env con tus credenciales

# 4. Iniciar Backend
swift run

# 5. Abrir App
cd ../App
open AuraMovies.xcodeproj
```

Para instrucciones detalladas, consulta la [Guía de Instalación Completa](#instalación-paso-a-paso).

---

## 📖 Uso Destacado

### 🔔 Notificaciones con Solicitudes

La campana ahora muestra **dos tipos** de contenido:

1. **Solicitudes de Seguimiento** (Sección superior)
   - Acepta o rechaza directamente
   - Badge naranja con icono ⏰
   
2. **Notificaciones Normales** (Sección inferior)
   - Nuevos seguidores
   - Solicitudes aceptadas
   - Recomendaciones

**Badge inteligente**: `notificaciones no leídas + solicitudes pendientes`

### ⭐ Reseñas Completas

**Ver tus reseñas**:
1. Ve a tu Perfil
2. Selecciona pestaña **"Reseñas"**
3. Verás:
   - Poster de la película
   - **Estrellas** (1-5)
   - **Texto completo** de tu opinión

**Ver reseñas de otros**:
1. Busca un usuario
2. Entra en su perfil (si es público o te sigue)
3. Pestaña **"Reseñas"**
4. Lee sus valoraciones completas

---

## 🎯 Características v2.1

### ✅ Mejoras Implementadas

- [x] **Solicitudes en la Campana**: Gestiona todo desde un solo lugar
- [x] **Badge Mejorado**: Notificaciones + Solicitudes
- [x] **Reseñas Completas**: Visualización de estrellas y comentarios
- [x] **Login con Email**: Inicia sesión con usuario o correo
- [x] **Perfil Limpio**: Solicitudes movidas a notificaciones

---

## 📡 Endpoints Principales

```
# Autenticación
POST   /auth/register              # Crear cuenta
POST   /auth/login                 # Login con usuario o email ⭐ NUEVO

# Sistema Social
GET    /users/search?q=...         # Buscar usuarios
POST   /users/:id/follow           # Seguir
DELETE /users/:id/remove-follower  # Eliminar seguidor

# Notificaciones
GET    /notifications              # Obtener todas + solicitudes
GET    /users/follow-requests      # Solicitudes pendientes

# Películas
POST   /movies/interact            # Marcar fav/vista/reseña completa
```

---

## 🔐 Seguridad

- ✅ **Contraseñas hasheadas** con Bcrypt (factor 12)
- ✅ **Tokens UUID** únicos por sesión
- ✅ **Login flexible**: Busca por username o email
- ✅ **Validaciones** en frontend y backend
- ✅ **Variables sensibles** en `.env` (excluido de Git)
- ✅ **Device tokens** almacenados de forma segura
- ⚠️ En producción, usa **HTTPS** siempre

---

## 📝 Changelog

### v2.1 (Última versión)
- ✨ Solicitudes de seguimiento integradas en notificaciones
- ✨ Badge inteligente (notificaciones + solicitudes)
- ✨ Reseñas completas con estrellas y texto visible
- ✨ Login con email además de usuario
- 🐛 Corrección de errores de sincronización
- 🎨 Perfil simplificado y más limpio

### v2.0
- ✨ Sistema social completo
- ✨ Notificaciones push reales
- ✨ Perfiles públicos/privados
- ✨ Sistema de reseñas

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
  <b>v2.1 - Notificaciones Mejoradas y Reseñas Completas</b>
</p>
