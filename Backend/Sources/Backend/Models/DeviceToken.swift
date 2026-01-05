// Backend/Sources/Backend/Models/DeviceToken.swift
import Fluent
import Vapor

final class DeviceToken: Model, Content {
    static let schema = "device_tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "token")
    var token: String
    
    @Field(key: "platform")
    var platform: String // "iOS" o "Android"
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(userID: UUID, token: String, platform: String) {
        self.$user.id = userID
        self.token = token
        self.platform = platform
    }
}

// MIGRACIÓN
struct CreateDeviceToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("device_tokens")
            .id()
            .field("user_id", .uuid, .required, .references("users", "_id", onDelete: .cascade))
            .field("token", .string, .required)
            .field("platform", .string, .required)
            .field("updated_at", .datetime)
            .unique(on: "user_id", "token")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("device_tokens").delete()
    }
}

// MARK: - HELPER PARA ENVIAR PUSH REALES (APNs)
extension Application {
    func sendPushNotification(
        to userID: UUID,
        title: String,
        body: String,
        type: NotificationType
    ) async {
        do {
            // 1. Obtener tokens del usuario
            let tokens = try await DeviceToken.query(on: self.db)
                .filter(\.$user.$id == userID)
                .all()
            
            guard !tokens.isEmpty else {
                self.logger.info("👤 Usuario \(userID) sin tokens registrados")
                return
            }
            
            // 2. Enviar a cada token
            for deviceToken in tokens {
                if deviceToken.platform == "iOS" {
                    await sendAPNsPush(
                        token: deviceToken.token,
                        title: title,
                        body: body,
                        type: type
                    )
                }
                // Para Android usarías Firebase Cloud Messaging (FCM)
            }
        } catch {
            self.logger.error("❌ Error enviando push: \(error)")
        }
    }
    
    private func sendAPNsPush(
        token: String,
        title: String,
        body: String,
        type: NotificationType
    ) async {
        // 1. Añadir la librería APNSwift a Package.swift
        // 2. Configurar certificado .p8 de Apple
        // 3. Descomentar y configurar el código siguiente:
        
        /*
        let payload = APNSwiftPayload(
            alert: APNSwiftAlert(title: title, body: body),
            sound: .normal("default"),
            badge: 1,
            contentAvailable: true,
            customData: ["type": type.rawValue]
        )
        
        do {
            try await self.apns.client.sendAlertNotification(
                payload,
                deviceToken: token,
                expiration: .immediately,
                priority: .immediately,
                collapseIdentifier: nil,
                topic: "com.AuraMovies", // Tu Bundle ID
                logger: self.logger
            )
            self.logger.info("✅ Push enviado a token: \(token.prefix(10))...")
        } catch {
            self.logger.error("❌ Error enviando push a APNs: \(error)")
        }
        */
        
        self.logger.info("📤 Push simulado enviado a token: \(token.prefix(10))...")
    }
}
