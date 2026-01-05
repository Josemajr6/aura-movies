import SwiftUI
import Observation

@Observable
class HistoryManager {
    static let shared = HistoryManager()
    
    // Lista de películas vistas
    var movies: [Movie] = []
    
    private let saveKey = "WatchedMovies"
    
    init() {
        // Cargar al iniciar
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
                movies = decoded
            }
        }
    }
    
    // Marcar/Desmarcar como vista
    func toggleSeen(movie: Movie) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies.remove(at: index)
        } else {
            // La añadimos al principio para que salga la última vista primero
            movies.insert(movie, at: 0) 
        }
        save()
    }
    
    func isSeen(_ id: Int) -> Bool {
        movies.contains { $0.id == id }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(movies) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
