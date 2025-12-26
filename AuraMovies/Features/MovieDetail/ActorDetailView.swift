import SwiftUI

struct ActorDetailView: View {
    let actorId: Int // Solo necesitamos el ID para empezar
    let actorName: String // Para el título mientras carga
    
    @State private var person: Person?
    @State private var movies: [Movie] = []
    @State private var isLoading = true
    @State private var isBioExpanded = false // Para leer más/menos
    
    let columns = [GridItem(.adaptive(minimum: 120), spacing: 16)]
    
    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding(.top, 100)
            } else if let person = person {
                VStack(spacing: 20) {
                    // FOTO DE PERFIL
                    AsyncImage(url: person.profileURL) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .shadow(radius: 10)
                    .padding(.top, 20)
                    
                    // DATOS PERSONALES
                    VStack(spacing: 8) {
                        Text(person.name)
                            .font(.title)
                            .bold()
                        
                        if let birth = person.birthday {
                            Text("Nacimiento: \(birth)")
                                .foregroundColor(.secondary)
                        }
                        if let place = person.placeOfBirth {
                            Text(place)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    // BIOGRAFÍA (Expandible)
                    if !person.biography.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Biografía").font(.headline)
                            Text(person.biography)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(isBioExpanded ? nil : 4) // Truco pro
                            
                            Button(isBioExpanded ? "Leer menos" : "Leer más") {
                                withAnimation { isBioExpanded.toggle() }
                            }
                            .font(.caption).bold()
                        }
                        .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // FILMOGRAFÍA (Grid de películas)
                    VStack(alignment: .leading) {
                        Text("Filmografía Conocida")
                            .font(.title3).bold()
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(movies) { movie in
                                // ¡Navegación Circular!
                                NavigationLink(value: movie) {
                                    VStack {
                                        AsyncImage(url: movie.posterURL) { img in
                                            img.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color("PlaceholderColor")
                                        }
                                        .frame(height: 180)
                                        .cornerRadius(12)
                                        .shadow(radius: 3)
                                        
                                        Text(movie.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationTitle(actorName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Carga paralela
            do {
                async let personResp = MovieService.shared.fetchPerson(id: actorId)
                async let moviesResp = MovieService.shared.fetchPersonCredits(id: actorId)
                
                let (p, m) = try await (personResp, moviesResp)
                self.person = p
                self.movies = m
            } catch {
                print("Error actor: \(error)")
            }
            isLoading = false
        }
    }
}
