import Vapor
import Fluent
import FluentMongoDriver
import Smtp

// Punto de entrada sin @main
do {
    var env = try Environment.detect()
    try LoggingSystem.bootstrap(from: &env)

    let app = Application(env)
    defer { app.shutdown() }

    // 1. Configuración de MongoDB
    let mongoHost = Environment.get("MONGO_HOST") ?? "localhost"
    let mongoPort = Environment.get("MONGO_PORT") ?? "27017"
    let mongoDatabase = Environment.get("MONGO_DATABASE") ?? "auramovies_db"
    
    let connectionString = "mongodb://\(mongoHost):\(mongoPort)/\(mongoDatabase)"
    
    print("🔗 Conectando a MongoDB: \(connectionString)")

    try app.databases.use(.mongo(
        connectionString: connectionString
    ), as: .mongo)

    // 2. Configuración SMTP (Gmail)
    let smtpEmail = Environment.get("SMTP_EMAIL") ?? ""
    let smtpPassword = Environment.get("SMTP_PASSWORD") ?? ""
    
    if smtpEmail.isEmpty || smtpPassword.isEmpty {
        print("⚠️  ADVERTENCIA: Credenciales SMTP no configuradas. El envío de emails no funcionará.")
    } else {
        print("📧 SMTP configurado para: \(smtpEmail)")
    }
    
    app.smtp.configuration.hostname = "smtp.gmail.com"
    app.smtp.configuration.port = 465
    app.smtp.configuration.secure = .ssl
    app.smtp.configuration.signInMethod = .credentials(
        username: smtpEmail,
        password: smtpPassword
    )

    // 3. Middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(CORSMiddleware(configuration: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin]
    )))
    
    app.middleware.use(ErrorMiddleware.default(environment: app.environment))

    // 4. Migraciones
    app.migrations.add(CreateUser())
    app.migrations.add(CreateToken())
    app.migrations.add(CreateUserMovie())
    app.migrations.add(AddAvatarToUser())
    app.migrations.add(AddLastUsernameChangeToUser())
    app.migrations.add(AddIsPrivateToUser())
    app.migrations.add(CreateUserFollow())

    do {
        try await app.autoMigrate()
        print("✅ Migraciones completadas")
    } catch {
        print("❌ Error en migraciones: \(error)")
        throw error
    }

    // 5. Rutas
    try app.register(collection: AuthController())
    try app.register(collection: MoviesInteractionController())
    try app.register(collection: UserSearchController())

    let port = Environment.get("PORT").flatMap(Int.init) ?? 8080
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = port

    print("🚀 Servidor iniciado en http://localhost:\(port)")
    print("📱 La app debe conectarse a: http://127.0.0.1:\(port)")
    print("")
    print("Endpoints disponibles:")
    print("  POST /auth/register")
    print("  POST /auth/verify")
    print("  POST /auth/login")
    print("  POST /auth/check-email")
    print("  POST /auth/apple-signin")
    print("  PUT  /auth/update-privacy")
    print("")
    print("  GET  /users/search?q=...")
    print("  GET  /users/:userID/profile")
    print("  POST /users/:userID/follow")
    print("  GET  /users/follow-requests")
    print("")
    
    try await app.execute()
    try await app.running?.onStop.get()
} catch {
    print("❌ Error fatal: \(error)")
    exit(1)
}
