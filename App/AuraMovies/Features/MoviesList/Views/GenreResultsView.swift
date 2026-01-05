import SwiftUI

struct GenreResultsView: View {
    let genre: Genre
    @State private var viewModel: GenreResultsViewModel
    
    init(genre: Genre) {
        self.genre = genre
        self._viewModel = State(initialValue: GenreResultsViewModel(genreId: genre.id))
    }
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        ScrollView {
            switch viewModel.state {
            case .loading:
                ProgressView().padding(.top, 50)
            case .success(let movies):
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(movies) { movie in
                        // Aquí solo emitimos el valor 'Movie'
                        NavigationLink(value: movie) {
                            MoviePosterCell(movie: movie)
                                .onAppear {
                                    viewModel.loadNextPageIfNeeded(movie: movie)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            case .error(let msg):
                ContentUnavailableView("Error", systemImage: "xmark.octagon", description: Text(msg))
            case .empty:
                ContentUnavailableView("Sin resultados", systemImage: "tray")
            }
        }
        .navigationTitle(genre.name)
        .task {
            await viewModel.loadInitial()
        }
        // AQUÍ NO DEBE HABER NINGÚN .navigationDestination
        // El 'GenresView' (padre) ya sabe qué hacer con las Movies.
    }
}
