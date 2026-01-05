import SwiftUI

struct UserProfileView: View {
    let userID: UUID
    
    @State private var profile: UserProfileResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isFollowing = false
    
    @State private var showFollowers = false
    @State private var showFollowing = false
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView()
                    .padding(.top, 100)
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "Error",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
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
                        // Mostrar películas
                        VStack(alignment: .leading, spacing: 20) {
                            if let favorites = profile.favoriteMovies, !favorites.isEmpty {
                                movieSection(title: "Películas Favoritas", movies: favorites)
                            }
                            
                            if let watched = profile.watchedMovies, !watched.isEmpty {
                                movieSection(title: "Películas Vistas", movies: watched)
                            }
                            
                            if (profile.favoriteMovies?.isEmpty ?? true) && (profile.watchedMovies?.isEmpty ?? true) {
                                ContentUnavailableView(
                                    "Sin Películas",
                                    systemImage: "film",
                                    description: Text("Este usuario aún no ha guardado películas")
                                )
                                .padding(.top, 50)
                            }
                        }
                        .padding()
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
    }
    
    private var followButton: some View {
        Group {
            if let status = profile?.followStatus {
                Button(action: handleFollowAction) {
                    HStack {
                        switch status {
                        case "following":
                            Image(systemName: "checkmark")
                            Text("Siguiendo")
                        case "pending":
                            Image(systemName: "clock")
                            Text("Solicitud Enviada")
                        default:
                            Image(systemName: "person.badge.plus")
                            Text(profile?.isPrivate == true ? "Solicitar Seguir" : "Seguir")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(status == "following" ? Color.gray.opacity(0.2) : Color.blue)
                    .foregroundColor(status == "following" ? .primary : .white)
                    .cornerRadius(12)
                }
                .disabled(isFollowing)
            }
        }
    }
    
    private func movieSection(title: String, movies: [UserMovieBasic]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .bold()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        VStack(alignment: .leading) {
                            AsyncImage(url: movie.posterURL) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 120, height: 180)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                            
                            Text(movie.title)
                                .font(.caption)
                                .lineLimit(2)
                                .frame(width: 120)
                        }
                    }
                }
            }
        }
    }
    
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
                if profile.followStatus == "following" {
                    try await UserService.shared.unfollowUser(userID: userID)
                } else {
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

enum FollowListType {
    case followers, following
}

struct FollowListView: View {
    let userID: UUID
    let type: FollowListType
    
    @Environment(\.dismiss) var dismiss
    @State private var users: [UserSearchResult] = []
    @State private var isLoading = true
    
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
                        NavigationLink(value: user.id) {
                            UserSearchCell(user: user)
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
}

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
