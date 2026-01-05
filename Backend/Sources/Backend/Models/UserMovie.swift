import Fluent
import Vapor

final class UserMovie: Model, Content {
    static let schema = "user_movies"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "movie_id")
    var movieID: Int

    @Field(key: "is_favorite")
    var isFavorite: Bool

    @Field(key: "is_watched")
    var isWatched: Bool // Se mantiene true si hay reseña

    @Field(key: "title")
    var title: String
    
    @Field(key: "poster_path")
    var posterPath: String?
    
    @Field(key: "vote_average")
    var voteAverage: Double?
    
    @Field(key: "release_date")
    var releaseDate: String?
    
    @Field(key: "user_rating")
    var userRating: Int? // 1 a 5 estrellas
    
    @Field(key: "user_review")
    var userReview: String? // Comentario de texto

    init() { }

    init(userID: UUID, movieID: Int, title: String, posterPath: String?, voteAverage: Double?, releaseDate: String?, isFavorite: Bool, isWatched: Bool, userRating: Int?, userReview: String?) {
        self.$user.id = userID
        self.movieID = movieID
        self.title = title
        self.posterPath = posterPath
        self.voteAverage = voteAverage
        self.releaseDate = releaseDate
        self.isFavorite = isFavorite
        self.isWatched = isWatched
        self.userRating = userRating
        self.userReview = userReview
    }
}

// MIGRACIÓN
struct CreateUserMovie: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_movies")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("movie_id", .int, .required)
            .field("is_favorite", .bool, .required)
            .field("is_watched", .bool, .required)
            .field("title", .string, .required)
            .field("poster_path", .string)
            .field("vote_average", .double)
            .field("release_date", .string)
            .field("user_rating", .int)    // 👈 Nuevo
            .field("user_review", .string) // 👈 Nuevo
            .unique(on: "user_id", "movie_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_movies").delete()
    }
}
