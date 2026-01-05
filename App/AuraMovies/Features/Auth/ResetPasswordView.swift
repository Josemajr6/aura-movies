import SwiftUI

struct ResetPasswordView: View {
    let email: String
    @Environment(\.dismiss) var dismiss
    
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isVisible = false
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Icono Header
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                VStack(spacing: 10) {
                    Text("Restablecer Contraseña")
                        .font(.title2.bold())
                    
                    Text("Introduce el código que enviamos a\n\(email)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 20) {
                    // Campo Código
                    TextField("Código de 6 dígitos", text: $code)
                        .keyboardType(.numberPad)
                        .font(.title3.monospaced())
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                        .onChange(of: code) { _, newValue in
                            if newValue.count > 6 { code = String(newValue.prefix(6)) }
                        }
                    
                    // Nueva Contraseña
                    CustomPasswordField(placeholder: "Nueva contraseña (mín. 8)", text: $newPassword, isVisible: $isVisible)
                    
                    // Confirmar
                    CustomPasswordField(placeholder: "Confirmar nueva contraseña", text: $confirmPassword, isVisible: $isVisible)
                }
                .padding(.horizontal)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: resetPassword) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Cambiar Contraseña")
                            .bold()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!isValid || isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .alert("¡Éxito!", isPresented: $showSuccessAlert) {
            Button("Ir a Iniciar Sesión") {
                dismiss() // Cierra esta vista y vuelve al Login
            }
        } message: {
            Text("Tu contraseña se ha cambiado correctamente.")
        }
    }
    
    var isValid: Bool {
        return code.count == 6 && newPassword.count >= 8 && newPassword == confirmPassword
    }
    
    func resetPassword() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await AuthService.shared.resetPassword(
                    email: email,
                    code: code,
                    newPassword: newPassword
                )
                
                await MainActor.run {
                    isLoading = false
                    if success {
                        showSuccessAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
