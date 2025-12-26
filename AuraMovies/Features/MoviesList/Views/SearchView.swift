import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel() // Usa el ViewModel nuevo
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                switch viewModel.state {
                case .empty:
                    ContentUnavailableView("Buscador", systemImage: "magnifyingglass", description: Text("Escribe para buscar."))
                        .padding(.top, 50)
                    
                case .loading:
                    ProgressView().padding(.top, 50)
                    
                case .success(let movies):
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(movies) { movie in
                            NavigationLink(value: movie) {
                                MoviePosterCell(movie: movie) // Usa la celda corregida
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    
                    .navigationDestination(for: Cast.self) { actor in
                        ActorDetailView(actorId: actor.id, actorName: actor.name)
                    }
                case .error(let msg):
                    Text(msg)
                }
            }
            .navigationTitle("Buscar")
            .searchable(text: $viewModel.searchText)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
        }
    }
}
