import Foundation
import Observation

// Tipos de Búsqueda
enum SearchScope: String, CaseIterable {
    case movies = "Películas"
    case people = "Actores"
    case users = "Usuarios"
}

// Estados de la Vista
enum SearchState {
    case empty
    case loading
    case movies([Movie])
    case people([PersonSearchResult]) // 👈 Usamos el modelo seguro
    case users([UserDTO])
    case error(String)
}

@Observable
class SearchViewModel {
    var state: SearchState = .empty
    var scope: SearchScope = .movies {
        didSet { searchByText() }
    }
    
    var searchText: String = "" {
        didSet {
            if searchText.isEmpty {
                state = .empty
                searchTask?.cancel()
            } else {
                searchByText()
            }
        }
    }
    
    private let service = MovieService.shared
    private var searchTask: Task<Void, Never>?
    
    @MainActor
    func searchByText() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Espera 0.5s al escribir
            if Task.isCancelled || searchText.isEmpty { return }
            
            self.state = .loading
            
            do {
                switch scope {
                case .movies:
                    let movies = try await service.fetchMovies(from: "search/movie", query: searchText)
                    self.state = movies.isEmpty ? .empty : .movies(movies)
                    
                case .people:
                    let people = try await service.searchPeople(query: searchText)
                    self.state = people.isEmpty ? .empty : .people(people)
                    
                case .users:
                    let users = try await service.searchUsers(query: searchText)
                    self.state = users.isEmpty ? .empty : .users(users)
                }
            } catch {
                print("❌ Error en búsqueda: \(error)") // Log para depurar
                self.state = .error(error.localizedDescription)
            }
        }
    }
}
