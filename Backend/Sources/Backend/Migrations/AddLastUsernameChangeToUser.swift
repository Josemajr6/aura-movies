import Fluent

struct AddLastUsernameChangeToUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .field("lastUsernameChangeDate", .datetime)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users")
            .deleteField("lastUsernameChangeDate")
            .update()
    }
}
