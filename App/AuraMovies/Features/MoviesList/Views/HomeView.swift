import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    if viewModel.isLoading {
                        ProgressView().padding(.top, 50)
                    } else {
                        // SECCIONES
                        MovieSection(title: "Selección AuraMovies 🍿", movies: viewModel.auraSelection)
                        
                        Divider().padding(.horizontal) 
                        
                        MovieSection(title: "Últimos Estrenos 🔥", movies: viewModel.nowPlaying)
                        MovieSection(title: "Más Vistas", movies: viewModel.popular)
                        MovieSection(title: "Crítica Excelente ⭐️", movies: viewModel.topRated)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Inicio")
            // NAVEGACIÓN (Rutas)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationDestination(for: Cast.self) { actor in
                ActorDetailView(actorId: actor.id, actorName: actor.name)
            }
            .task {
                await viewModel.loadAllSections()
            }
        }
    }
}

// Subvista reutilizable (Igual que antes)
struct MovieSection: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .bold()
                .padding(.horizontal)
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        NavigationLink(value: movie) {
                            MoviePosterCell(movie: movie)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
