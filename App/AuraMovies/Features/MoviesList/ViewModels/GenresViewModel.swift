import Foundation
import Observation

@Observable
class GenresViewModel {
    var genres: [Genre] = []
    var isLoading = false
    
    func loadGenres() async {
        isLoading = true
        do {
            self.genres = try await MovieService.shared.fetchGenres()
        } catch {
            print("Error cargando géneros: \(error)")
        }
        isLoading = false
    }
}
