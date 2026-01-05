import SwiftUI

struct MovieListView: View {
    @State private var viewModel = MovieListViewModel()
    
    // Columnas adaptables: mínimo 160pt de ancho
    // Esto crea 2 columnas en iPhone y más en iPad
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 24)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .controlSize(.large)
                        .padding(.top, 100)
                    
                case .success(let movies):
                    LazyVGrid(columns: columns, spacing: 30) { // Spacing vertical entre filas
                        ForEach(movies) { movie in
                            NavigationLink(value: movie) {
                                MoviePosterCell(movie: movie)
                                    .onAppear {
                                        viewModel.loadNextPageIfNeeded(movie: movie)
                                    }
                            }
                            .buttonStyle(.plain) // Quita el efecto azul por defecto del enlace
                        }
                    }
                    .padding(24)
                    
                case .empty:
                    ContentUnavailableView.search
                        .padding(.top, 50)
                    
                case .error(let msg):
                    ContentUnavailableView("Error", systemImage: "exclamationmark.triangle", description: Text(msg))
                }
            }
            .navigationTitle("AuraMovies 🍿")
            .background(Color(uiColor: .systemGroupedBackground))
            .task {
                if viewModel.searchText.isEmpty {
                    await viewModel.loadMovies()
                }
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
}
