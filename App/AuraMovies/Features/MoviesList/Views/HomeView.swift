import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var notificationManager = NotificationManager.shared
    @State private var showNotifications = false
    
    // Estado para contar solicitudes pendientes
    @State private var pendingRequestsCount = 0
    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNotifications = true
                    } label: {
                        // 🔔 BADGE COMPLETAMENTE SEPARADO
                        let totalBadge = notificationManager.unreadCount + pendingRequestsCount
                        
                        ZStack {
                            // Icono de campana
                            Image(systemName: "bell.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                                .frame(width: 24, height: 24)
                            
                            // Badge posicionado fuera
                            if totalBadge > 0 {
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("\(totalBadge)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(4)
                                            .background(
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(minWidth: 18, minHeight: 18)
                                            )
                                    }
                                    Spacer()
                                }
                                .frame(width: 40, height: 40)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            // NAVEGACIÓN (Rutas)
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationDestination(for: Cast.self) { actor in
                ActorDetailView(actorId: actor.id, actorName: actor.name)
            }
            .task {
                await viewModel.loadAllSections()
                await loadPendingRequests()
            }
            .refreshable {
                await viewModel.loadAllSections()
                await notificationManager.checkForNewNotifications()
                await loadPendingRequests()
            }
        }
    }
    
    // Cargar solicitudes pendientes
    private func loadPendingRequests() async {
        do {
            let stats = try await UserService.shared.getUserStats()
            await MainActor.run {
                pendingRequestsCount = stats.pendingRequestsCount
            }
        } catch {
            print("❌ Error cargando estadísticas: \(error)")
        }
    }
}

// Subvista reutilizable
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

#Preview {
    HomeView()
}
