//
//  NotificationsView.swift
//  AuraMovies
//
//  Created by José Manuel Jiménez Rodríguez on 5/1/26.
//


import SwiftUI

struct NotificationsView: View {
    @State private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if notificationManager.notifications.isEmpty {
                    ContentUnavailableView(
                        "Sin Notificaciones",
                        systemImage: "bell.slash",
                        description: Text("Aquí aparecerán tus notificaciones")
                    )
                } else {
                    List {
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
                    }
                    .listStyle(.plain)
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
            .refreshable {
                await notificationManager.checkForNewNotifications()
            }
        }
    }
    
    func handleNotificationTap(_ notification: AppNotification) {
        notificationManager.markAsRead(notification.id)
        
        // Aquí puedes navegar según el tipo de notificación
        // Por ejemplo, si es una solicitud, abrir FollowRequestsView
        // Por ahora solo marcamos como leída
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

#Preview {
    NotificationsView()
}