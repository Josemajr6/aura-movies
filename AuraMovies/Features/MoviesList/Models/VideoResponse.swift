import Foundation

struct VideoResponse: Codable {
    let results: [Video]
}

struct Video: Codable, Identifiable {
    let id: String
    let key: String // La ID de YouTube
    let name: String
    let site: String
    let type: String
    
    // Generamos la URL real de YouTube
    var youtubeURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}
