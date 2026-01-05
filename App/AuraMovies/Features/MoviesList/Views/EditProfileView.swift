import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
    
    // Campos
    @State private var username: String
    @State private var email: String
    @State private var isPrivate: Bool
    
    // Foto
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    
    // Contraseña
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var showingForgotPasswordAlert = false
    
    // Feedback
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    init(currentUser: UserDTO?) {
        _username = State(initialValue: currentUser?.username ?? "")
        _email = State(initialValue: currentUser?.email ?? "")
        _isPrivate = State(initialValue: currentUser?.isPrivate ?? false)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. FOTO
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 15) {
                            if let selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 100, height: 100).clipShape(Circle())
                            } else if let avatar = authService.currentUser?.avatar,
                                      let url = URL(string: "http://127.0.0.1:8080/avatars/\(avatar)") {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Image(systemName: "person.circle.fill").foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 100, height: 100).clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable().foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                            }
                            
                            PhotosPicker(selection: $selectedItem, matching: .images) {
                                Text("Cambiar foto").font(.footnote).bold().foregroundColor(.blue)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // 2. INFORMACIÓN
                Section(header: Text("Perfil")) {
                    TextField("Nombre de usuario", text: $username)
                        .textInputAutocapitalization(.never)
                }
                
                // 2.5 PRIVACIDAD
                Section {
                    Toggle(isOn: $isPrivate) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cuenta Privada")
                                .font(.body)
                            Text("Solo tus seguidores podrán ver tus películas")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Privacidad")
                } footer: {
                    Text("Si activas esta opción, otros usuarios tendrán que enviarte una solicitud para seguirte y ver tu perfil.")
                        .font(.caption)
                }
                
                // 3. SEGURIDAD
                Section(header: Text("Cambiar Contraseña")) {
                    SecureField("Contraseña actual", text: $oldPassword)
                    SecureField("Nueva contraseña", text: $newPassword)
                    SecureField("Repetir nueva contraseña", text: $confirmNewPassword)
                    
                    Button("¿Olvidaste tu contraseña?") {
                        showingForgotPasswordAlert = true
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
                
                // 4. ESTADO Y BOTÓN
                Section {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let success = successMessage {
                        Text(success).foregroundColor(.green).font(.callout)
                    }
                    
                    Button(action: saveChanges) {
                        if isLoading {
                            HStack { Spacer(); ProgressView(); Spacer() }
                        } else {
                            Text("Guardar Cambios")
                                .frame(maxWidth: .infinity)
                                .bold()
                                .foregroundColor(canSave ? .blue : .gray)
                        }
                    }
                    .disabled(!canSave || isLoading)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                    }
                }
            }
            .alert("Recuperar contraseña", isPresented: $showingForgotPasswordAlert) {
                Button("Cancelar", role: .cancel) { }
                Button("Enviar") {
                    Task { try? await authService.requestPasswordReset(email: email) }
                }
            } message: {
                Text("Se enviará un correo a tu dirección registrada.")
            }
        }
    }
    
    var canSave: Bool {
        let usernameChanged = username != authService.currentUser?.username
        let photoChanged = selectedImage != nil
        let privacyChanged = isPrivate != (authService.currentUser?.isPrivate ?? false)
        let passwordFilled = !oldPassword.isEmpty && !newPassword.isEmpty && newPassword == confirmNewPassword
        
        return (usernameChanged || photoChanged || passwordFilled || privacyChanged) && !username.isEmpty
    }
    
    func saveChanges() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                if let img = selectedImage {
                    _ = try await authService.uploadAvatar(image: img)
                    successMessage = "Foto actualizada. "
                }
                
                if username != authService.currentUser?.username {
                    _ = try await authService.updateProfile(username: username, email: email)
                    successMessage = (successMessage ?? "") + "Nombre actualizado. "
                }
                
                if isPrivate != (authService.currentUser?.isPrivate ?? false) {
                    try await UserService.shared.updatePrivacy(isPrivate: isPrivate)
                    successMessage = (successMessage ?? "") + "Privacidad actualizada. "
                    
                    // Actualizar el usuario actual localmente
                    if let currentUser = authService.currentUser {
                        let updatedUser = UserDTO(
                            id: currentUser.id,
                            username: currentUser.username,
                            email: currentUser.email,
                            avatar: currentUser.avatar,
                            isPrivate: isPrivate
                        )
                        authService.currentUser = updatedUser
                    }
                }
                
                if !oldPassword.isEmpty {
                    _ = try await authService.changePassword(old: oldPassword, new: newPassword)
                    successMessage = (successMessage ?? "") + "Contraseña cambiada."
                }
                
                isLoading = false
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
                
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
