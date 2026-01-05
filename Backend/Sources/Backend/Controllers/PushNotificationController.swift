// Backend/Sources/Backend/Controllers/PushNotificationController.swift
import Vapor
import Fluent

// MARK: - Extension para crear notificaciones con push
extension Application {
    func createNotificationWithPush(
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
