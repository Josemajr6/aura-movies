import SwiftUI

struct UserProfileView: View {
    let userID: UUID
    
    @State private var profile: UserProfileResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isFollowing = false
    
    @State private var showFollowers = false
    @State private var showFollowing = false
    @State private var selectedTab = 0 // 0: Favoritas, 1: Reseñas
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .controlSize(.large)
                    .padding(.top, 100)
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                .padding(.top, 50)
            } else if let profile = profile {
                VStack(spacing: 20) {
                    // CABECERA
                    VStack(spacing: 16) {
                        // Avatar
                        if let avatar = profile.avatar,
                           let url = URL(string: "http://127.0.0.1:8080/avatars/\(avatar)") {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.3))
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                        } else {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.largeTitle)
                                        .foregroundColor(.orange)
                                )
                        }
                        
                        // Nombre y badge privado
                        HStack(spacing: 8) {
                            Text(profile.username)
                                .font(.title2)
                                .bold()
                            
                            if profile.isPrivate {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Estadísticas
                        HStack(spacing: 40) {
                            Button(action: { showFollowers = true }) {
                                VStack {
                                    Text("\(profile.followersCount)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.primary)
                                    Text("Seguidores")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { showFollowing = true }) {
                                VStack {
                                    Text("\(profile.followingCount)")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.primary)
                                    Text("Siguiendo")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Botón de Seguir
                        followButton
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .background(Color(uiColor: .systemGroupedBackground))
                    
                    // CONTENIDO DEL PERFIL
                    if profile.canViewProfile {
                        // Selector de pestaña
                        Picker("", selection: $selectedTab) {
                            Text("Favoritas").tag(0)
                            Text("Reseñas").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Lista de películas
                        moviesList
                    } else {
                        // Perfil Privado
                        VStack(spacing: 20) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("Este perfil es privado")
                                .font(.title3)
                                .bold()
                            
                            Text("Sigue a \(profile.username) para ver sus películas")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 80)
                        .padding(.horizontal, 40)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFollowers) {
            FollowListView(userID: userID, type: .followers)
        }
        .sheet(isPresented: $showFollowing) {
            FollowListView(userID: userID, type: .following)
        }
        .task {
            await loadProfile()
        }
        .refreshable {
            await loadProfile()
        }
    }
    
    // MARK: - Botón de Seguir
    private var followButton: some View {
        Group {
            if let status = profile?.followStatus {
                Button(action: handleFollowAction) {
                    HStack {
                        if isFollowing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            switch status {
                            case "following":
                                Image(systemName: "checkmark")
                                Text("Siguiendo")
                            case "pending":
                                Image(systemName: "xmark.circle")
                                Text("Cancelar Solicitud")
                            default:
                                Image(systemName: "person.badge.plus")
                                Text(profile?.isPrivate == true ? "Solicitar Seguir" : "Seguir")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        status == "following" ? Color.gray.opacity(0.2) :
                        status == "pending" ? Color.red.opacity(0.1) :
                        Color.blue
                    )
                    .foregroundColor(
                        status == "following" ? .primary :
                        status == "pending" ? .red :
                        .white
                    )
                    .cornerRadius(12)
                }
                .disabled(isFollowing)
            }
        }
    }
    
    // MARK: - Lista de Películas
    @ViewBuilder
    private var moviesList: some View {
        if selectedTab == 0 {
            // FAVORITAS (Sin reseña, solo poster)
            if let movies = profile?.favoriteMovies, !movies.isEmpty {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(movies) { movieDTO in
                        let movie = Movie(
                            id: movieDTO.movieID,
                            title: movieDTO.title,
                            overview: "",
                            posterPath: movieDTO.posterPath,
                            backdropPath: nil,
                            releaseDate: nil,
                            voteAverage: 0.0
                        )
                        
                        NavigationLink(value: movie) {
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: movieDTO.posterURL) { img in
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: { Color.gray.opacity(0.3) }
                                .frame(width: 150, height: 225)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                                
                                Text(movieDTO.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(2)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: 150, alignment: .leading)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "Sin Favoritas",
                    systemImage: "heart.slash",
                    description: Text("\(profile?.username ?? "Este usuario") no tiene favoritas.")
                )
                .padding(.top, 40)
            }
        } else {
            // RESEÑAS (Con estrellas y texto completo)
            if let movies = profile?.watchedMovies, !movies.isEmpty {
                LazyVStack(spacing: 16) {
                    ForEach(movies) { movieDTO in
                        let movie = Movie(
                            id: movieDTO.movieID,
                            title: movieDTO.title,
                            overview: "",
                            posterPath: movieDTO.posterPath,
                            backdropPath: nil,
                            releaseDate: nil,
                            voteAverage: 0.0
                        )
                        
                        NavigationLink(value: movie) {
                            HStack(alignment: .top, spacing: 16) {
                                // Poster
                                AsyncImage(url: movieDTO.posterURL) { img in
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: { Color.gray.opacity(0.2) }
                                .frame(width: 80, height: 120)
                                .cornerRadius(8)
                                .clipped()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(movieDTO.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    // ESTRELLAS (si tiene valoración)
                                    if let rating = movieDTO.userRating {
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { star in
                                                Image(systemName: star <= rating ? "star.fill" : "star")
                                                    .font(.caption)
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                    }
                                    
                                    // RESEÑA (si tiene texto)
                                    if let review = movieDTO.userReview, !review.isEmpty {
                                        Text("\"\(review)\"")
                                            .font(.subheadline)
                                            .italic()
                                            .foregroundColor(.secondary)
                                            .lineLimit(4)
                                            .padding(.top, 4)
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
            } else {
                ContentUnavailableView(
                    "Sin Reseñas",
                    systemImage: "star.slash",
                    description: Text("\(profile?.username ?? "Este usuario") no ha escrito reseñas.")
                )
                .padding(.top, 40)
            }
        }
    }
    
    // MARK: - Funciones
    private func loadProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedProfile = try await UserService.shared.getUserProfile(userID: userID)
            await MainActor.run {
                self.profile = loadedProfile
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "No se pudo cargar el perfil"
                self.isLoading = false
            }
        }
    }
    
    private func handleFollowAction() {
        guard let profile = profile else { return }
        isFollowing = true
        
        Task {
            do {
                if profile.followStatus == "following" || profile.followStatus == "pending" {
                    // Dejar de seguir o cancelar solicitud
                    try await UserService.shared.unfollowUser(userID: userID)
                } else {
                    // Seguir usuario
                    try await UserService.shared.followUser(userID: userID)
                }
                
                // Recargar perfil
                await loadProfile()
            } catch {
                print("Error al seguir/dejar de seguir: \(error)")
            }
            
            await MainActor.run {
                isFollowing = false
            }
        }
    }
}

// MARK: - Vista de Lista de Seguidores/Siguiendo
enum FollowListType {
    case followers, following
}

struct FollowListView: View {
    let userID: UUID
    let type: FollowListType
    
    @Environment(\.dismiss) var dismiss
    @State private var users: [UserSearchResult] = []
    @State private var isLoading = true
    @State private var processingUsers: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if users.isEmpty {
                    ContentUnavailableView(
                        type == .followers ? "Sin Seguidores" : "Sin Seguidos",
                        systemImage: "person.2.slash"
                    )
                } else {
                    List(users) { user in
                        HStack {
                            NavigationLink(value: user.id) {
                                UserSearchCell(user: user)
                            }
                            
                            // Botón de Eliminar
                            if !processingUsers.contains(user.id) {
                                Button {
                                    handleRemove(user)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            } else {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(type == .followers ? "Seguidores" : "Siguiendo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .navigationDestination(for: UUID.self) { userID in
                UserProfileView(userID: userID)
            }
            .task {
                await loadUsers()
            }
            .refreshable {
                await loadUsers()
            }
        }
    }
    
    private func loadUsers() async {
        isLoading = true
        
        do {
            let loadedUsers = type == .followers
                ? try await UserService.shared.getFollowers(userID: userID)
                : try await UserService.shared.getFollowing(userID: userID)
            
            await MainActor.run {
                self.users = loadedUsers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func handleRemove(_ user: UserSearchResult) {
        processingUsers.insert(user.id)
        
        Task {
            do {
                if type == .followers {
                    // Eliminar seguidor (quitar a alguien que me sigue)
                    try await UserService.shared.removeFollower(userID: user.id)
                } else {
                    // Dejar de seguir (yo dejo de seguir a alguien)
                    try await UserService.shared.unfollowUser(userID: user.id)
                }
                
                await MainActor.run {
                    users.removeAll { $0.id == user.id }
                    processingUsers.remove(user.id)
                }
            } catch {
                print("❌ Error eliminando: \(error)")
                await MainActor.run {
                    processingUsers.remove(user.id)
                }
            }
        }
    }
}

// MARK: - Celda de Usuario
struct UserSearchCell: View {
    let user: UserSearchResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarURL = user.avatarURL {
                AsyncImage(url: avatarURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.orange)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if user.isPrivate {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Label("\(user.followersCount)", systemImage: "person.2.fill")
                    Label("\(user.followingCount)", systemImage: "person.fill.checkmark")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Estado de seguimiento
            if let status = user.followStatus {
                FollowStatusBadge(status: status)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct FollowStatusBadge: View {
    let status: String
    
    var body: some View {
        Group {
            switch status {
            case "following":
                Label("Siguiendo", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            case "pending":
                Label("Pendiente", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    UserProfileView(userID: UUID())
}
