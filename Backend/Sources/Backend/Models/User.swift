import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(custom: "_id")
    var id: UUID?

    @Field(key: "username")
    var username: String
    
    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "verification_code")
    var verificationCode: String?
    
    @Field(key: "is_verified")
    var isVerified: Bool
    
    // 👇 CAMPOS DE LOGIN SOCIAL
    @OptionalField(key: "apple_user_id")
    var appleUserID: String?
    
    @OptionalField(key: "google_user_id")
    var googleUserID: String?

    @OptionalField(key: "avatar")
    var avatar: String?
    
    @OptionalField(key: "lastUsernameChangeDate")
    var lastUsernameChangeDate: Date?
    
    // 👇 NUEVO CAMPO: Cuenta Privada
    @OptionalField(key: "is_private")
    var isPrivate: Bool?
    
    init() { }

    init(id: UUID? = nil, username: String, email: String, passwordHash: String, verificationCode: String, appleUserID: String? = nil, googleUserID: String? = nil) {
        self.id = id
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.verificationCode = verificationCode
        self.isVerified = false
        self.appleUserID = appleUserID
        self.googleUserID = googleUserID
        self.isPrivate = false // Por defecto, las cuentas son públicas
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: !.empty)
    }
}
