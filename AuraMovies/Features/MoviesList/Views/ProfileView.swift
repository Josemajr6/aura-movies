import SwiftUI

struct ProfileView: View {
    // Managers para acceder a los datos
    @State private var favorites = FavoritesManager.shared
    @State private var history = HistoryManager.shared
    
    // Estado para saber qué lista estamos viendo
    @State private var selectedList = "Favoritas"
    let listTypes = ["Favoritas", "Vistas"]
    
    let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // CABECERA DE PERFIL
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                        .background(Circle().fill(.white))
                        .shadow(radius: 4)
                    
                    Text("Usuario Aura")
                        .font(.title2)
                        .bold()
                    
                    // Estadísticas rápidas
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(favorites.movies.count)")
                                .font(.title3).bold()
                            Text("Favoritas").font(.caption).foregroundColor(.secondary)
                        }
                        VStack {
                            Text("\(history.movies.count)")
                                .font(.title3).bold()
                            Text("Vistas").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemGroupedBackground))
                
                // SELECTOR DE LISTA (Segmented Control)
                Picker("Lista", selection: $selectedList) {
                    ForEach(listTypes, id: \.self) { type in
                        Text(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // CONTENIDO DE LA LISTA
                ScrollView {
                    let moviesToShow = (selectedList == "Favoritas") ? favorites.movies : history.movies
                    
                    if moviesToShow.isEmpty {
                        ContentUnavailableView(
                            selectedList == "Favoritas" ? "Sin Favoritos" : "Sin Historial",
                            systemImage: selectedList == "Favoritas" ? "heart.slash" : "eye.slash",
                            description: Text(selectedList == "Favoritas" ? "Marca tus pelis favoritas con ❤️" : "Marca las pelis vistas con 👁️")
                        )
                        .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(moviesToShow) { movie in
                                NavigationLink(value: movie) {
                                    MoviePosterCell(movie: movie)
                                        // Si es la lista de Vistas, añadimos el check
                                        .overlay(alignment: .topLeading) {
                                            if selectedList == "Vistas" {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(.green)
                                                    .background(Circle().fill(.white))
                                                    .padding(8)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            // RUTAS DE NAVEGACIÓN
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movie: movie)
            }
            .navigationDestination(for: Cast.self) { actor in
                ActorDetailView(actorId: actor.id, actorName: actor.name)
            }
        }
    }
}
