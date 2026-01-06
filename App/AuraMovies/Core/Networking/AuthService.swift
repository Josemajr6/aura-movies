import SwiftUI
import Foundation
import Combine
import AuthenticationServices

// MARK: - Modelos de Datos (DTOs)
struct UserDTO: Codable {
    let id: UUID
    let username: String
    let email: String
    let avatar: String?
    let isPrivate: Bool?
}

struct LoginResponse: Decodable {
    let token: String
    let user: UserDTO
}

struct TokenResponse: Decodable {
    let value: String
}

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserDTO?
    
    // Configuración de URL (Para simulador usa 127.0.0.1, para dispositivo físico tu IP local)
    private let baseURL = "http://127.0.0.1:8080/auth"
    private var isDebugMode = true
    
    // Propiedad pública para acceder al token
    var token: String? {
        UserDefaults.standard.string(forKey: "AuthToken")
    }
    
    private init() {
        // Restaurar sesión al iniciar la app
        if let token = UserDefaults.standard.string(forKey: "AuthToken"), !token.isEmpty {
            // 1. Intentar recuperar el objeto usuario completo
            if let savedUserData = UserDefaults.standard.data(forKey: "SavedUser"),
               let savedUser = try? JSONDecoder().decode(UserDTO.self, from: savedUserData) {
                self.currentUser = savedUser
                self.isAuthenticated = true
                print("✅ Sesión restaurada para: \(savedUser.username)")
            }
            // 2. Fallback para versiones anteriores (Solo nombre guardado)
            else if let legacyUsername = UserDefaults.standard.string(forKey: "Username") {
                // CORREGIDO: Se añade avatar: nil
                self.currentUser = UserDTO(id: UUID(), username: legacyUsername, email: "", avatar: nil, isPrivate: false)
                self.isAuthenticated = true
                print("⚠️ Sesión legacy restaurada para: \(legacyUsername)")
            }
        }
    }
    
    // MARK: - Verificar si email existe
    func checkEmailExists(email: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/check-email") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body: [String: String] = ["email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return false }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let exists = json["exists"] as? Bool {
                return exists
            }
            return false
        } catch {
            print("❌ Error verificando email: \(error.localizedDescription)")
            throw AuthError.connectionError
        }
    }
    
    // MARK: - Registro
    func register(username: String, email: String, password: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/register") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let body = ["username": username, "email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Respuesta inválida") }
            
            if isDebugMode { print("📡 Register Status: \(http.statusCode)") }
            
            if http.statusCode == 200 {
                return true
            } else {
                throw parseError(data: data)
            }
        } catch let error as AuthError { throw error }
        catch { throw AuthError.connectionError }
    }
    
    // MARK: - Verificación de código
    func verifyCode(email: String, code: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/verify") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body = ["email": email, "code": code]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Respuesta inválida") }
            
            if http.statusCode == 200 {
                if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                    // CORREGIDO: Se añade avatar: nil
                    let tempUser = UserDTO(id: UUID(), username: email, email: email, avatar: nil, isPrivate: false)
                    self.saveSession(token: tokenResponse.value, user: tempUser)
                    return true
                }
            } else {
                throw parseError(data: data)
            }
            return false
        } catch let error as AuthError { throw error }
        catch {
            print("❌ Error verificando código: \(error.localizedDescription)")
            throw AuthError.connectionError
        }
    }
    
    // MARK: - Reenviar código
    func resendCode(email: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/resend-code") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
    
    
    // MARK: - Login
    func login(username: String, password: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/login") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10
        
        // 🆕 USAMOS EL INPUT TAL CUAL (puede ser username o email)
        let loginString = "\(username):\(password)"
        guard let loginData = loginString.data(using: .utf8) else { throw AuthError.invalidCredentials }
        let base64LoginString = loginData.base64EncodedString()
        
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Respuesta inválida") }
            
            if isDebugMode { print("📡 Login Status: \(http.statusCode)") }
            
            if http.statusCode == 200 {
                // INTENTO 1: Decodificar LoginResponse (Token + Usuario)
                if let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data) {
                    self.saveSession(token: loginResponse.token, user: loginResponse.user)
                    return true
                }
                // INTENTO 2: Fallback a TokenResponse (Legacy)
                else if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                    let tempUser = UserDTO(id: UUID(), username: username, email: "", avatar: nil, isPrivate: false)
                    self.saveSession(token: tokenResponse.value, user: tempUser)
                    return true
                }
            } else if http.statusCode == 401 {
                throw AuthError.invalidCredentials
            } else if http.statusCode == 403 {
                throw AuthError.notVerified
            } else {
                throw parseError(data: data)
            }
            return false
        } catch let error as AuthError { throw error }
        catch {
            print("❌ Error de login: \(error.localizedDescription)")
            throw AuthError.connectionError
        }
    }
    
    // MARK: - Apple Sign In
    func appleSignIn(userID: String, email: String?, fullName: PersonNameComponents?) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/apple-signin") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        
        let username: String
        if let fullName = fullName, let givenName = fullName.givenName {
            username = givenName.lowercased().replacingOccurrences(of: " ", with: "")
        } else if let email = email {
            username = email.components(separatedBy: "@").first ?? "user"
        } else {
            username = "appleuser"
        }
        
        let body: [String: Any] = [
            "appleUserID": userID,
            "email": email ?? "",
            "username": username
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Respuesta inválida") }
            
            if http.statusCode == 200 {
                if let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                    // CORREGIDO: Se añade avatar: nil
                    let tempUser = UserDTO(id: UUID(), username: username, email: email ?? "", avatar: nil, isPrivate: false)
                    self.saveSession(token: tokenResponse.value, user: tempUser)
                    return true
                }
            } else {
                throw parseError(data: data)
            }
            return false
        } catch let error as AuthError { throw error }
        catch {
            print("❌ Error en Apple Sign-In: \(error.localizedDescription)")
            throw AuthError.connectionError
        }
    }
    
    // MARK: - Solicitar Restablecimiento de Contraseña
    func requestPasswordReset(email: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/forgot-password") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body = ["email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Respuesta inválida") }
            
            if http.statusCode == 200 { return true }
            else { throw parseError(data: data) }
        } catch let error as AuthError { throw error }
        catch {
            print("❌ Error solicitando reset: \(error.localizedDescription)")
            throw AuthError.connectionError
        }
    }
    
    // MARK: - Restablecer Contraseña (Confirmar)
    func resetPassword(email: String, code: String, newPassword: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/reset-password") else { throw AuthError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let body = ["email": email, "code": code, "newPassword": newPassword]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Respuesta inválida") }
            
            if http.statusCode == 200 {
                return true
            } else { throw parseError(data: data) }
        } catch let error as AuthError { throw error }
        catch {
            print("❌ Error restableciendo contraseña: \(error.localizedDescription)")
            throw AuthError.connectionError
        }
    }
    
    // MARK: - Logout
    func logout() {
        UserDefaults.standard.removeObject(forKey: "AuthToken")
        UserDefaults.standard.removeObject(forKey: "SavedUser")
        UserDefaults.standard.removeObject(forKey: "Username")
        
        self.isAuthenticated = false
        self.currentUser = nil
        print("👋 Sesión cerrada")
    }
    
    // MARK: - Actualizar Perfil (MEJORADO PARA ERRORES 403 y 409)
    func updateProfile(username: String, email: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/update-profile") else { throw AuthError.invalidURL }
        guard let token = self.token else { throw AuthError.invalidCredentials }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["username": username, "email": email]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Error") }
            
            if http.statusCode == 200 {
                // Éxito: Guardamos usuario actualizado
                if let updatedUser = try? JSONDecoder().decode(UserDTO.self, from: data) {
                    await MainActor.run {
                        self.saveSession(token: token, user: updatedUser)
                    }
                    print("✅ Perfil local actualizado")
                    return true
                }
            } else if http.statusCode == 401 {
                // Token caducado
                throw AuthError.serverError("Sesión caducada. Por favor, cierra sesión y vuelve a entrar.")
            } else {
                // Aquí capturamos:
                // 409: Nombre o correo en uso
                // 403: Límite de 14 días
                throw parseError(data: data)
            }
            return false
        } catch let error as AuthError { throw error }
        catch { throw AuthError.connectionError }
    }
    
    // MARK: - Cambiar Contraseña
    func changePassword(old: String, new: String) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/change-password") else { throw AuthError.invalidURL }
        guard let token = self.token else { throw AuthError.invalidCredentials }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body = ["oldPassword": old, "newPassword": new]
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Error") }
            
            if http.statusCode == 200 { return true }
            else if http.statusCode == 401 { throw AuthError.serverError("La contraseña actual no es correcta o la sesión ha caducado.") }
            else { throw parseError(data: data) }
        } catch let error as AuthError { throw error }
        catch { throw AuthError.connectionError }
    }
    
    // MARK: - Subir Avatar
    func uploadAvatar(image: UIImage) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/upload-avatar") else { throw AuthError.invalidURL }
        guard let token = self.token else { throw AuthError.invalidCredentials }
        
        // 1. Convertir imagen a Data (JPEG comprimido)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return false }
        
        // 2. Crear Request Multipart manual
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = "avatar.jpg"
        let mimeType = "image/jpeg"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AuthError.serverError("Error") }
            
            if http.statusCode == 200 {
                if let updatedUser = try? JSONDecoder().decode(UserDTO.self, from: data) {
                    await MainActor.run {
                        self.saveSession(token: token, user: updatedUser)
                    }
                    return true
                }
            } else if http.statusCode == 401 {
                throw AuthError.serverError("Sesión caducada. Por favor, cierra sesión y vuelve a entrar.")
            }
            throw parseError(data: data)
        } catch {
            throw error
        }
    }
    
    // MARK: - Helpers Privados
    
    private func saveSession(token: String, user: UserDTO) {
        // 1. Guardar Token
        UserDefaults.standard.set(token, forKey: "AuthToken")
        
        // 2. Guardar Objeto Usuario Completo (Codificado en JSON)
        if let encodedUser = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encodedUser, forKey: "SavedUser")
        }
        
        // 3. Guardar nombre en formato legacy (por compatibilidad)
        UserDefaults.standard.set(user.username, forKey: "Username")
        
        // 4. Actualizar Estado en la App
        self.isAuthenticated = true
        self.currentUser = user
    }
    
    // Helper antiguo por compatibilidad
    private func saveToken(_ token: String, username: String) {
        let tempUser = UserDTO(id: UUID(), username: username, email: "", avatar: nil, isPrivate: false)
        saveSession(token: token, user: tempUser)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "AuthToken")
    }
    
    // Helper para parsear errores del backend
    private func parseError(data: Data) -> AuthError {
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            return .serverError(errorResponse.reason)
        } else if let errorString = String(data: data, encoding: .utf8) {
            return .serverError(errorString)
        }
        return .unknown
    }
}

// MARK: - Error Types
enum AuthError: LocalizedError {
    case invalidURL
    case invalidCredentials
    case notVerified
    case serverError(String)
    case connectionError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL inválida"
        case .invalidCredentials:
            return "Usuario o contraseña incorrectos"
        case .notVerified:
            return "Debes verificar tu correo primero"
        case .serverError(let message):
            return message
        case .connectionError:
            return "Error de conexión. Verifica que el servidor esté corriendo en Xcode."
        case .unknown:
            return "Error desconocido"
        }
    }
}

// MARK: - Response Models
struct ErrorResponse: Codable {
    let error: Bool?
    let reason: String
}

struct SuccessResponse: Codable {
    let success: Bool?
    let message: String
}
