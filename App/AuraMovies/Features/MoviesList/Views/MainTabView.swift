import SwiftUI

// VISTA DE CATEGORÍAS
struct GenresView: View {
    @State private var viewModel = GenresViewModel()
    let gradients: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo]
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading { ProgressView().padding(.top, 50) } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(viewModel.genres.enumerated()), id: \.element.id) { index, genre in
                            NavigationLink(value: genre) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16).fill(gradients[index % gradients.count].gradient).frame(height: 100).shadow(radius: 4)
                                    Text(genre.name).font(.title3).bold().foregroundColor(.white).shadow(radius: 2)
                                }
                            }.buttonStyle(.plain)
                        }
                    }.padding()
                }
            }
            .navigationTitle("Categorías")
            .task { if viewModel.genres.isEmpty { await viewModel.loadGenres() } }
            .navigationDestination(for: Genre.self) { genre in GenreResultsView(genre: genre) }
            .navigationDestination(for: Movie.self) { movie in MovieDetailView(movie: movie) }
            .navigationDestination(for: Cast.self) { actor in ActorDetailView(actorId: actor.id, actorName: actor.name) }
        }
    }
}

// 2. MAIN TAB 
struct MainTabView: View {
    var body: some View {
        TabView {
            // Tab 1: Inicio
            HomeView()
                .tabItem { Label("Inicio", systemImage: "house.fill") }
            
            // Tab 2: Categorías
            GenresView()
                .tabItem { Label("Categorías", systemImage: "square.grid.2x2.fill") }
            
            // Tab 3: Búsqueda
            SearchView()
                .tabItem { Label("Buscar", systemImage: "magnifyingglass") }
            
            // Tab 4: PERFIL (Nuevo)
            ProfileView()
                .tabItem { Label("Perfil", systemImage: "person.circle.fill") }
        }
        .tint(.blue)
    }
}
