import Foundation

// MARK: - DTOs para Búsqueda de Usuarios
struct UserSearchResult: Codable, Identifiable {
    let id: UUID
    let username: String
    let avatar: String?
    let isPrivate: Bool
    let followStatus: String?
    let followersCount: Int
    let followingCount: Int
    
    var avatarURL: URL? {
        guard let avatar = avatar else { return nil }
        return URL(string: "http://127.0.0.1:8080/avatars/\(avatar)")
    }
}

struct UserProfileResponse: Codable {
    let id: UUID
    let username: String
    let email: String?
    let avatar: String?
    let isPrivate: Bool
    let followStatus: String?
    let canViewProfile: Bool
    let followersCount: Int
    let followingCount: Int
    let favoriteMovies: [UserMovieBasic]?
    let watchedMovies: [UserMovieBasic]?
}

struct UserMovieBasic: Codable, Identifiable {
    let movieID: Int
    let title: String
    let posterPath: String?
    let userRating: Int?
    let userReview: String?
    
    var id: Int { movieID }
    
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
}

struct FollowRequestDTO: Codable, Identifiable {
    let id: UUID
    let follower: UserSearchResult
    let createdAt: Date
}

struct UserStatsResponse: Codable {
    let followersCount: Int
    let followingCount: Int
    let pendingRequestsCount: Int
}

// MARK: - Servicio de Usuarios
class UserService {
    static let shared = UserService()
    private let baseURL = "http://127.0.0.1:8080"
    
    private init() {}
    
    // MARK: - Búsqueda de Usuarios
    func searchUsers(query: String) async throws -> [UserSearchResult] {
        guard !query.isEmpty else { return [] }
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var components = URLComponents(string: "\(baseURL)/users/search")!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        
        guard let url = components.url else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([UserSearchResult].self, from: data)
    }
    
    // MARK: - Perfil de Usuario
    func getUserProfile(userID: UUID) async throws -> UserProfileResponse {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(userID.uuidString)/profile") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UserProfileResponse.self, from: data)
    }
    
    // MARK: - Seguir
    func followUser(userID: UUID) async throws {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(userID.uuidString)/follow") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Dejar de seguir
    func unfollowUser(userID: UUID) async throws {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(userID.uuidString)/unfollow") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - 🆕 Eliminar Seguidor (Quitar a alguien que te sigue)
    func removeFollower(userID: UUID) async throws {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(userID.uuidString)/remove-follower") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Solicitudes de Seguimiento
    func getFollowRequests() async throws -> [FollowRequestDTO] {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/follow-requests") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FollowRequestDTO].self, from: data)
    }
    
    func acceptFollowRequest(requestID: UUID) async throws {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/follow-requests/\(requestID.uuidString)/accept") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // GENERAR NOTIFICACIÓN AL ACEPTAR
        // (En un caso real, esto vendría del servidor)
        NotificationManager.shared.addNotification(AppNotification(
            type: .followRequestAccepted,
            title: "Solicitud aceptada",
            message: "Has aceptado una solicitud de seguimiento"
        ))
    }
    
    func rejectFollowRequest(requestID: UUID) async throws {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/follow-requests/\(requestID.uuidString)/reject") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    // MARK: - Listas
    func getFollowers(userID: UUID) async throws -> [UserSearchResult] {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(userID.uuidString)/followers") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([UserSearchResult].self, from: data)
    }
    
    func getFollowing(userID: UUID) async throws -> [UserSearchResult] {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/\(userID.uuidString)/following") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([UserSearchResult].self, from: data)
    }
    
    // MARK: - Estadísticas
    func getUserStats() async throws -> UserStatsResponse {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/users/stats") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(UserStatsResponse.self, from: data)
    }
    
    // MARK: - Actualizar Privacidad
    func updatePrivacy(isPrivate: Bool) async throws {
        guard let token = AuthService.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/auth/update-privacy") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["isPrivate": isPrivate]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
