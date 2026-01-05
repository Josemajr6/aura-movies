import SwiftUI
import Observation
import UserNotifications

// MARK: - Modelo de Notificación
struct AppNotification: Identifiable, Codable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let relatedUserID: UUID?
    let relatedUsername: String?
    let relatedUserAvatar: String?
    
    init(
        id: UUID = UUID(),
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        isRead: Bool = false,
        relatedUserID: UUID? = nil,
        relatedUsername: String? = nil,
        relatedUserAvatar: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.isRead = isRead
        self.relatedUserID = relatedUserID
        self.relatedUsername = relatedUsername
        self.relatedUserAvatar = relatedUserAvatar
    }
}

enum NotificationType: String, Codable {
    case newFollower = "new_follower"
    case followRequestAccepted = "follow_request_accepted"
    case newFollowRequest = "new_follow_request"
    case movieRecommendation = "movie_recommendation"
    case trendingMovie = "trending_movie"
}

// MARK: - Gestor de Notificaciones
@Observable
class NotificationManager {
    static let shared = NotificationManager()
    
    var notifications: [AppNotification] = []
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    private let saveKey = "AppNotifications"
    private var checkTimer: Timer?
    
    private init() {
        loadNotifications()
        requestNotificationPermission()
        startPeriodicCheck()
    }
    
    // MARK: - Persistencia
    func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([AppNotification].self, from: data) {
            notifications = decoded.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    // MARK: - Añadir Notificaciones
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
        save()
        
        // Enviar notificación push local
        sendLocalNotification(notification)
    }
    
    func markAsRead(_ id: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isRead = true
            save()
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        save()
    }
    
    func deleteNotification(_ id: UUID) {
        notifications.removeAll { $0.id == id }
        save()
    }
    
    func clearAll() {
        notifications.removeAll()
        save()
    }
    
    // MARK: - Verificación Periódica (Cada 30 segundos)
    func startPeriodicCheck() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.checkForNewNotifications()
            }
        }
    }
    
    func stopPeriodicCheck() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Verificar Nuevas Notificaciones del Servidor
    func checkForNewNotifications() async {
        do {
            // 1. Verificar solicitudes de seguimiento
            let stats = try await UserService.shared.getUserStats()
            
            // Si hay solicitudes pendientes y no tenemos notificación de ellas
            if stats.pendingRequestsCount > 0 {
                let existingRequests = notifications.filter { $0.type == .newFollowRequest && !$0.isRead }
                
                if existingRequests.count < stats.pendingRequestsCount {
                    addNotification(AppNotification(
                        type: .newFollowRequest,
                        title: "Nueva solicitud de seguimiento",
                        message: "Tienes \(stats.pendingRequestsCount) solicitud(es) pendiente(s)"
                    ))
                }
            }
            
            // 2. Generar notificaciones aleatorias ocasionalmente (1 de cada 10 veces)
            if Int.random(in: 1...10) == 1 {
                await generateRandomNotification()
            }
            
        } catch {
            print("❌ Error verificando notificaciones: \(error)")
        }
    }
    
    // MARK: - Notificaciones Aleatorias
    func generateRandomNotification() async {
        let randomType = Int.random(in: 1...2)
        
        switch randomType {
        case 1:
            // Película trending
            addNotification(AppNotification(
                type: .trendingMovie,
                title: "🔥 Película en tendencia",
                message: "¡No te pierdas las películas más populares de la semana!"
            ))
        case 2:
            // Recomendación personalizada
            addNotification(AppNotification(
                type: .movieRecommendation,
                title: "🎬 Recomendación para ti",
                message: "Basándonos en tus favoritas, tenemos nuevas películas que te pueden gustar"
            ))
        default:
            break
        }
    }
    
    // MARK: - Permisos de Notificaciones Push
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permisos de notificaciones concedidos")
            } else if let error = error {
                print("❌ Error solicitando permisos: \(error)")
            }
        }
    }
    
    // MARK: - Enviar Notificación Local
    func sendLocalNotification(_ notification: AppNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.message
        content.sound = .default
        content.badge = NSNumber(value: unreadCount)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error enviando notificación local: \(error)")
            }
        }
    }
    
    // MARK: - Helpers
    func getIcon(for type: NotificationType) -> String {
        switch type {
        case .newFollower:
            return "person.fill.badge.plus"
        case .followRequestAccepted:
            return "checkmark.circle.fill"
        case .newFollowRequest:
            return "person.crop.circle.badge.clock"
        case .movieRecommendation:
            return "sparkles"
        case .trendingMovie:
            return "flame.fill"
        }
    }
    
    func getColor(for type: NotificationType) -> Color {
        switch type {
        case .newFollower:
            return .blue
        case .followRequestAccepted:
            return .green
        case .newFollowRequest:
            return .orange
        case .movieRecommendation:
            return .purple
        case .trendingMovie:
            return .red
        }
    }
    
    // MARK: - Listener de Notificaciones Remotas
    func setupRemoteNotificationListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenNotifications"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Señal para abrir la pantalla de notificaciones
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowNotificationsSheet"),
                object: nil
            )
            
            // Recargar notificaciones del servidor
            Task { [weak self] in
                await self?.checkForNewNotifications()
            }
        }
    }
}
