// Features/MoviesList/ViewModels/HomeViewModel.swift
import Foundation
import Observation

@Observable
class HomeViewModel {
    // 4 Arrays de películas
    var auraSelection: [Movie] = [] // 👈 NUEVA: La selección especial
    var nowPlaying: [Movie] = []
    var popular: [Movie] = []
    var topRated: [Movie] = []
    
    var isLoading = true
    
    private let service = MovieService.shared
    
    @MainActor
    func loadAllSections() async {
        isLoading = true
        do {
            // Descargamos 4 cosas a la vez en paralelo
            async let auraResponse = service.fetchMovies(from: "trending/movie/day") 
            async let nowPlayingResponse = service.fetchMovies(from: "movie/now_playing")
            async let popularResponse = service.fetchMovies(from: "movie/popular")
            async let topRatedResponse = service.fetchMovies(from: "movie/top_rated")
            
            // Esperamos a todas
            let (aura, np, pop, tr) = try await (auraResponse, nowPlayingResponse, popularResponse, topRatedResponse)
            
            self.auraSelection = aura
            self.nowPlaying = np
            self.popular = pop
            self.topRated = tr
        } catch {
            print("Error cargando secciones: \(error)")
        }
        isLoading = false
    }
}
