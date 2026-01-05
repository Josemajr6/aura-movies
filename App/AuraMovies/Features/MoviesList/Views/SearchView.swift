import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtro de tipo de búsqueda
                Picker("Filtro", selection: $viewModel.scope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(scope.rawValue).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Resultados
                ScrollView {
                    switch viewModel.state {
                    case .empty:
                        ContentUnavailableView(
                            "Explorar",
                            systemImage: "magnifyingglass",
                            description: Text("Busca \(viewModel.scope.rawValue.lowercased())...")
                        )
                        .padding(.top, 50)
                        
                    case .loading:
                        ProgressView()
                            .controlSize(.large)
                            .padding(.top, 50)
                        
                    case .movies(let movies):
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(movies) { movie in
                                NavigationLink(value: movie) {
                                    MoviePosterCell(movie: movie)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        
                    case .people(let people):
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(people) { person in
                                NavigationLink(value: Cast(
                                    id: person.id,
                                    name: person.name,
                                    character: "",
                                    profilePath: person.profilePath
                                )) {
                                    VStack {
                                        if let path = person.profilePath,
                                           let url = URL(string: "https://image.tmdb.org/t/p/w500\(path)") {
                                            AsyncImage(url: url) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .frame(width: 90, height: 90)
                                                .foregroundColor(.gray)
                                        }
                                        
                                        Text(person.name)
                                            .font(.caption)
                                            .bold()
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        
                    case .users(let users):
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(users, id: \.id) { user in
                                NavigationLink(value: user.id) {
                                    UserSearchCard(user: user)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        
                    case .error(let msg):
                        ContentUnavailableView(
                            "Error",
                            systemImage: "exclamationmark.triangle",
                            description: Text(msg)
                        )
                        .padding()
                    }
                }
            }
            .navigationTitle("Buscar")
            .searchable(text: $viewModel.searchText, prompt: "Escribe para buscar...")
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationDestination(for: Cast.self) { actor in
                ActorDetailView(actorId: actor.id, actorName: actor.name)
            }
            .navigationDestination(for: UUID.self) { userID in
                UserProfileView(userID: userID)
            }
        }
    }
}

// MARK: - Tarjeta de Usuario en Búsqueda
struct UserSearchCard: View {
    let user: UserDTO
    
    var body: some View {
        HStack(spacing: 15) {
            // Avatar
            if let avatar = user.avatar,
               let url = URL(string: "http://127.0.0.1:8080/avatars/\(avatar)") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    case .failure, .empty:
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                    )
            }
            
            // Info del usuario
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(user.username)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if user.isPrivate == true {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(user.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    SearchView()
}
