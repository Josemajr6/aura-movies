import SwiftUI
import UserNotifications

@main
struct AuraMoviesApp: App {
    // Usamos @StateObject para escuchar los cambios de @Published en AuthService
    @StateObject private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
    }
    
}
