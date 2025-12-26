import Foundation

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

class MovieService {
    static let shared = MovieService()
    
    private var apiKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String else {
            fatalError("API Key no configurada")
        }
        return key
    }
    
    private let baseURL = "https://api.themoviedb.org/3"
    
    // Obtener Películas (Populares, Búsqueda, Género)
    func fetchMovies(from endpoint: String, page: Int = 1, query: String? = nil, genreID: Int? = nil) async throws -> [Movie] {
        let effectiveEndpoint = genreID != nil ? "discover/movie" : endpoint
        
        guard var components = URLComponents(string: "\(baseURL)/\(effectiveEndpoint)") else {
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
        
        if let genreID = genreID {
            queryItems.append(URLQueryItem(name: "with_genres", value: "\(genreID)"))
            queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw MovieError.serverError
        }
        
        let result = try JSONDecoder().decode(MovieResponse.self, from: data)
        return result.results
    }
    
    // Obtener Lista de Géneros
    func fetchGenres() async throws -> [Genre] {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)&language=es-ES"
        guard let url = URL(string: urlString) else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MovieError.serverError
        }
        
        let result = try JSONDecoder().decode(GenreResponse.self, from: data)
        return result.genres
    }
    
    // Obtener Reparto (Cast)
    func fetchCast(for movieID: Int) async throws -> [Cast] {
        let urlString = "\(baseURL)/movie/\(movieID)/credits?api_key=\(apiKey)&language=es-ES"
        guard let url = URL(string: urlString) else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MovieError.serverError
        }
        
        let result = try JSONDecoder().decode(CreditsResponse.self, from: data)
        return result.cast
    }
    
    // Obtener Videos (Trailers)
    func fetchVideos(for movieID: Int) async throws -> [Video] {
        let urlString = "\(baseURL)/movie/\(movieID)/videos?api_key=\(apiKey)&language=es-ES"
        guard let url = URL(string: urlString) else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MovieError.serverError
        }
        
        let result = try JSONDecoder().decode(VideoResponse.self, from: data)
        return result.results
    }
    
    // Obtener Recomendaciones
    func fetchRecommendations(for movieID: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/movie/\(movieID)/recommendations?api_key=\(apiKey)&language=es-ES&page=1"
        guard let url = URL(string: urlString) else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MovieError.serverError
        }
        
        let result = try JSONDecoder().decode(MovieResponse.self, from: data)
        return result.results
    }
    
    // Obtener Detalles de Persona (Actor)
    func fetchPerson(id: Int) async throws -> Person {
        let urlString = "\(baseURL)/person/\(id)?api_key=\(apiKey)&language=es-ES"
        guard let url = URL(string: urlString) else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MovieError.serverError
        }
        
        return try JSONDecoder().decode(Person.self, from: data)
    }
    
    // Obtener Filmografía de Persona
    func fetchPersonCredits(id: Int) async throws -> [Movie] {
        let urlString = "\(baseURL)/person/\(id)/movie_credits?api_key=\(apiKey)&language=es-ES"
        guard let url = URL(string: urlString) else { throw MovieError.invalidURL }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw MovieError.serverError
        }
        
        let result = try JSONDecoder().decode(PersonMovieCredits.self, from: data)
        return result.cast
            .filter { $0.posterPath != nil } // Solo con foto
    }
}
