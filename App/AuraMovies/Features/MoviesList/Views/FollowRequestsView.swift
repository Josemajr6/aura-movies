import SwiftUI

struct FollowRequestsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var requests: [FollowRequestDTO] = []
    @State private var isLoading = true
    @State private var processingRequests: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                        .padding(.top, 50)
                } else if requests.isEmpty {
                    ContentUnavailableView(
                        "Sin Solicitudes",
                        systemImage: "person.crop.circle.badge.clock",
                        description: Text("No tienes solicitudes de seguimiento pendientes")
                    )
                } else {
                    List {
                        ForEach(requests) { request in
                            FollowRequestCell(
                                request: request,
                                isProcessing: processingRequests.contains(request.id),
                                onAccept: { acceptRequest(request) },
                                onReject: { rejectRequest(request) }
                            )
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Solicitudes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task {
                await loadRequests()
            }
            .refreshable {
                await loadRequests()
            }
        }
    }
    
    private func loadRequests() async {
        isLoading = true
        
        do {
            let loadedRequests = try await UserService.shared.getFollowRequests()
            await MainActor.run {
                self.requests = loadedRequests
                self.isLoading = false
            }
        } catch {
            print("❌ Error cargando solicitudes: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func acceptRequest(_ request: FollowRequestDTO) {
        processingRequests.insert(request.id)
        
        Task {
            do {
                try await UserService.shared.acceptFollowRequest(requestID: request.id)
                await MainActor.run {
                    requests.removeAll { $0.id == request.id }
                    processingRequests.remove(request.id)
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
                    requests.removeAll { $0.id == request.id }
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
}

// MARK: - Celda de Solicitud
struct FollowRequestCell: View {
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
    FollowRequestsView()
}
