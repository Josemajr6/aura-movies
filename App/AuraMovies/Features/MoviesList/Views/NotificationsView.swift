import SwiftUI

struct NotificationsView: View {
    @State private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    // Estados para solicitudes
    @State private var followRequests: [FollowRequestDTO] = []
    @State private var isLoadingRequests = false
    @State private var processingRequests: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            Group {
                if notificationManager.notifications.isEmpty && followRequests.isEmpty {
                    ContentUnavailableView(
                        "Sin Notificaciones",
                        systemImage: "bell.slash",
                        description: Text("Aquí aparecerán tus notificaciones y solicitudes")
                    )
                } else {
                    List {
                        // SECCIÓN: SOLICITUDES DE SEGUIMIENTO
                        if !followRequests.isEmpty {
                            Section {
                                ForEach(followRequests) { request in
                                    FollowRequestCellInNotifications(
                                        request: request,
                                        isProcessing: processingRequests.contains(request.id),
                                        onAccept: { acceptRequest(request) },
                                        onReject: { rejectRequest(request) }
                                    )
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "person.crop.circle.badge.clock")
                                        .foregroundColor(.orange)
                                    Text("Solicitudes de Seguimiento")
                                        .font(.headline)
                                }
                            }
                        }
                        
                        // SECCIÓN: NOTIFICACIONES NORMALES
                        if !notificationManager.notifications.isEmpty {
                            Section {
                                ForEach(notificationManager.notifications) { notification in
                                    NotificationCell(notification: notification)
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    notificationManager.deleteNotification(notification.id)
                                                }
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                        }
                                        .onTapGesture {
                                            handleNotificationTap(notification)
                                        }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.blue)
                                    Text("Notificaciones")
                                        .font(.headline)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                
                if !notificationManager.notifications.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                notificationManager.markAllAsRead()
                            } label: {
                                Label("Marcar todas como leídas", systemImage: "checkmark.circle")
                            }
                            
                            Button(role: .destructive) {
                                notificationManager.clearAll()
                            } label: {
                                Label("Eliminar todas", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .task {
                await loadFollowRequests()
            }
            .refreshable {
                await notificationManager.checkForNewNotifications()
                await loadFollowRequests()
            }
        }
    }
    
    // MARK: - Cargar Solicitudes
    private func loadFollowRequests() async {
        isLoadingRequests = true
        
        do {
            let requests = try await UserService.shared.getFollowRequests()
            await MainActor.run {
                self.followRequests = requests
                self.isLoadingRequests = false
            }
        } catch {
            print("❌ Error cargando solicitudes: \(error)")
            await MainActor.run {
                self.isLoadingRequests = false
            }
        }
    }
    
    // MARK: - Aceptar/Rechazar Solicitudes
    private func acceptRequest(_ request: FollowRequestDTO) {
        processingRequests.insert(request.id)
        
        Task {
            do {
                try await UserService.shared.acceptFollowRequest(requestID: request.id)
                await MainActor.run {
                    followRequests.removeAll { $0.id == request.id }
                    processingRequests.remove(request.id)
                    
                    // Añadir notificación local
                    notificationManager.addNotification(AppNotification(
                        type: .followRequestAccepted,
                        title: "Solicitud Aceptada",
                        message: "Has aceptado la solicitud de \(request.follower.username)"
                    ))
                }
            } catch {
                print("❌ Error aceptando solicitud: \(error)")
                await MainActor.run {
                    processingRequests.remove(request.id)
                }
            }
        }
    }
    
    private func rejectRequest(_ request: FollowRequestDTO) {
        processingRequests.insert(request.id)
        
        Task {
            do {
                try await UserService.shared.rejectFollowRequest(requestID: request.id)
                await MainActor.run {
                    followRequests.removeAll { $0.id == request.id }
                    processingRequests.remove(request.id)
                }
            } catch {
                print("❌ Error rechazando solicitud: \(error)")
                await MainActor.run {
                    processingRequests.remove(request.id)
                }
            }
        }
    }
    
    func handleNotificationTap(_ notification: AppNotification) {
        notificationManager.markAsRead(notification.id)
    }
}

// MARK: - Celda de Notificación
struct NotificationCell: View {
    let notification: AppNotification
    @State private var notificationManager = NotificationManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icono
            ZStack {
                Circle()
                    .fill(notificationManager.getColor(for: notification.type).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: notificationManager.getIcon(for: notification.type))
                    .font(.title3)
                    .foregroundColor(notificationManager.getColor(for: notification.type))
            }
            
            // Contenido
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                    
                    Spacer()
                }
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(notification.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            notification.isRead ?
                Color(.secondarySystemBackground) :
                Color.blue.opacity(0.05)
        )
        .cornerRadius(12)
    }
}

// MARK: - Celda de Solicitud (Nombre único para evitar conflictos)
struct FollowRequestCellInNotifications: View {
    let request: FollowRequestDTO
    let isProcessing: Bool
    let onAccept: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                if let avatarURL = request.follower.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.orange)
                        )
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(request.follower.username)
                            .font(.headline)
                        
                        if request.follower.isPrivate {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(timeAgo(from: request.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Botones
            HStack(spacing: 12) {
                Button(action: onReject) {
                    Text("Rechazar")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .disabled(isProcessing)
                
                Button(action: onAccept) {
                    Text("Aceptar")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(isProcessing ? 0.6 : 1.0)
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "Hace un momento"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "Hace \(minutes) min"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "Hace \(hours) h"
        } else {
            let days = Int(seconds / 86400)
            return "Hace \(days) d"
        }
    }
}

#Preview {
    NotificationsView()
}
