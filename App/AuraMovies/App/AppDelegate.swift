// App/AuraMovies/App/AppDelegate.swift
import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        // Configurar el centro de notificaciones
        UNUserNotificationCenter.current().delegate = self
        
        // Solicitar permisos
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ Permisos de notificaciones concedidos")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("❌ Error solicitando permisos: \(error)")
            }
        }
        
        return true
    }
    
    // MARK: - Registro de Token APNs
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Device Token: \(token)")
        
        // Enviar token al backend
        Task {
            await sendTokenToBackend(token: token)
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Error registrando notificaciones: \(error)")
    }
    
    // MARK: - Manejo de Notificaciones
    
    // Cuando se recibe con la app en primer plano
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mostrar banner incluso si la app está abierta
        completionHandler([.banner, .sound, .badge])
        
        // Actualizar NotificationManager
        Task {
            await NotificationManager.shared.checkForNewNotifications()
        }
    }
    
    // Cuando el usuario toca la notificación
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Navegar según el tipo
        if let type = userInfo["type"] as? String {
            handleNotificationTap(type: type, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    // MARK: - Helpers
    
    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any]) {
        // Abrir pantalla de notificaciones
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenNotifications"),
            object: nil
        )
        
        // Actualizar lista de notificaciones
        Task {
            await NotificationManager.shared.checkForNewNotifications()
        }
    }
    
    private func sendTokenToBackend(token: String) async {
        guard let url = URL(string: "http://127.0.0.1:8080/users/device-token") else {
            print("❌ URL inválida")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Añadir token de autenticación si existe
        if let authToken = AuthService.shared.token {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("⚠️ No hay token de autenticación, el device token no se puede enviar")
            return
        }
        
        let body: [String: String] = [
            "deviceToken": token,
            "platform": "iOS"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Device token enviado al backend")
            } else {
                print("⚠️ Error enviando token: respuesta inválida")
            }
        } catch {
            print("❌ Error enviando token: \(error)")
        }
    }
}
