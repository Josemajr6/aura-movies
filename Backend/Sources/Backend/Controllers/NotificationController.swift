// Backend/Sources/Backend/Controllers/NotificationController.swift
import Fluent
import Vapor

struct NotificationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notifications = routes.grouped("notifications")
        let tokenProtected = notifications.grouped(Token.authenticator(), Token.guardMiddleware())
        
        tokenProtected.get(use: getNotifications)
        tokenProtected.put(":notificationID", "read", use: markAsRead)
        tokenProtected.put("read-all", use: markAllAsRead)
        tokenProtected.delete(":notificationID", use: deleteNotification)
        tokenProtected.get("unread-count", use: getUnreadCount)
    }
    
    // DTOs
    struct NotificationDTO: Content {
        let id: UUID
        let type: String
        let title: String
        let message: String
        let isRead: Bool
        let relatedUserID: UUID?
        let relatedUsername: String?
        let createdAt: Date
    }
    
    struct UnreadCountResponse: Content {
        let count: Int
    }
    
    // MARK: - Obtener Notificaciones
    func getNotifications(req: Request) async throws -> [NotificationDTO] {
        let user = try req.auth.require(User.self)
        
        let notifications = try await Notification.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .sort(\.$createdAt, .descending)
            .all()
        
        return notifications.map { notification in
            NotificationDTO(
                id: notification.id!,
                type: notification.type.rawValue,
                title: notification.title,
                message: notification.message,
                isRead: notification.isRead,
                relatedUserID: notification.relatedUserID,
                relatedUsername: notification.relatedUsername,
                createdAt: notification.createdAt ?? Date()
            )
        }
    }
    
    // MARK: - Marcar como Leída
    func markAsRead(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        
        guard let notificationID = req.parameters.get("notificationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let notification = try await Notification.find(notificationID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Verificar que es del usuario
        guard notification.$user.id == userID else {
            throw Abort(.forbidden)
        }
        
        notification.isRead = true
        try await notification.save(on: req.db)
        
        return .ok
    }
    
    // MARK: - Marcar Todas como Leídas
    func markAllAsRead(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        let notifications = try await Notification.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$isRead == false)
            .all()
        
        for notification in notifications {
            notification.isRead = true
            try await notification.save(on: req.db)
        }
        
        return .ok
    }
    
    // MARK: - Eliminar Notificación
    func deleteNotification(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let userID = try user.requireID()
        
        guard let notificationID = req.parameters.get("notificationID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let notification = try await Notification.find(notificationID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        guard notification.$user.id == userID else {
            throw Abort(.forbidden)
        }
        
        try await notification.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - Contador de No Leídas
    func getUnreadCount(req: Request) async throws -> UnreadCountResponse {
        let user = try req.auth.require(User.self)
        
        let count = try await Notification.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$isRead == false)
            .count()
        
        return UnreadCountResponse(count: count)
    }
}

// MARK: - Helper para Crear Notificaciones
extension Application {
    func createNotification(
        for userID: UUID,
        type: NotificationType,
        title: String,
        message: String,
        relatedUserID: UUID? = nil,
        relatedUsername: String? = nil
    ) async throws {
        let notification = Notification(
            userID: userID,
            type: type,
            title: title,
            message: message,
            relatedUserID: relatedUserID,
            relatedUsername: relatedUsername
        )
        
        try await notification.save(on: self.db)
        
        // Aquí podrías integrar servicios como Firebase Cloud Messaging
        // o Apple Push Notification service (APNs) para enviar push reales
        print("📬 Notificación creada para usuario: \(userID)")
    }
}
