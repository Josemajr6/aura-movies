import SwiftUI

struct VerificationView: View {
    let email: String
    @Environment(\.dismiss) var dismiss
    
    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccessAlert = false
    
    // Estado para reenvío
    @State private var resendMessage = ""
    @State private var showingResendAlert = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Icono
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                // Textos Header
                VStack(spacing: 12) {
                    Text("Verifica tu cuenta")
                        .font(.title2.bold())
                    
                    Text("Introduce el código de 6 dígitos que hemos enviado a:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(email)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                
                // Input Código
                VStack(spacing: 20) {
                    TextField("000000", text: $code)
                        .keyboardType(.numberPad)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .frame(maxWidth: 280)
                        .onChange(of: code) { _, newValue in
                            // Limitar a 6 caracteres
                            if newValue.count > 6 {
                                code = String(newValue.prefix(6))
                            }
                        }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Botón Verificar
                Button(action: verify) {
                    ZStack {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Verificar")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(code.count == 6 ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(code.count < 6 || isLoading)
                .padding(.horizontal, 40)
                
                // Botón Reenviar
                Button("No he recibido el código") {
                    resendCode()
                }
                .font(.footnote)
                .foregroundColor(.blue)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        // Alerta de éxito al verificar
        .alert("¡Verificado!", isPresented: $showSuccessAlert) {
            Button("Continuar") {
                // Al verificar, cerramos esta pantalla y el usuario ya podrá hacer login
                // Opcionalmente podrías hacer login automático aquí si guardaste pass
                dismiss()
            }
        } message: {
            Text("Tu correo ha sido confirmado correctamente. Ya puedes iniciar sesión.")
        }
        // Alerta de reenvío
        .alert("Reenviar código", isPresented: $showingResendAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(resendMessage)
        }
    }
    
    func verify() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let success = try await AuthService.shared.verifyCode(email: email, code: code)
                await MainActor.run {
                    isLoading = false
                    if success {
                        showSuccessAlert = true
                    } else {
                        errorMessage = "El código es incorrecto. Inténtalo de nuevo."
                        code = ""
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Error de conexión: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func resendCode() {
        Task {
            do {
                let sent = try await AuthService.shared.resendCode(email: email)
                await MainActor.run {
                    resendMessage = sent ? "Código reenviado. Revisa tu bandeja de entrada." : "No se pudo reenviar el código."
                    showingResendAlert = true
                }
            } catch {
                await MainActor.run {
                    resendMessage = "Error al conectar con el servidor."
                    showingResendAlert = true
                }
            }
        }
    }
}

#Preview {
    VerificationView(email: "test@ejemplo.com")
}
