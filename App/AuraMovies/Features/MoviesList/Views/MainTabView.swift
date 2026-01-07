import SwiftUI

// VISTA DE CATEGORÍAS CON ICONOS
struct GenresView: View {
    @State private var viewModel = GenresViewModel()
    let gradients: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal, .indigo]
    let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView().padding(.top, 50)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(viewModel.genres.enumerated()), id: \.element.id) { index, genre in
                            NavigationLink(value: genre) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(gradients[index % gradients.count].gradient)
                                        .frame(height: 100)
                                        .shadow(radius: 4)
                                    
                                    VStack(spacing: 8) {
                                        // ICONO DINÁMICO
                                        Image(systemName: getIconForGenre(genre.name))
                                            .font(.title)
                                            .foregroundColor(.white)
                                        
                                        Text(genre.name)
                                            .font(.subheadline)
                                            .bold()
                                            .foregroundColor(.white)
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Categorías")
            .task {
                if viewModel.genres.isEmpty {
                    await viewModel.loadGenres()
                }
            }
            .navigationDestination(for: Genre.self) { genre in
                GenreResultsView(genre: genre)
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationDestination(for: Cast.self) { actor in
                ActorDetailView(actorId: actor.id, actorName: actor.name)
            }
        }
    }
    
    // FUNCIÓN PARA ASIGNAR ICONOS
    func getIconForGenre(_ genreName: String) -> String {
        let name = genreName.lowercased()
        
        if name.contains("acción") || name.contains("action") {
            return "bolt.fill"
        } else if name.contains("aventura") || name.contains("adventure") {
            return "map.fill"
        } else if name.contains("animación") || name.contains("animation") {
            return "star.fill"
        } else if name.contains("comedia") || name.contains("comedy") {
            return "face.smiling.fill"
        } else if name.contains("crimen") || name.contains("crime") {
            return "exclamationmark.shield.fill"
        } else if name.contains("documental") || name.contains("documentary") {
            return "book.fill"
        } else if name.contains("drama") {
            return "theatermasks.fill"
        } else if name.contains("familia") || name.contains("family") {
            return "house.fill"
        } else if name.contains("fantasía") || name.contains("fantasy") {
            return "wand.and.stars"
        } else if name.contains("historia") || name.contains("history") {
            return "clock.fill"
        } else if name.contains("terror") || name.contains("horror") {
            return "moon.stars.fill"
        } else if name.contains("música") || name.contains("music") {
            return "music.note"
        } else if name.contains("misterio") || name.contains("mystery") {
            return "questionmark.circle.fill"
        } else if name.contains("romance") {
            return "heart.fill"
        } else if name.contains("ciencia ficción") || name.contains("science fiction") || name.contains("sci-fi") {
            return "sparkles"
        } else if name.contains("tv") || name.contains("televisión") {
            return "tv.fill"
        } else if name.contains("suspense") || name.contains("thriller") {
            return "eye.fill"
        } else if name.contains("bélica") || name.contains("war") || name.contains("guerra") {
            return "shield.fill"
        } else if name.contains("western") {
            return "star.circle.fill"
        } else {
            return "film.fill"
        }
    }
}

// MAIN TAB VIEW 
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
                .tag(0)
            
            GenresView()
                .tabItem {
                    Label("Categorías", systemImage: selectedTab == 1 ? "square.grid.2x2.fill" : "square.grid.2x2")
                }
                .tag(1)
            
            SearchView()
                .tabItem {
                    Label("Buscar", systemImage: selectedTab == 2 ? "magnifyingglass.circle.fill" : "magnifyingglass")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: selectedTab == 3 ? "person.circle.fill" : "person.circle")
                }
                .tag(3)
        }
        .tint(.blue)
        .onAppear {
            // Personalizar apariencia del TabBar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Sombra sutil
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
}
