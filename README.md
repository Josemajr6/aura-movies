# 🎬 AuraMovies

<p align="center">
  <img src="AuraMovies/App/Assets.xcassets/appiconauramovies.png" width="120" alt="Logo AuraMovies">
  <br>
  <b>Explora, descubre y organiza tu vida cinematográfica en iOS 🍿</b>
</p>

**AuraMovies** es una aplicación nativa de iOS desarrollada en **SwiftUI** que ofrece una experiencia inmersiva para descubrir películas. Utilizando la API de **TMDB (The Movie Database)**, la app permite navegar de forma "infinita" entre películas, actores y géneros, gestionando además un perfil de usuario persistente.

---

## ✨ Características

* **Exploración Dinámica**: Listas de "Estrenos", "Populares" y la exclusiva "Selección Aura" (Trending).
* **Detalle Profundo**: Sinopsis, puntuación, año, trailers de YouTube integrados y reparto.
* **Navegación Cruzada**: Sistema de navegación recursiva (Película -> Actor -> Filmografía -> Película).
* **Gestión de Perfil**:
    * ❤️ **Favoritos**: Guarda las películas que amas.
    * 👁️ **Vistas**: Historial de películas visualizadas.
    * Persistencia de datos local mediante `UserDefaults`.
* **Búsqueda Inteligente**: Buscador en tiempo real con *debounce* para optimizar llamadas a la API.
* **UI/UX Moderna**: Diseño adaptativo con soporte nativo para **Modo Oscuro**.

---

## 📱 Galería de la App

### 🌟 Vista General
<p align="center">
  <img src="AuraMovies/App/Assets.xcassets/vistaPrevia.png" width="500" alt="AuraMovies Mockup">
</p>

### 🧭 Navegación y Descubrimiento

| **Inicio (Home)** | **Categorías** | **Buscador** |
|:---:|:---:|:---:|
| ![Inicio](AuraMovies/App/Assets.xcassets/inicioVP.png) | ![Categorias](AuraMovies/App/Assets.xcassets/categoriasVP.png) | ![Buscador](AuraMovies/App/Assets.xcassets/buscadorVP.png) |
| *Tendencias* | *Géneros* | *Búsqueda* |

### 🎬 Detalle y Contenido

| **Detalle Película** | **Reparto y Extras** | **Ficha Actor** |
|:---:|:---:|:---:|
| ![Detalle Top](AuraMovies/App/Assets.xcassets/movieTOPVP.png) | ![Detalle Bottom](AuraMovies/App/Assets.xcassets/movieINFOVP.png) | ![Actor](AuraMovies/App/Assets.xcassets/actorVP.png) |
| *Info principal* | *Recomendaciones* | *Filmografía* |

### 👤 Usuario

| **Perfil de Usuario** |
|:---:|
| <img src="AuraMovies/App/Assets.xcassets/perfilVP.png" width="300"> |
| *Tus listas de Favoritos y Vistas* |

---

## 🛠️ Stack Tecnológico

* **Lenguaje**: Swift 5.0+ (SwiftUI)
* **Arquitectura**: MVVM + Framework `Observation`.
* **Concurrencia**: Swift Concurrency (`async/await`).
* **Red**: `URLSession` + `Codable`.
* **API**: [The Movie Database (TMDB)](https://www.themoviedb.org/documentation/api).

---

## 🚀 Instalación y Ejecución

1. **Clona el repositorio**:
   ```bash
   git clone [https://github.com/tu-usuario/AuraMovies.git](https://github.com/tu-usuario/AuraMovies.git)


2.  **Abre el proyecto**:
    Abre el archivo `AuraMovies.xcodeproj` en Xcode 15 o superior.

3.  **Configura la API Key (IMPORTANTE)**:
    El proyecto necesita un archivo de configuración que está ignorado en Git.
    * Regístrate en [TMDB](https://www.themoviedb.org/) y obtén tu API Key gratuita.
    * En Xcode, navega a la carpeta `AuraMovies/App/`.
    * Crea un nuevo archivo llamado **`Config.xcconfig`**.
    * Añade la siguiente línea dentro de ese archivo:
        ```text
        TMDB_API_KEY = tu_clave_de_tmdb_aqui
        ```

4.  **Compila y Ejecuta**:
    Selecciona un simulador (ej. iPhone 15 Pro) y pulsa `Cmd + R`.

---

## 🏗️ Arquitectura

El proyecto sigue una estructura modular limpia:

* **App**: Punto de entrada y configuración global.
* **Core**: Servicios de red (`MovieService`), Managers de persistencia (`FavoritesManager`, `HistoryManager`) y constantes.
* **Features**: Módulos funcionales (MoviesList, MovieDetail, etc.). Cada uno contiene:
    * *Models*: Estructuras de datos (`Movie`, `Cast`, `Video`).
    * *ViewModels*: Lógica de negocio y estado (`HomeViewModel`, `SearchViewModel`).
    * *Views*: Interfaz de usuario declarativa.

---

Desarrollado con ❤️ por **José Manuel Jiménez**
