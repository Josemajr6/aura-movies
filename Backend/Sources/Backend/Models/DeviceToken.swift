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

// Backend/Sources/Backend/Controllers/PushNotificationController.swift
import Vapor
import Fluent

struct PushNotificationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let push = routes.grouped("users")
        let tokenProtected = push.grouped(Token.authenticator(), Token.guardMiddleware())
        
        tokenProtected.post("device-token", use: registerDeviceToken)
        tokenProtected.delete("device-token", use: removeDeviceToken)
    }
    
    struct DeviceTokenRequest: Content {
        let deviceToken: String
        let platform: String
    }
    
    // MARK: - Registrar Token
    func registerDeviceToken(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let input = try req.content.decode(DeviceTokenRequest.self)
        
        // Buscar si ya existe
        if let existing = try await DeviceToken.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$token == input.deviceToken)
            .first() {
            
            existing.platform = input.platform
            try await existing.save(on: req.db)
        } else {
            let newToken = DeviceToken(
                userID: userID,
                token: input.deviceToken,
                platform: input.platform
            )
            try await newToken.save(on: req.db)
        }
        
        req.logger.info("📱 Token registrado: \(input.deviceToken.prefix(10))... para usuario: \(userID)")
        return .ok
    }
    
    // MARK: - Eliminar Token
    func removeDeviceToken(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        let input = try req.content.decode(DeviceTokenRequest.self)
        
        if let token = try await DeviceToken.query(on: req.db)
            .filter(\.$user.$id == userID)
            .filter(\.$token == input.deviceToken)
            .first() {
            try await token.delete(on: req.db)
            req.logger.info("🗑️ Token eliminado: \(input.deviceToken.prefix(10))...")
        }
        
        return .noContent
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
        // NOTA: Para enviar push reales necesitas:
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
        
        // En desarrollo, solo logueamos
        self.logger.info("📤 Push simulado enviado a token: \(token.prefix(10))...")
    }
}

// MARK: - ACTUALIZAR createNotification para enviar push automáticamente
extension Application {
    func createNotification(
        for userID: UUID,
        type: NotificationType,
        title: String,
        message: String,
        relatedUserID: UUID? = nil,
        relatedUsername: String? = nil
    ) async throws {
        // 1. Guardar en DB
        let notification = Notification(
            userID: userID,
            type: type,
            title: title,
            message: message,
            relatedUserID: relatedUserID,
            relatedUsername: relatedUsername
        )
        
        try await notification.save(on: self.db)
        
        // 2. Enviar Push Real
        await sendPushNotification(
            to: userID,
            title: title,
            body: message,
            type: type
        )
        
        self.logger.info("📬 Notificación creada y push enviado para: \(userID)")
    }
}
