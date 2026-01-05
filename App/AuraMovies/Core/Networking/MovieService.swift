import Foundation

// MARK: - Errores Personalizados
enum MovieError: Error, LocalizedError {
    case invalidURL, serverError, decodingError, unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .serverError: return "Error del servidor"
        case .decodingError: return "Error de datos"
        case .unknown(let e): return e.localizedDescription
        }
    }
}

// MARK: - DTOs para el Backend (Vapor)
struct UserMovieDTO: Codable, Identifiable {
    let id: UUID?
    let movieID: Int
    let title: String
    let posterPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let isFavorite: Bool
    let isWatched: Bool
    let userRating: Int?
    let userReview: String?
}

// MARK: - DTOs Seguros para Búsqueda (Actores)
// Esto evita que falle si la API no devuelve detalles completos
struct PersonSearchResponse: Codable {
    let results: [PersonSearchResult]
}

struct PersonSearchResult: Identifiable, Codable {
    let id: Int
    let name: String
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case profilePath = "profile_path"
    }
}

// MARK: - Servicio Principal
class MovieService {
    static let shared = MovieService()
    
    // Configuración TMDB
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String else {
            return "" // O manejar el error fatal
        }
        return key
    }
    private let tmdbBaseURL = "https://api.themoviedb.org/3"
    
    // Configuración Backend (Ajusta a tu IP local si usas iPhone físico)
    private let backendURL = "http://127.0.0.1:8080"
    
    private init() {}
    
    // MARK: - 🌍 TMDB API (Películas)
    
    // CORREGIDO: Se ha vuelto a añadir 'genreID' para que funcione GenreResultsViewModel
    func fetchMovies(from endpoint: String, page: Int = 1, query: String? = nil, genreID: Int? = nil) async throws -> [Movie] {
        // Si hay género, forzamos el endpoint de discover
        let effectiveEndpoint = genreID != nil ? "discover/movie" : endpoint
        
        guard var components = URLComponents(string: "\(tmdbBaseURL)/\(effectiveEndpoint)") else {
            throw MovieError.invalidURL
        }
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "es-ES"),
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        if let query = query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "query", value: query))
        }
        
        // Lógica de Géneros recuperada
        if let genreID = genreID {
            queryItems.append(URLQueryItem(name: "with_genres", value: "\(genreID)"))
            queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw MovieError.serverError
        }
        
        let result = try JSONDecoder().decode(MovieResponse.self, from: data)
        return result.results
    }
    
    // MARK: - 🔍 Búsqueda de Personas (Actores)
    // MARK: - 🔍 Búsqueda de Personas (Actores)
        func searchPeople(query: String) async throws -> [PersonSearchResult] {
            guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
            
            // Añadimos 'include_adult=false' por si acaso
            let urlString = "\(tmdbBaseURL)/search/person?api_key=\(apiKey)&language=es-ES&query=\(encodedQuery)&include_adult=false&page=1"
            
            guard let url = URL(string: urlString) else { throw MovieError.invalidURL }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                throw MovieError.serverError
            }
            
            // Usamos el modelo seguro
            let result = try JSONDecoder().decode(PersonSearchResponse.self, from: data)
            
            // ✅ FILTRO RESTAURADO: Solo mostramos gente CON FOTO.
            // Esto elimina la "basura" (gente sin imagen). Aaron Paul tiene foto, así que saldrá.
            return result.results.filter { $0.profilePath != nil && !$0.profilePath!.isEmpty }
        }
    
    // MARK: - 🔍 Búsqueda de Usuarios (Tu Backend)
    func searchUsers(query: String) async throws -> [UserDTO] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        guard let url = URL(string: "\(backendURL)/auth/search?query=\(encodedQuery)") else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return [] // Si falla, devolvemos lista vacía
        }
        
        return try JSONDecoder().decode([UserDTO].self, from: data)
    }
    
    // MARK: - Métodos Auxiliares
    
    func fetchGenres() async throws -> [Genre] {
        let url = URL(string: "\(tmdbBaseURL)/genre/movie/list?api_key=\(apiKey)&language=es-ES")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GenreResponse.self, from: data).genres
    }
    
    func fetchCast(for movieID: Int) async throws -> [Cast] {
        let url = URL(string: "\(tmdbBaseURL)/movie/\(movieID)/credits?api_key=\(apiKey)&language=es-ES")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(CreditsResponse.self, from: data).cast
    }
    
    func fetchVideos(for movieID: Int) async throws -> [Video] {
        let url = URL(string: "\(tmdbBaseURL)/movie/\(movieID)/videos?api_key=\(apiKey)&language=es-ES")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(VideoResponse.self, from: data).results
    }
    
    func fetchRecommendations(for movieID: Int) async throws -> [Movie] {
        let url = URL(string: "\(tmdbBaseURL)/movie/\(movieID)/recommendations?api_key=\(apiKey)&language=es-ES&page=1")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(MovieResponse.self, from: data).results
    }
    
    func fetchPerson(id: Int) async throws -> Person {
        let url = URL(string: "\(tmdbBaseURL)/person/\(id)?api_key=\(apiKey)&language=es-ES")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Person.self, from: data)
    }
    
    func fetchPersonCredits(id: Int) async throws -> [Movie] {
        let url = URL(string: "\(tmdbBaseURL)/person/\(id)/movie_credits?api_key=\(apiKey)&language=es-ES")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(PersonMovieCredits.self, from: data)
        return result.cast.filter { $0.posterPath != nil }
    }
    
    // MARK: - Métodos del Backend (Favoritos/Perfil)
    
    func fetchUserProfileMovies() async throws -> [UserMovieDTO] {
        guard let url = URL(string: "\(backendURL)/movies/profile") else { throw MovieError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = AuthService.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw MovieError.serverError }
        return try JSONDecoder().decode([UserMovieDTO].self, from: data)
    }
    
    func fetchPublicUserMovies(userID: UUID) async throws -> [UserMovieDTO] {
            guard let url = URL(string: "\(backendURL)/movies/public-profile/\(userID.uuidString)") else { throw MovieError.invalidURL }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            
            // Necesitamos el token para hacer la petición (ruta protegida)
            if let token = AuthService.shared.token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw MovieError.serverError
            }
            
            return try JSONDecoder().decode([UserMovieDTO].self, from: data)
        }
    
    func syncMovieInteraction(movie: Movie, isFavorite: Bool?, isWatched: Bool?, userRating: Int? = nil, userReview: String? = nil) async throws {
        guard let url = URL(string: "\(backendURL)/movies/interact") else { throw MovieError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = [
            "movieID": movie.id,
            "title": movie.title,
            "posterPath": movie.posterPath ?? "",
            "voteAverage": movie.voteAverage,
            "releaseDate": movie.releaseDate ?? ""
        ]

        if let fav = isFavorite { body["isFavorite"] = fav }
        if let watched = isWatched { body["isWatched"] = watched }
        // 👇 Enviamos reseña si existe
        if let rating = userRating { body["userRating"] = rating }
        if let review = userReview { body["userReview"] = review }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw MovieError.serverError }
    }
}
