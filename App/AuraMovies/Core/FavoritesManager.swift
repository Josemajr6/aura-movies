import SwiftUI
import Observation

@Observable
class FavoritesManager {
    static let shared = FavoritesManager()
    
    // Ahora guardamos la lista de Películas enteras
    var movies: [Movie] = []
    
    private let saveKey = "FavoritesMovies"
    
    init() {
        // Cargar y decodificar al iniciar
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            if let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
                movies = decoded
            }
        }
    }
    
    // Función para añadir/borrar pasando la película entera
    func toggleFavorite(movie: Movie) {
        if let index = movies.firstIndex(where: { $0.id == movie.id }) {
            movies.remove(at: index)
        } else {
            movies.append(movie)
        }
        save()
    }
    
    func isFavorite(_ id: Int) -> Bool {
        movies.contains { $0.id == id }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(movies) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
}
