import Fluent

struct AddIsPrivateToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("is_private", .bool, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("is_private")
            .update()
    }
}
