import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    
    // Managers locales
    @State private var favorites = FavoritesManager.shared
    @State private var history = HistoryManager.shared
    
    // Estados de datos
    @State private var cast: [Cast] = []
    @State private var trailer: Video? = nil
    @State private var recommendations: [Movie] = []
    @State private var isLoadingExtras = false
    
    // Estado para la hoja de reseñas
    @State private var showReviewSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // --- CABECERA (POSTER + TRAILER) ---
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: movie.posterURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 350)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        colors: [.clear, .black.opacity(0.8)],
                                        startPoint: .center,
                                        endPoint: .bottom
                                    )
                                )
                        default:
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 350)
                        }
                    }
                    
                    if let trailerURL = trailer?.youtubeURL {
                        Link(destination: trailerURL) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Ver Trailer").fontWeight(.bold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        }
                        .padding(16)
                    }
                }
                
                // --- INFORMACIÓN ---
                VStack(alignment: .leading, spacing: 20) {
                    // Título y Valoración
                    VStack(alignment: .leading, spacing: 8) {
                        Text(movie.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Label(String(format: "%.1f", movie.voteAverage), systemImage: "star.fill")
                                .foregroundColor(.yellow)
                                .fontWeight(.bold)
                            Text("•").foregroundColor(.secondary)
                            Text(movie.releaseDate?.prefix(4) ?? "N/A")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                    
                    Divider()
                    
                    // Sinopsis
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sinopsis").font(.title3).bold()
                        Text(movie.overview.isEmpty ? "No hay descripción disponible." : movie.overview)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // Reparto
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reparto Principal").font(.title3).bold()
                        
                        if isLoadingExtras {
                            ProgressView().padding()
                        } else if cast.isEmpty {
                            Text("No disponible").font(.caption).foregroundColor(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(cast.prefix(10)) { actor in
                                        NavigationLink(value: actor) {
                                            VStack {
                                                AsyncImage(url: actor.profileURL) { image in
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Image(systemName: "person.circle.fill")
                                                        .resizable()
                                                        .foregroundColor(.gray.opacity(0.3))
                                                }
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                                .shadow(radius: 3)
                                                
                                                Text(actor.name)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .lineLimit(2)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 80)
                                                    .foregroundColor(.primary)
                                                
                                                Text(actor.character)
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                                    .frame(width: 80)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Recomendaciones
                    if !recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Te puede gustar").font(.title3).bold()
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(recommendations) { relatedMovie in
                                        NavigationLink(value: relatedMovie) {
                                            MoviePosterCell(movie: relatedMovie)
                                                .frame(width: 140)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        // --- BARRA SUPERIOR (BOTONES) ---
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    
                    // BOTÓN VISTO (OJO) - AHORA ABRE RESEÑA
                    Button {
                        // Si ya está vista, la desmarcamos (Unwatch)
                        if history.isSeen(movie.id) {
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                            withAnimation { history.toggleSeen(movie: movie) }
                            
                            // Avisamos al server que quitamos el visto
                            syncWithServer(isFavorite: nil, isWatched: false)
                        } else {
                            // Si NO está vista, abrimos la hoja de valorar
                            showReviewSheet = true
                        }
                    } label: {
                        Image(systemName: history.isSeen(movie.id) ? "eye.fill" : "eye")
                            .font(.title3)
                            .foregroundColor(history.isSeen(movie.id) ? .green : .blue)
                    }
                    
                    // BOTÓN FAVORITO (CORAZÓN)
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        withAnimation { favorites.toggleFavorite(movie: movie) }
                        
                        // Sincronización con el servidor
                        let isFav = favorites.isFavorite(movie.id)
                        syncWithServer(isFavorite: isFav, isWatched: nil)
                        
                    } label: {
                        Image(systemName: favorites.isFavorite(movie.id) ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(favorites.isFavorite(movie.id) ? .red : .blue)
                    }
                }
            }
        }
        // --- HOJA DE VALORACIÓN ---
        .sheet(isPresented: $showReviewSheet) {
            RateMovieSheet(movie: movie)
                .presentationDetents([.medium, .large])
        }
        // --- CARGA DE DATOS ---
        .task {
            if cast.isEmpty {
                isLoadingExtras = true
                do {
                    async let castResp = MovieService.shared.fetchCast(for: movie.id)
                    async let videoResp = MovieService.shared.fetchVideos(for: movie.id)
                    async let recsResp = MovieService.shared.fetchRecommendations(for: movie.id)
                    
                    let (fetchedCast, fetchedVideos, fetchedRecs) = try await (castResp, videoResp, recsResp)
                    
                    self.cast = fetchedCast
                    self.trailer = fetchedVideos.first { $0.type == "Trailer" && $0.site == "YouTube" }
                                   ?? fetchedVideos.first { $0.site == "YouTube" }
                    self.recommendations = fetchedRecs
                } catch {
                    print("Error cargando extras: \(error)")
                }
                isLoadingExtras = false
            }
        }
    }
    
    // Función auxiliar para sincronizar cambios simples (Favorito o Desmarcar Visto)
    func syncWithServer(isFavorite: Bool?, isWatched: Bool?) {
        Task {
            do {
                try await MovieService.shared.syncMovieInteraction(
                    movie: movie,
                    isFavorite: isFavorite,
                    isWatched: isWatched
                )
                print("✅ Sincronizado con servidor")
            } catch {
                print("❌ Error sincronizando: \(error.localizedDescription)")
            }
        }
    }
}
