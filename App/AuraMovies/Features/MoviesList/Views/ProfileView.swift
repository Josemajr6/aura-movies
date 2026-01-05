import SwiftUI

struct ProfileView: View {
    @StateObject private var authService = AuthService.shared
    
    @State private var favorites = FavoritesManager.shared
    @State private var history = HistoryManager.shared
    
    // Estado para mostrar hojas
    @State private var showingEditSheet = false
    @State private var showingFollowRequests = false
    @State private var showFollowers = false
    @State private var showFollowing = false
    
    // Datos del servidor
    @State private var serverMovies: [UserMovieDTO] = []
    @State private var isLoading = false
    
    // Estadísticas
    @State private var stats: UserStatsResponse?
    
    @State private var selectedList = "Favoritas"
    let listTypes = ["Favoritas", "Reseñas"]
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // --- CABECERA DE PERFIL ---
                VStack(spacing: 16) {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 90, height: 90)
                            
                            if let avatarFile = authService.currentUser?.avatar,
                               let url = URL(string: "http://127.0.0.1:8080/avatars/\(avatarFile)") {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                    case .failure:
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 45, height: 45)
                                            .foregroundColor(.orange.opacity(0.5))
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "popcorn.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 45, height: 45)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Button {
                            showingEditSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .blue)
                                .font(.title)
                                .background(Circle().fill(.white).padding(2))
                        }
                        .offset(x: 5, y: 5)
                    }
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                    
                    VStack(spacing: 4) {
                        if let user = authService.currentUser {
                            HStack(spacing: 8) {
                                Text(user.username)
                                    .font(.title2)
                                    .bold()
                                
                                if user.isPrivate == true {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text(user.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Cargando usuario...")
                                .font(.title2).bold()
                        }
                    }
                    
                    // ESTADÍSTICAS MEJORADAS
                    HStack(spacing: 40) {
                        // Seguidores
                        Button(action: { showFollowers = true }) {
                            VStack(spacing: 4) {
                                Text("\(stats?.followersCount ?? 0)")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.primary)
                                Text("Seguidores")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Siguiendo
                        Button(action: { showFollowing = true }) {
                            VStack(spacing: 4) {
                                Text("\(stats?.followingCount ?? 0)")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.primary)
                                Text("Siguiendo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // Solicitudes (solo si hay pendientes)
                        if let pendingCount = stats?.pendingRequestsCount, pendingCount > 0 {
                            Button(action: { showingFollowRequests = true }) {
                                VStack(spacing: 4) {
                                    ZStack(alignment: .topTrailing) {
                                        Text("\(pendingCount)")
                                            .font(.title3)
                                            .bold()
                                            .foregroundColor(.primary)
                                        
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 10, y: -5)
                                    }
                                    Text("Solicitudes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 5)
                    
                    // Botón de Solicitudes más visible (si hay pendientes)
                    if let pendingCount = stats?.pendingRequestsCount, pendingCount > 0 {
                        Button(action: { showingFollowRequests = true }) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.clock")
                                Text("\(pendingCount) solicitud\(pendingCount > 1 ? "es" : "") pendiente\(pendingCount > 1 ? "s" : "")")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
                
                // --- SELECTOR DE LISTA ---
                Picker("Lista", selection: $selectedList) {
                    ForEach(listTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // --- CONTENIDO DE LA LISTA ---
                ScrollView {
                    if selectedList == "Favoritas" {
                        if favorites.movies.isEmpty {
                            emptyView(title: "Sin Favoritas", icon: "heart.slash")
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(favorites.movies) { movie in
                                    NavigationLink(value: movie) {
                                        MoviePosterCell(movie: movie)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                        }
                    } else {
                        let watchedMovies = serverMovies.filter { $0.isWatched }
                        
                        if watchedMovies.isEmpty {
                            emptyView(title: "Sin Reseñas", icon: "star.slash")
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(watchedMovies) { item in
                                    let movie = Movie(
                                        id: item.movieID,
                                        title: item.title,
                                        overview: "",
                                        posterPath: item.posterPath,
                                        backdropPath: nil,
                                        releaseDate: item.releaseDate,
                                        voteAverage: item.voteAverage ?? 0.0
                                    )
                                    
                                    NavigationLink(value: movie) {
                                        HStack(alignment: .top, spacing: 16) {
                                            AsyncImage(url: movie.posterURL) { img in
                                                img.resizable().aspectRatio(contentMode: .fill)
                                            } placeholder: { Color.gray.opacity(0.2) }
                                            .frame(width: 80, height: 120)
                                            .cornerRadius(8)
                                            .clipped()
                                            
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text(movie.title)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                if let rating = item.userRating {
                                                    HStack(spacing: 2) {
                                                        ForEach(1...5, id: \.self) { star in
                                                            Image(systemName: star <= rating ? "star.fill" : "star")
                                                                .font(.caption)
                                                                .foregroundColor(.yellow)
                                                        }
                                                    }
                                                }
                                                
                                                if let review = item.userReview, !review.isEmpty {
                                                    Text("\"\(review)\"")
                                                        .font(.subheadline)
                                                        .italic()
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(3)
                                                        .padding(.top, 2)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                    Divider().padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        authService.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditProfileView(currentUser: authService.currentUser)
                    .onDisappear {
                        // Recargar estadísticas al cerrar
                        Task { await loadStats() }
                    }
            }
            .sheet(isPresented: $showingFollowRequests) {
                FollowRequestsView()
                    .onDisappear {
                        // Recargar estadísticas al cerrar
                        Task { await loadStats() }
                    }
            }
            .sheet(isPresented: $showFollowers) {
                if let userID = authService.currentUser?.id {
                    FollowListView(userID: userID, type: .followers)
                }
            }
            .sheet(isPresented: $showFollowing) {
                if let userID = authService.currentUser?.id {
                    FollowListView(userID: userID, type: .following)
                }
            }
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationDestination(for: Cast.self) { actor in
                ActorDetailView(actorId: actor.id, actorName: actor.name)
            }
            .task {
                await syncUserData()
                await loadStats()
            }
            .refreshable {
                await syncUserData()
                await loadStats()
            }
        }
    }
    
    @ViewBuilder
    func emptyView(title: String, icon: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: icon,
            description: Text("Tu actividad aparecerá aquí.")
        )
        .padding(.top, 50)
    }
    
    func syncUserData() async {
        do {
            isLoading = true
            let serverData = try await MovieService.shared.fetchUserProfileMovies()
            
            await MainActor.run {
                self.serverMovies = serverData
                
                for item in serverData {
                    let movie = Movie(
                        id: item.movieID,
                        title: item.title,
                        overview: "",
                        posterPath: item.posterPath,
                        backdropPath: nil,
                        releaseDate: item.releaseDate ?? "",
                        voteAverage: item.voteAverage ?? 0.0
                    )
                    
                    if item.isFavorite {
                        if !favorites.isFavorite(movie.id) { favorites.toggleFavorite(movie: movie) }
                    } else if favorites.isFavorite(movie.id) {
                        favorites.toggleFavorite(movie: movie)
                    }
                    
                    if item.isWatched {
                        if !history.isSeen(movie.id) { history.toggleSeen(movie: movie) }
                    } else if history.isSeen(movie.id) {
                        history.toggleSeen(movie: movie)
                    }
                }
                isLoading = false
            }
        } catch {
            print("❌ Error sincronizando perfil: \(error)")
            isLoading = false
        }
    }
    
    func loadStats() async {
        do {
            let loadedStats = try await UserService.shared.getUserStats()
            await MainActor.run {
                self.stats = loadedStats
            }
        } catch {
            print("❌ Error cargando estadísticas: \(error)")
        }
    }
}
