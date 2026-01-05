import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var authService = AuthService.shared
    
    // MARK: - Estados del Formulario
    @State private var isRegistering = false
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    
    // MARK: - Estados de UI
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Navegación
    @State private var navigateToVerification = false
    @State private var navigateToResetPassword = false
    
    // MARK: - Estados para Reset Password
    @State private var showingForgotPasswordAlert = false
    @State private var forgotPasswordEmail = ""
    @State private var resetMessage = ""
    @State private var showingResetMessageAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // MARK: - Header (Logo)
                        VStack(spacing: 20) {
                            Image("appiconauramovies")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                            
                            VStack(spacing: 8) {
                                Text(isRegistering ? "Crear Cuenta" : "¡Hola de nuevo!")
                                    .font(.title2.bold())
                                    .foregroundColor(.primary)
                                
                                Text(isRegistering ? "Rellena los datos" : "Inicia sesión para continuar")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 40)
                        
                        // MARK: - Formulario
                        VStack(spacing: 20) {
                            
                            if isRegistering {
                                // Registro: Usuario y Email separados
                                CustomTextField(icon: "person", placeholder: "Usuario", text: $username)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                
                                CustomTextField(icon: "envelope", placeholder: "Correo electrónico", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                // Login: Usuario O Email (campo unificado)
                                CustomTextField(
                                    icon: "person",
                                    placeholder: "Usuario o Email",
                                    text: $username
                                )
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            }
                            
                            // Contraseña
                            CustomPasswordField(
                                placeholder: "Contraseña",
                                text: $password,
                                isVisible: $showPassword
                            )
                            
                            if isRegistering {
                                CustomPasswordField(
                                    placeholder: "Repetir contraseña",
                                    text: $confirmPassword,
                                    isVisible: $showPassword
                                )
                            }
                            
                            // Botón Olvidé contraseña (Solo en Login)
                            if !isRegistering {
                                HStack {
                                    Spacer()
                                    Button("¿Has olvidado la contraseña?") {
                                        forgotPasswordEmail = ""
                                        showingForgotPasswordAlert = true
                                    }
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                }
                            }
                            
                            // Mensaje de Error
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 5)
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Botón Principal
                        Button(action: handleAuth) {
                            ZStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isRegistering ? "Registrarse" : "Iniciar Sesión")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || !isFormValid)
                        .padding(.horizontal)
                        
                        // MARK: - Divisor
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(Color(.systemGray5))
                            Text("o continúa con").font(.caption).foregroundColor(.secondary)
                            Rectangle().frame(height: 1).foregroundColor(Color(.systemGray5))
                        }
                        .padding(.vertical, 10)
                        
                        // MARK: - Botón Apple
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: handleAppleSignIn
                        )
                        .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                        .frame(height: 50)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // MARK: - Footer
                        HStack {
                            Text(isRegistering ? "¿Ya tienes cuenta?" : "¿No tienes cuenta?")
                                .foregroundColor(.secondary)
                            
                            Button(isRegistering ? "Inicia sesión" : "Regístrate") {
                                withAnimation {
                                    isRegistering.toggle()
                                    errorMessage = nil
                                    password = ""
                                    confirmPassword = ""
                                }
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        }
                        .font(.footnote)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToVerification) {
                VerificationView(email: email)
            }
            .navigationDestination(isPresented: $navigateToResetPassword) {
                ResetPasswordView(email: forgotPasswordEmail)
            }
            .alert("Recuperar contraseña", isPresented: $showingForgotPasswordAlert) {
                TextField("Correo electrónico", text: $forgotPasswordEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                Button("Cancelar", role: .cancel) { }
                Button("Enviar") { requestPasswordReset() }
            } message: {
                Text("Introduce tu correo asociado a la cuenta.")
            }
            .alert("Estado del envío", isPresented: $showingResetMessageAlert) {
                Button("OK", role: .cancel) {
                    if resetMessage.contains("enviado") {
                        navigateToResetPassword = true
                    }
                }
            } message: {
                Text(resetMessage)
            }
        }
    }
    
    // MARK: - Validaciones
    var isFormValid: Bool {
        if isRegistering {
            return !username.isEmpty &&
                   username.count >= 3 &&
                   isValidEmail(email) &&
                   password.count >= 8 &&
                   password == confirmPassword
        } else {
            return !username.isEmpty && !password.isEmpty
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    // MARK: - Handlers
    func handleAuth() {
        errorMessage = nil
        UIApplication.shared.endEditing()
        if isRegistering { handleRegister() } else { handleLogin() }
    }
    
    func handleRegister() {
        isLoading = true
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let success = try await authService.register(
                    username: cleanUsername,
                    email: cleanEmail,
                    password: password
                )
                await MainActor.run {
                    isLoading = false
                    if success {
                        navigateToVerification = true
                    } else {
                        errorMessage = "Error en el registro."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    let msg = error.localizedDescription
                    if msg.contains("409") || msg.contains("conflict") {
                        errorMessage = "El usuario o correo ya existen."
                    } else {
                        errorMessage = "Error: \(msg)"
                    }
                }
            }
        }
    }
    
    func handleLogin() {
        isLoading = true
        let cleanInput = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            do {
                let success = try await authService.login(
                    username: cleanInput,
                    password: cleanPassword
                )
                await MainActor.run {
                    isLoading = false
                    if !success {
                        errorMessage = "Usuario o contraseña incorrectos."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Usuario o contraseña incorrectos."
                }
            }
        }
    }
    
    func requestPasswordReset() {
        let cleanEmail = forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard isValidEmail(cleanEmail) else {
            resetMessage = "El formato del correo no es válido."
            showingResetMessageAlert = true
            return
        }
        
        Task {
            do {
                _ = try await authService.requestPasswordReset(email: cleanEmail)
                await MainActor.run {
                    resetMessage = "✅ Se ha enviado un código de recuperación a tu correo."
                    showingResetMessageAlert = true
                }
            } catch {
                await MainActor.run {
                    let errorStr = error.localizedDescription.lowercased()
                    if errorStr.contains("404") || errorStr.contains("not found") || errorStr.contains("no existe") {
                        resetMessage = "⚠️ Este correo no está registrado en nuestra base de datos."
                    } else {
                        resetMessage = "❌ Error al conectar. Inténtalo de nuevo."
                    }
                    showingResetMessageAlert = true
                }
            }
        }
    }
    
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    do {
                        let success = try await authService.appleSignIn(
                            userID: appleIDCredential.user,
                            email: appleIDCredential.email,
                            fullName: appleIDCredential.fullName
                        )
                        await MainActor.run {
                            if !success {
                                errorMessage = "Fallo login con Apple"
                            }
                        }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        case .failure: break
        }
    }
}

// MARK: - Utilidades UI
struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            TextField(placeholder, text: $text)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CustomPasswordField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
            } else {
                SecureField(placeholder, text: $text)
            }
            
            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
