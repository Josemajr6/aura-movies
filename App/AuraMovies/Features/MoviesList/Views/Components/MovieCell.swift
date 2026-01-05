import SwiftUI

struct MovieCell: View {
    let movie: Movie
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: movie.posterURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 80, height: 120)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 120)
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "photo")
                        .frame(width: 80, height: 120)
                        .background(Color.gray.opacity(0.3))
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(movie.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(movie.releaseDate ?? "N/A")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", movie.voteAverage))
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
