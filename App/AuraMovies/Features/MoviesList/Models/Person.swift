import Foundation

// Detalles del Actor
struct Person: Codable, Identifiable {
    let id: Int
    let name: String
    let biography: String
    let birthday: String?
    let placeOfBirth: String?
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, biography, birthday
        case placeOfBirth = "place_of_birth"
        case profilePath = "profile_path"
    }
    
    var profileURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(profilePath)")
    }
}

// Respuesta de la Filmografía (Películas donde ha salido)
struct PersonMovieCredits: Codable {
    let cast: [Movie] 
}
