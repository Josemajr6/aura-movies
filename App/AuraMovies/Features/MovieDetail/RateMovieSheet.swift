import SwiftUI

struct RateMovieSheet: View {
    @Environment(\.dismiss) var dismiss
    let movie: Movie
    
    // Estados para la reseña
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var isSaving = false
    
    let reviewLimit = 280
    
    var body: some View {
        NavigationStack {
            ScrollView { // 👈 AÑADIDO SCROLLVIEW (Para que si el título es gigante, se pueda bajar)
                VStack(spacing: 24) {
                    
                    // 1. ENCABEZADO (Solución "Ampliado")
                    HStack(alignment: .top, spacing: 16) {
                        // POSTER
                        AsyncImage(url: movie.posterURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                Color.gray.opacity(0.3)
                            }
                        }
                        .frame(width: 90, height: 135) // Un poco más grande
                        .cornerRadius(8)
                        .clipped()
                        .shadow(radius: 4)
                        
                        // TEXTO
                        VStack(alignment: .leading, spacing: 8) {
                            Text(movie.title)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .lineLimit(nil) // 👈 SIN LÍMITE DE LÍNEAS
                                .fixedSize(horizontal: false, vertical: true) // 👈 OBLIGA A EXPANDIRSE VERTICALMENTE
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let date = movie.releaseDate {
                                Text(date.prefix(4))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 2. ESTRELLAS
                    VStack(spacing: 12) {
                        Text("¿Qué puntuación le das?")
                            .font(.headline)
                        
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= rating ? "star.fill" : "star")
                                    .font(.system(size: 36))
                                    .foregroundColor(.yellow)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                            rating = index
                                        }
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                            }
                        }
                    }
                    
                    // 3. CAMPO DE TEXTO
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tu opinión (Opcional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        ZStack(alignment: .topLeading) {
                            if reviewText.isEmpty {
                                Text("Escribe aquí tu reseña...")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .padding(12)
                            }
                            
                            TextEditor(text: $reviewText)
                                .frame(height: 120)
                                .padding(4)
                                .scrollContentBackground(.hidden)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(12)
                                .onChange(of: reviewText) { _, newValue in
                                    if newValue.count > reviewLimit {
                                        reviewText = String(newValue.prefix(reviewLimit))
                                    }
                                }
                        }
                        .padding(.horizontal)
                        
                        Text("\(reviewText.count)/\(reviewLimit)")
                            .font(.caption2)
                            .foregroundColor(reviewText.count == reviewLimit ? .red : .secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal)
                    }
                    
                    // 4. BOTÓN GUARDAR
                    Button(action: saveReview) {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white).padding(.trailing, 5)
                            }
                            Text("Publicar Valoración")
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((rating > 0 && !isSaving) ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(rating == 0 || isSaving)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Valorar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        // 👇 IMPORTANTE: Forzamos que se abra en GRANDE para evitar bugs visuales
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
    
    func saveReview() {
        isSaving = true
        Task {
            do {
                // 1. Servidor
                try await MovieService.shared.syncMovieInteraction(
                    movie: movie,
                    isFavorite: nil,
                    isWatched: true,
                    userRating: rating,
                    userReview: reviewText
                )
                
                // 2. Local
                await MainActor.run {
                    if !HistoryManager.shared.isSeen(movie.id) {
                        HistoryManager.shared.toggleSeen(movie: movie)
                    }
                    dismiss()
                }
            } catch {
                print("Error guardando reseña: \(error)")
                isSaving = false
            }
        }
    }
}
