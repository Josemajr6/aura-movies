import Fluent
import Vapor

// Modelo para gestionar seguimientos entre usuarios
final class UserFollow: Model, Content {
    static let schema = "user_follows"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "follower_id")
    var follower: User  // Usuario que sigue

    @Parent(key: "following_id")
    var following: User  // Usuario seguido

    @Field(key: "status")
    var status: FollowStatus  // pending, accepted, rejected

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(followerID: UUID, followingID: UUID, status: FollowStatus = .pending) {
        self.$follower.id = followerID
        self.$following.id = followingID
        self.status = status
    }
}

enum FollowStatus: String, Codable {
    case pending   // Solicitud pendiente (para cuentas privadas)
    case accepted  // Solicitud aceptada
    case rejected  // Solicitud rechazada
}

// MIGRACIÓN
struct CreateUserFollow: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_follows")
            .id()
            .field("follower_id", .uuid, .required, .references("users", "_id", onDelete: .cascade))
            .field("following_id", .uuid, .required, .references("users", "_id", onDelete: .cascade))
            .field("status", .string, .required)
            .field("created_at", .datetime)
            .unique(on: "follower_id", "following_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_follows").delete()
    }
}
