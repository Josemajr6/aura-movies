import SwiftUI

@main
struct AuraMoviesApp: App {
    // Usamos @StateObject para escuchar los cambios de @Published en AuthService
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            // Router principal: Si está autenticado muestra la App, si no, el Login
            if authService.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        // Puedes añadir .animation(.default, value: authService.isAuthenticated) aquí si quieres suavizar el cambio
    }
}
