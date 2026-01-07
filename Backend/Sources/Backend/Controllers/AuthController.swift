import Fluent
import Vapor
import Smtp

struct FlexibleUserAuthenticator: AsyncBasicAuthenticator {
    func authenticate(basic: BasicAuthorization, for request: Request) async throws {
        // El identificador puede ser username O email
        let identifier = basic.username
        let password = basic.password
        
        // 1. Intentar buscar por username
        var user = try await User.query(on: request.db)
            .filter(\.$username == identifier)
            .first()
        
        // 2. Si no existe, buscar por email
        if user == nil {
            user = try await User.query(on: request.db)
                .filter(\.$email == identifier)
                .first()
        }
        
        // 3. Verificar que existe y que la contraseña es correcta
        guard let foundUser = user,
              try Bcrypt.verify(password, created: foundUser.passwordHash) else {
            return
        }
        
        // 4. Autenticar
        request.auth.login(foundUser)
    }
}

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
            let auth = routes.grouped("auth")
            
            // 1. Rutas Públicas
            auth.post("register", use: register)
            auth.post("verify", use: verifyCode)
            auth.post("resend-code", use: resendCode)
            auth.post("check-email", use: checkEmail)
            auth.post("apple-signin", use: appleSignIn)
            auth.post("google-signin", use: googleSignIn)
            auth.post("forgot-password", use: forgotPassword)
            auth.post("reset-password", use: resetPassword)
            auth.get("search", use: searchUsers)
        
            // 2. Rutas protegidas por CONTRASEÑA (Solo Login)
            // User.authenticator() lee cabeceras Basic Auth (user:pass)
            let passwordProtected = auth.grouped(FlexibleUserAuthenticator())
            passwordProtected.post("login", use: login)
            
            // 3. Rutas protegidas por TOKEN (Perfil, Avatar, Cambiar Pass)
            // Token.authenticator() lee cabeceras Bearer Auth (Token)
            let tokenProtected = auth.grouped(Token.authenticator()).grouped(Token.guardMiddleware())
            
            tokenProtected.put("update-profile", use: updateProfile)
            tokenProtected.put("change-password", use: changePassword)
            tokenProtected.on(.POST, "upload-avatar", body: .collect(maxSize: "10mb"), use: uploadAvatar)
        
            tokenProtected.put("update-privacy", use: updatePrivacy)
        }
    // MARK: - DTOs
    struct RegisterRequest: Content, Validatable {
        var username: String
        var email: String
        var password: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("username", as: String.self, is: !.empty && .count(3...20))
            validations.add("email", as: String.self, is: .email)
            validations.add("password", as: String.self, is: .count(8...) && .characterSet(.alphanumerics + .init(charactersIn: "!@#$%^&*")))
        }
    }
    
    struct LoginResponse: Content {
        let token: String
        let user: UserDTO
    }

    struct UserDTO: Content {
        let id: UUID
        let username: String
        let email: String
        let avatar: String?
        let isPrivate: Bool?
    }
    
    // 👈 DTO AÑADIDO PARA SUBIR ARCHIVOS
    struct AvatarUploadRequest: Content {
        var avatar: File
    }
    
    struct VerifyRequest: Content {
        var email: String
        var code: String
    }
    
    struct CheckEmailRequest: Content {
        var email: String
    }
    
    struct ForgotPasswordRequest: Content {
        var email: String
    }
    
    struct ResetPasswordRequest: Content, Validatable {
        var email: String
        var code: String
        var newPassword: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("newPassword", as: String.self, is: .count(8...))
        }
    }
    
    struct AppleSignInRequest: Content {
        var appleUserID: String
        var email: String
        var username: String
    }
    
    struct GoogleSignInRequest: Content {
        var googleUserID: String
        var email: String
        var name: String
        var photoURL: String?
    }
    
    struct CheckEmailResponse: Content {
        let exists: Bool
        let message: String
    }
    
    struct ErrorResponse: Content {
        var error: Bool = true
        var reason: String
    }
    
    // DTO para actualizar datos básicos
    struct UpdateProfileRequest: Content, Validatable {
        var username: String
        var email: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("username", as: String.self, is: !.empty && .count(3...20))
            validations.add("email", as: String.self, is: .email)
        }
    }

    // DTO para cambiar contraseña
    struct ChangePasswordRequest: Content, Validatable {
        var oldPassword: String
        var newPassword: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("newPassword", as: String.self, is: .count(8...))
        }
    }
    
    struct SuccessResponse: Content {
        var success: Bool = true
        var message: String
    }
    
    // MARK: - Verificar si email existe
    func checkEmail(req: Request) async throws -> CheckEmailResponse {
        let input = try req.content.decode(CheckEmailRequest.self)
        
        let exists = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() != nil
        
        return CheckEmailResponse(
            exists: exists,
            message: exists ? "Este correo ya está registrado" : "Correo disponible"
        )
    }
    
    // MARK: - Registro
    func register(req: Request) async throws -> SuccessResponse {
        do {
            try RegisterRequest.validate(content: req)
        } catch {
            throw Abort(.badRequest, reason: "Validación fallida: \(error.localizedDescription)")
        }
        
        let input = try req.content.decode(RegisterRequest.self)
        
        guard input.email.contains("@") && input.email.contains(".") else {
            throw Abort(.badRequest, reason: "Formato de correo inválido")
        }
        
        guard input.password.count >= 8 else {
            throw Abort(.badRequest, reason: "La contraseña debe tener al menos 8 caracteres")
        }
        
        if try await User.query(on: req.db).filter(\.$username == input.username).first() != nil {
            throw Abort(.conflict, reason: "El nombre de usuario ya está registrado")
        }
        
        if let existingUser = try await User.query(on: req.db).filter(\.$email == input.email).first() {
            if existingUser.isVerified {
                throw Abort(.conflict, reason: "Este correo ya está registrado y verificado")
            } else {
                let newCode = String(Int.random(in: 100000...999999))
                existingUser.verificationCode = newCode
                try await existingUser.save(on: req.db)
                
                Task {
                    try? await sendEmail(to: input.email, code: newCode, subject: "Verifica tu cuenta", title: "Código de Verificación", app: req.application)
                }
                
                return SuccessResponse(message: "Se ha reenviado el código de verificación a tu correo")
            }
        }
        
        let passwordHash = try Bcrypt.hash(input.password)
        let verificationCode = String(Int.random(in: 100000...999999))
        
        let user = User(
            username: input.username,
            email: input.email,
            passwordHash: passwordHash,
            verificationCode: verificationCode
        )
        
        try await user.save(on: req.db)
        req.logger.info("✅ Usuario creado: \(input.username)")
        
        Task {
            do {
                try await sendEmail(to: input.email, code: verificationCode, subject: "Bienvenido a AuraMovies", title: "Código de Verificación", app: req.application)
                req.logger.info("📧 Email enviado a: \(input.email)")
            } catch {
                req.logger.error("❌ Error enviando email: \(error)")
            }
        }
        
        return SuccessResponse(message: "Registro exitoso. Revisa tu correo para el código de verificación.")
    }
    
    // MARK: - Verificación
    func verifyCode(req: Request) async throws -> LoginResponse {
        let input = try req.content.decode(VerifyRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() else {
            throw Abort(.notFound, reason: "Usuario no encontrado")
        }
        
        guard let storedCode = user.verificationCode else {
            throw Abort(.badRequest, reason: "No hay código de verificación pendiente")
        }
        
        guard storedCode == input.code else {
            throw Abort(.unauthorized, reason: "Código de verificación incorrecto")
        }
        
        // Marcar como verificado
        user.isVerified = true
        user.verificationCode = nil
        try await user.save(on: req.db)
        
        req.logger.info("✅ Usuario verificado: \(user.username)")
        
        // Crear token
        let token = try Token(value: UUID().uuidString, userID: user.requireID())
        try await token.save(on: req.db)
        
        // 🔥 DEVOLVER TOKEN + USUARIO COMPLETO (no un usuario temporal)
        return LoginResponse(
            token: token.value,
            user: UserDTO(
                id: try user.requireID(),
                username: user.username,  // ✅ El username real, no el email
                email: user.email,
                avatar: user.avatar,
                isPrivate: user.isPrivate
            )
        )
    }
    
    // MARK: - Reenviar código
    func resendCode(req: Request) async throws -> SuccessResponse {
        let input = try req.content.decode(CheckEmailRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() else {
            throw Abort(.notFound, reason: "Usuario no encontrado")
        }
        
        guard !user.isVerified else {
            throw Abort(.badRequest, reason: "Este usuario ya está verificado")
        }
        
        let newCode = String(Int.random(in: 100000...999999))
        user.verificationCode = newCode
        try await user.save(on: req.db)
        
        Task {
            try? await sendEmail(to: input.email, code: newCode, subject: "Reenvío de código", title: "Nuevo Código de Verificación", app: req.application)
        }
        
        return SuccessResponse(message: "Código reenviado")
    }
    
    // MARK: - Login
    func login(req: Request) async throws -> LoginResponse {
        let user = try req.auth.require(User.self)
        
        guard user.isVerified else {
            throw Abort(.forbidden, reason: "Debes verificar tu correo antes de iniciar sesión")
        }
        
        // Crear token
        let token = try Token(value: UUID().uuidString, userID: user.requireID())
        try await token.save(on: req.db)
        
        req.logger.info("✅ Login exitoso: \(user.username)")
        
        // Devolver Token + Datos del Usuario (INCLUIDO AVATAR E isPrivate)
        return LoginResponse(
            token: token.value,
            user: UserDTO(
                id: try user.requireID(),
                username: user.username,
                email: user.email,
                avatar: user.avatar,
                isPrivate: user.isPrivate
            )
        )
    }
    
    // MARK: - Apple Sign In
    func appleSignIn(req: Request) async throws -> Token {
        let input = try req.content.decode(AppleSignInRequest.self)
        
        var user: User?
        
        // 1. Prioridad: Buscar por appleUserID
        user = try await User.query(on: req.db)
            .filter(\.$appleUserID == input.appleUserID)
            .first()
        
        // 2. Si no existe y tenemos email, buscar por email
        if user == nil, !input.email.isEmpty {
            user = try await User.query(on: req.db)
                .filter(\.$email == input.email)
                .first()
            
            if let existingUser = user, existingUser.appleUserID == nil {
                existingUser.appleUserID = input.appleUserID
                try await existingUser.save(on: req.db)
            }
        }
        
        // 3. Si sigue sin existir, crear nuevo usuario
        if user == nil {
            let username = input.username.isEmpty ? "apple_\(input.appleUserID.prefix(8))" : input.username
            let email = input.email.isEmpty ? "\(input.appleUserID.prefix(8))@privaterelay.appleid.com" : input.email
            let passwordHash = try Bcrypt.hash(UUID().uuidString)
            
            let newUser = User(
                username: username,
                email: email,
                passwordHash: passwordHash,
                verificationCode: "", // CORREGIDO
                appleUserID: input.appleUserID
            )
            newUser.isVerified = true
            
            try await newUser.save(on: req.db)
            user = newUser
            req.logger.info("✅ Nuevo usuario Apple creado: \(newUser.username)")
        }
        
        guard let finalUser = user else {
            throw Abort(.internalServerError, reason: "Error al crear/obtener usuario")
        }
        
        let token = try Token(value: UUID().uuidString, userID: finalUser.requireID())
        try await token.save(on: req.db)
        
        return token
    }
    
    // MARK: - Google Sign In
    func googleSignIn(req: Request) async throws -> Token {
        let input = try req.content.decode(GoogleSignInRequest.self)
        
        var user: User?
        
        // 1. Prioridad: Buscar por googleUserID
        user = try await User.query(on: req.db)
            .filter(\.$googleUserID == input.googleUserID)
            .first()
        
        // 2. Fallback: Buscar por email
        if user == nil, !input.email.isEmpty {
            user = try await User.query(on: req.db)
                .filter(\.$email == input.email)
                .first()
            
            if let existingUser = user, existingUser.googleUserID == nil {
                existingUser.googleUserID = input.googleUserID
                try await existingUser.save(on: req.db)
            }
        }
        
        // 3. Crear nuevo usuario
        if user == nil {
            let usernameBase = input.name.lowercased()
                .replacingOccurrences(of: " ", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let finalUsername = usernameBase.isEmpty ? "google_\(input.googleUserID.prefix(8))" : usernameBase
            let passwordHash = try Bcrypt.hash(UUID().uuidString)
            
            let newUser = User(
                username: finalUsername,
                email: input.email,
                passwordHash: passwordHash,
                verificationCode: "", // CORREGIDO
                googleUserID: input.googleUserID
            )
            newUser.isVerified = true
            
            try await newUser.save(on: req.db)
            user = newUser
            req.logger.info("✅ Nuevo usuario Google creado: \(newUser.username)")
        }
        
        guard let finalUser = user else {
            throw Abort(.internalServerError, reason: "Error al crear/obtener usuario")
        }
        
        let token = try Token(value: UUID().uuidString, userID: finalUser.requireID())
        try await token.save(on: req.db)
        
        return token
    }
    
    // MARK: - Olvidé Contraseña (SOLICITAR CÓDIGO) - CORREGIDO
    func forgotPassword(req: Request) async throws -> SuccessResponse {
        let input = try req.content.decode(ForgotPasswordRequest.self)
        
        // 1. Buscar usuario
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() else {
            // AHORA SÍ: Lanzamos error para que la App iOS sepa que no existe
            throw Abort(.notFound, reason: "El correo no está registrado en AuraMovies.")
        }
        
        // 2. Generar Código 6 dígitos
        let resetCode = String(Int.random(in: 100000...999999))
        user.verificationCode = resetCode
        try await user.save(on: req.db)
        
        // 3. Enviar Email (Usando tu función helper con HTML)
        Task {
            do {
                try await sendEmail(
                    to: input.email,
                    code: resetCode,
                    subject: "Recuperación de Contraseña - AuraMovies",
                    title: "Recupera tu Contraseña",
                    app: req.application,
                    messageText: "Usa el siguiente código en la app para crear una nueva contraseña:"
                )
                req.logger.info("📧 Email de restablecimiento enviado a: \(input.email)")
            } catch {
                req.logger.error("❌ Error enviando email de restablecimiento: \(error)")
            }
        }
        
        return SuccessResponse(message: "Código enviado correctamente.")
    }
    
    // MARK: - Restablecer Contraseña (CAMBIARLA)
    func resetPassword(req: Request) async throws -> SuccessResponse {
        do {
            try ResetPasswordRequest.validate(content: req)
        } catch {
            throw Abort(.badRequest, reason: "La contraseña debe tener al menos 8 caracteres.")
        }
        
        let input = try req.content.decode(ResetPasswordRequest.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == input.email)
            .first() else {
            throw Abort(.notFound, reason: "Usuario no encontrado")
        }
        
        // Verificar que el código coincida
        guard let storedCode = user.verificationCode, storedCode == input.code else {
            throw Abort(.unauthorized, reason: "El código es incorrecto o ha expirado.")
        }
        
        // Actualizar contraseña
        user.passwordHash = try Bcrypt.hash(input.newPassword)
        user.verificationCode = nil // Borramos el código para que no se pueda reusar
        try await user.save(on: req.db)
        
        req.logger.info("✅ Contraseña restablecida para: \(user.username)")
        
        return SuccessResponse(message: "Tu contraseña ha sido cambiada correctamente. Ya puedes iniciar sesión.")
    }
    
    // MARK: - Helper Email (CON HTML)
    private func sendEmail(to email: String, code: String, subject: String, title: String, app: Application, messageText: String = "Tu código es:") async throws {
        let smtpEmail = Environment.get("SMTP_EMAIL") ?? ""
        
        guard !smtpEmail.isEmpty else {
            app.logger.warning("⚠️  SMTP no configurado, no se puede enviar email")
            return
        }
        
        let emailObj = try Email(
            from: EmailAddress(address: smtpEmail, name: "AuraMovies"),
            to: [EmailAddress(address: email)],
            subject: subject,
            body: """
            <html>
            <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 40px; background-color: #f5f5f5;">
                <div style="max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; padding: 40px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
                    <h1 style="color: #007AFF; margin-bottom: 20px;">🍿 AuraMovies</h1>
                    <h2 style="color: #333; margin-bottom: 30px;">\(title)</h2>
                    <div style="background: #f8f9fa; border-radius: 12px; padding: 30px; margin: 30px 0;">
                        <p style="color: #666; margin-bottom: 15px; font-size: 16px;">\(messageText)</p>
                        <h1 style="color: #007AFF; font-size: 48px; letter-spacing: 8px; margin: 0; font-family: 'Courier New', monospace;">\(code)</h1>
                    </div>
                    <p style="color: #999; font-size: 14px; margin-top: 30px;">Este código expira pronto.</p>
                    <p style="color: #999; font-size: 12px; margin-top: 20px;">Si no solicitaste esto, protege tu cuenta.</p>
                </div>
            </body>
            </html>
            """,
            isBodyHtml: true
        )
        
        try await app.smtp.send(emailObj)
    }
    
    // MARK: - Actualizar Perfil
    func updateProfile(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        
        do { try UpdateProfileRequest.validate(content: req) }
        catch { throw Abort(.badRequest, reason: "Datos inválidos: \(error.localizedDescription)") }
        
        let input = try req.content.decode(UpdateProfileRequest.self)
        
        if input.email != user.email {
            let emailExists = try await User.query(on: req.db)
                .filter(\.$email == input.email)
                .filter(\.$id != user.requireID())
                .first() != nil
            if emailExists {
                throw Abort(.conflict, reason: "Ese correo ya está en uso por otra cuenta.")
            }
            user.email = input.email
        }
        
        if input.username != user.username {
            let usernameExists = try await User.query(on: req.db)
                .filter(\.$username == input.username)
                .first() != nil
            
            if usernameExists {
                throw Abort(.conflict, reason: "El nombre de usuario '\(input.username)' ya está cogido.")
            }
            
            if let lastChange = user.lastUsernameChangeDate {
                let limitDate = lastChange.addingTimeInterval(1209600)
                
                if Date() < limitDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    let dateString = formatter.string(from: limitDate)
                    
                    throw Abort(.forbidden, reason: "No puedes cambiar el nombre hasta el \(dateString) (Límite de 14 días).")
                }
            }
            
            user.username = input.username
            user.lastUsernameChangeDate = Date()
        }
        
        try await user.save(on: req.db)
        
        req.logger.info("✅ Perfil actualizado: \(user.username)")
        
        return UserDTO(
            id: try user.requireID(),
            username: user.username,
            email: user.email,
            avatar: user.avatar,
            isPrivate: user.isPrivate
        )
    }


    // MARK: - Cambiar Contraseña
    func changePassword(req: Request) async throws -> SuccessResponse {
        let user = try req.auth.require(User.self)
        
        do { try ChangePasswordRequest.validate(content: req) }
        catch { throw Abort(.badRequest, reason: "La nueva contraseña debe tener al menos 8 caracteres.") }
        
        let input = try req.content.decode(ChangePasswordRequest.self)
        
        // 1. Verificar la contraseña antigua
        guard try Bcrypt.verify(input.oldPassword, created: user.passwordHash) else {
            throw Abort(.unauthorized, reason: "La contraseña actual es incorrecta.")
        }
        
        // 2. Hashear y guardar la nueva contraseña
        user.passwordHash = try Bcrypt.hash(input.newPassword)
        try await user.save(on: req.db)
        
        req.logger.info("🔐 Contraseña cambiada para: \(user.username)")
        
        return SuccessResponse(message: "Contraseña actualizada correctamente.")
    }
    
    // MARK: - Subir Avatar (Lógica Nueva)
    func uploadAvatar(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        
        // 1. Decodificar la imagen del body Multipart
        let input = try req.content.decode(AvatarUploadRequest.self)
        
        // 2. Validar que sea imagen (básico)
        guard let contentType = input.avatar.contentType,
              contentType.type == "image" else {
            throw Abort(.badRequest, reason: "El archivo debe ser una imagen.")
        }
        
        // 3. Generar nombre único (UUID.extension)
        let fileExtension = input.avatar.extension ?? "jpg"
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let publicPath = req.application.directory.publicDirectory + "avatars/"
        
        // 4. Guardar archivo en la carpeta Public/avatars/
        // Nota: Asegúrate de que la carpeta existe.
        try await req.fileio.writeFile(input.avatar.data, at: publicPath + filename)
        
        // 5. Borrar avatar antiguo para limpiar disco (Opcional)
        if let oldAvatar = user.avatar {
            let oldPath = publicPath + oldAvatar
            // Ignoramos error si no existe el viejo
            try? FileManager.default.removeItem(atPath: oldPath)
        }
        
        // 6. Actualizar usuario en DB
        user.avatar = filename
        try await user.save(on: req.db)
        
        req.logger.info("📸 Avatar actualizado para: \(user.username)")
        
        return UserDTO(
            id: try user.requireID(),
            username: user.username,
            email: user.email,
            avatar: filename,
            isPrivate: user.isPrivate
        )

    }
    
    // MARK: - Buscar Usuarios (CORREGIDO: Búsqueda flexible)
        func searchUsers(req: Request) async throws -> [UserDTO] {
            // Obtenemos el texto de búsqueda
            guard let query = try? req.query.get(String.self, at: "query"), !query.isEmpty else {
                return []
            }
            
            // 1. Traemos TODOS los usuarios (Para una app pequeña/mediana esto es lo más seguro y rápido)
            let allUsers = try await User.query(on: req.db).all()
            
            // 2. Filtramos AQUÍ en Swift (Case Insensitive y Parcial)
            // Esto asegura que "aaron" encuentre a "Aaron", y "jose" encuentre a "Josema"
            let filteredUsers = allUsers.filter { user in
                user.username.localizedCaseInsensitiveContains(query)
            }
            
            // 3. Devolvemos los primeros 20 y convertimos a DTO
            return try filteredUsers.prefix(20).map { user in
                UserDTO(
                    id: try user.requireID(),
                    username: user.username,
                    email: user.email,
                    avatar: user.avatar,
                    isPrivate: false
                )
            }
        }
    
    // MARK: - Actualizar Privacidad
    func updatePrivacy(req: Request) async throws -> UserDTO {
        let user = try req.auth.require(User.self)
        
        struct UpdatePrivacyRequest: Content {
            var isPrivate: Bool
        }
        
        let input = try req.content.decode(UpdatePrivacyRequest.self)
        
        user.isPrivate = input.isPrivate
        try await user.save(on: req.db)
        
        req.logger.info("🔒 Privacidad actualizada para: \(user.username) - Privado: \(input.isPrivate)")
        
        return UserDTO(
            id: try user.requireID(),
            username: user.username,
            email: user.email,
            avatar: user.avatar,
            isPrivate: input.isPrivate
        )
    }
    
}


