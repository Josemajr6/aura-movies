import Foundation
import Observation

enum ViewState {
    case loading
    case success([Movie])
    case error(String)
    case empty
}

@Observable
class MovieListViewModel {
    var state: ViewState = .loading
    
    // Cuando el texto cambia, avisamos para buscar
    var searchText: String = "" {
        didSet {
            if searchText.isEmpty && oldValue != "" {
                Task { await loadMovies() } // Volver a populares si borra todo
            }
        }
    }
    
    private let service = MovieService.shared
    private var allMovies: [Movie] = []
    
    // Paginación
    private var currentPage = 1
    private var canLoadMore = true
    private var isLoadingPage = false
    
    // Control de búsqueda (Task para poder cancelar si escribe rápido)
    private var searchTask: Task<Void, Never>?
    
    @MainActor
    func loadMovies() async {
        resetPagination()
        await fetchNextPage()
    }
    
    // Función llamada al escribir
    @MainActor
    func searchByText() {
        searchTask?.cancel() // Cancelamos la búsqueda anterior
        
        searchTask = Task {
            // DEBOUNCE: Esperamos 0.5 segundos antes de disparar
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            if Task.isCancelled { return }
            if searchText.isEmpty { return }
            
            resetPagination()
            await fetchNextPage()
        }
    }
    
    @MainActor
    func loadNextPageIfNeeded(movie: Movie) {
        guard let last = allMovies.last, last.id == movie.id, canLoadMore, !isLoadingPage else { return }
        Task { await fetchNextPage() }
    }
    
    private func resetPagination() {
        state = .loading
        currentPage = 1
        allMovies = []
        canLoadMore = true
        isLoadingPage = false
    }
    
    @MainActor
    private func fetchNextPage() async {
        guard !isLoadingPage else { return }
        isLoadingPage = true
        
        do {
            let movies: [Movie]
            
            if searchText.isEmpty {
                // Modo Populares
                movies = try await service.fetchMovies(from: "movie/popular", page: currentPage)
            } else {
                // Modo Búsqueda Real
                movies = try await service.fetchMovies(from: "search/movie", page: currentPage, query: searchText)
            }
            
            if movies.isEmpty {
                canLoadMore = false
                if allMovies.isEmpty { state = .empty }
            } else {
                allMovies.append(contentsOf: movies)
                // Eliminamos duplicados por si la API se lía
                let unique = Array(Set(allMovies)).sorted {
                    allMovies.firstIndex(of: $0)! < allMovies.firstIndex(of: $1)!
                }
                allMovies = unique
                currentPage += 1
                state = .success(allMovies)
            }
        } catch {
            if allMovies.isEmpty { state = .error(error.localizedDescription) }
        }
        isLoadingPage = false
    }
}
