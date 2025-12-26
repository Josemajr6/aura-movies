import Foundation
import Observation

@Observable
class SearchViewModel {
    var state: ViewState = .empty // Empieza vacío
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
            try? await Task.sleep(nanoseconds: 500_000_000) /
            if Task.isCancelled || searchText.isEmpty { return }
            
            self.state = .loading
            do {
                let movies = try await service.fetchMovies(from: "search/movie", query: searchText)
                self.state = movies.isEmpty ? .empty : .success(movies)
            } catch {
                self.state = .error(error.localizedDescription)
            }
        }
    }
}
