import Fluent
import Vapor

struct MoviesInteractionController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let movies = routes.grouped("movies")
        let tokenProtected = movies.grouped(Token.authenticator(), Token.guardMiddleware())
        
        tokenProtected.get("profile", use: getUserMovies)
        tokenProtected.post("interact", use: syncInteraction)
        tokenProtected.get("public-profile", ":userID", use: getPublicUserMovies)
    }
    
    // DTO de Salida
    struct UserMovieDTO: Content {
        let id: UUID?
        let movieID: Int
        let title: String
        let posterPath: String?
        let voteAverage: Double
        let releaseDate: String?
        let isFavorite: Bool
        let isWatched: Bool
        // 👇 Nuevos
        let userRating: Int?
        let userReview: String?
    }
    
    // DTO de Entrada
    struct InteractionRequest: Content {
        let movieID: Int
        let title: String
        let posterPath: String
        let voteAverage: Double?
        let releaseDate: String?
        let isFavorite: Bool?
        let isWatched: Bool?
        // 👇 Nuevos
        let userRating: Int?
        let userReview: String?
    }
    
    // MARK: - Helpers
    private func fetchMoviesForUser(userID: UUID, db: Database) async throws -> [UserMovieDTO] {
        let movies = try await UserMovie.query(on: db).filter(\.$user.$id == userID).all()
        return movies.map { m in
            UserMovieDTO(
                id: m.id,
                movieID: m.movieID,
                title: m.title,
                posterPath: m.posterPath,
                voteAverage: m.voteAverage ?? 0.0,
                releaseDate: m.releaseDate,
                isFavorite: m.isFavorite,
                isWatched: m.isWatched,
                userRating: m.userRating,
                userReview: m.userReview
            )
        }
    }

    func getUserMovies(req: Request) async throws -> [UserMovieDTO] {
        let user = try req.auth.require(User.self)
        return try await fetchMoviesForUser(userID: user.requireID(), db: req.db)
    }
    
    func getPublicUserMovies(req: Request) async throws -> [UserMovieDTO] {
        guard let targetUserID = req.parameters.get("userID", as: UUID.self) else { throw Abort(.badRequest) }
        return try await fetchMoviesForUser(userID: targetUserID, db: req.db)
    }
    
    // MARK: - Guardar Interacción
    func syncInteraction(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        let input = try req.content.decode(InteractionRequest.self)
        
        let existingMovie = try await UserMovie.query(on: req.db)
            .filter(\.$user.$id == user.requireID())
            .filter(\.$movieID == input.movieID)
            .first()
        
        if let movie = existingMovie {
            // Actualizar existente
            if let fav = input.isFavorite { movie.isFavorite = fav }
            if let watched = input.isWatched { movie.isWatched = watched }
            if let votes = input.voteAverage { movie.voteAverage = votes }
            if let date = input.releaseDate { movie.releaseDate = date }
            
            // Actualizar reseña si viene en la petición
            if let rating = input.userRating { movie.userRating = rating }
            if let review = input.userReview { movie.userReview = review }
            
            try await movie.save(on: req.db)
        } else {
            // Crear nueva
            let newMovie = UserMovie(
                userID: try user.requireID(),
                movieID: input.movieID,
                title: input.title,
                posterPath: input.posterPath,
                voteAverage: input.voteAverage,
                releaseDate: input.releaseDate,
                isFavorite: input.isFavorite ?? false,
                isWatched: input.isWatched ?? false,
                userRating: input.userRating,
                userReview: input.userReview
            )
            try await newMovie.save(on: req.db)
        }
        return .ok
    }
}
