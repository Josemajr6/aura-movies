import SwiftUI

struct MoviePosterCell: View {
    let movie: Movie
    @State private var favorites = FavoritesManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // PÓSTER
                AsyncImage(url: movie.posterURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 150, height: 225)
                .cornerRadius(12)
                .shadow(radius: 4)
                
                // BOTÓN LIKE
                Image(systemName: favorites.isFavorite(movie.id) ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundColor(favorites.isFavorite(movie.id) ? .red : .white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(8)
                    // GESTO DE ALTA PRIORIDAD (para que no falle)
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            // Pasamos 'movie' entero, no solo el ID
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                favorites.toggleFavorite(movie: movie)
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                    )
            }
            
            // TÍTULO
            Text(movie.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(.primary)
                .frame(maxWidth: 150, alignment: .leading)
        }
    }
}
