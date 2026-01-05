// Backend/Sources/Backend/Models/Notification.swift
import Fluent
import Vapor

final class Notification: Model, Content {
    static let schema = "notifications"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "user_id")
    var user: User
    
    @Field(key: "type")
    var type: NotificationType
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "message")
    var message: String
    
    @Field(key: "is_read")
    var isRead: Bool
    
    @OptionalField(key: "related_user_id")
    var relatedUserID: UUID?
    
    @OptionalField(key: "related_username")
    var relatedUsername: String?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        userID: UUID,
        type: NotificationType,
        title: String,
        message: String,
        isRead: Bool = false,
        relatedUserID: UUID? = nil,
        relatedUsername: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.type = type
        self.title = title
        self.message = message
        self.isRead = isRead
        self.relatedUserID = relatedUserID
        self.relatedUsername = relatedUsername
    }
}

enum NotificationType: String, Codable {
    case newFollower = "new_follower"
    case followRequestAccepted = "follow_request_accepted"
    case newFollowRequest = "new_follow_request"
}

// MIGRACIÓN
struct CreateNotification: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("notifications")
            .id()
            .field("user_id", .uuid, .required, .references("users", "_id", onDelete: .cascade))
            .field("type", .string, .required)
            .field("title", .string, .required)
            .field("message", .string, .required)
            .field("is_read", .bool, .required)
            .field("related_user_id", .uuid)
            .field("related_username", .string)
            .field("created_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("notifications").delete()
    }
}
