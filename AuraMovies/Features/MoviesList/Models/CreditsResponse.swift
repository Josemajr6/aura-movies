import Foundation

struct CreditsResponse: Codable {
    let cast: [Cast]
}

struct Cast: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, character
        case profilePath = "profile_path"
    }
    
    var profileURL: URL? {
        guard let profilePath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w200\(profilePath)")
    }
}
