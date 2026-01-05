import Foundation
import Observation

@Observable
class GenreResultsViewModel {
    var state: ViewState = .loading
    private let genreId: Int
    private let service = MovieService.shared
    
    private var allMovies: [Movie] = []
    private var currentPage = 1
    private var canLoadMore = true
    private var isLoadingPage = false
    
    init(genreId: Int) {
        self.genreId = genreId
    }
    
    @MainActor
    func loadInitial() async {
        state = .loading
        await fetchNextPage()
    }
    
    @MainActor
    func loadNextPageIfNeeded(movie: Movie) {
        guard let last = allMovies.last, last.id == movie.id, canLoadMore, !isLoadingPage else { return }
        Task { await fetchNextPage() }
    }
    
    @MainActor
    private func fetchNextPage() async {
        guard !isLoadingPage else { return }
        isLoadingPage = true
        
        do {
            // Usamos el parametro genreID del servicio actualizado
            let newMovies = try await service.fetchMovies(from: "discover/movie", page: currentPage, genreID: genreId)
            
            if newMovies.isEmpty {
                canLoadMore = false
            } else {
                allMovies.append(contentsOf: newMovies)
                currentPage += 1
                state = .success(allMovies)
            }
        } catch {
            if allMovies.isEmpty { state = .error(error.localizedDescription) }
        }
        isLoadingPage = false
    }
}
