import Vapor
import Fluent

struct UserSearchController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let users = routes.grouped("users").grouped(Token.authenticator())
        
        users.get("search", use: searchUsers)
         users.get(":userID", "profile", use: getUserProfile)
         users.post(":userID", "follow", use: followUser)
         users.delete(":userID", "unfollow", use: unfollowUser)
         users.delete(":userID", "remove-follower", use: removeFollower) // 🆕 NUEVO
         users.get("follow-requests", use: getFollowRequests)
         users.post("follow-requests", ":requestID", "accept", use: acceptFollowRequest)
         users.post("follow-requests", ":requestID", "reject", use: rejectFollowRequest)
         users.get(":userID", "followers", use: getFollowers)
         users.get(":userID", "following", use: getFollowing)
         users.get("stats", use: getUserStats)
    }
    
    // MARK: - DTOs
    struct UserSearchResult: Content {
        let id: UUID
        let username: String
        let avatar: String?
        let isPrivate: Bool
        let followStatus: String?
        let followersCount: Int
        let followingCount: Int
    }
    
    struct UserProfileResponse: Content {
        let id: UUID
        let username: String
        let email: String?
        let avatar: String?
        let isPrivate: Bool
        let followStatus: String?
        let canViewProfile: Bool
        let followersCount: Int
        let followingCount: Int
        let favoriteMovies: [UserMovieDTO]?
        let watchedMovies: [UserMovieDTO]?
    }
    
    struct UserMovieDTO: Content {
        let movieID: Int
        let title: String
        let posterPath: String?
    }
    
    struct FollowRequestDTO: Content {
        let id: UUID
        let follower: UserSearchResult
        let createdAt: Date
    }
    
    struct UserStatsResponse: Content {
        let followersCount: Int
        let followingCount: Int
        let pendingRequestsCount: Int
    }
    
    // MARK: - Búsqueda
    func searchUsers(req: Request) async throws -> [UserSearchResult] {
        let currentUser = try req.auth.require(User.self)
        let currentUserID = try currentUser.requireID()
        
        guard let searchQuery = req.query[String.self, at: "q"], !searchQuery.isEmpty else {
            throw Abort(.badRequest, reason: "Debes proporcionar un término de búsqueda")
        }
        
        let users = try await User.query(on: req.db)
            .filter(\.$username, .custom("LIKE"), "%\(searchQuery)%")
            .limit(20)
            .all()
        
        var results: [UserSearchResult] = []
        
        for user in users {
            let userID = try user.requireID()
            if userID == currentUserID { continue }
            
            let followStatus = try await getFollowStatus(
                followerID: currentUserID,
                followingID: userID,
                on: req.db
            )
            
            let followersCount = try await UserFollow.query(on: req.db)
                .filter(\.$following.$id == userID)
                .filter(\.$status == .accepted)
                .count()
            
            let followingCount = try await UserFollow.query(on: req.db)
                .filter(\.$follower.$id == userID)
                .filter(\.$status == .accepted)
                .count()
            
            results.append(UserSearchResult(
                id: userID,
                username: user.username,
                avatar: user.avatar,
                isPrivate: user.isPrivate ?? false,
                followStatus: followStatus,
                followersCount: followersCount,
                followingCount: followingCount
            ))
        }
        
        return results
    }
    
    // MARK: - Perfil
    func getUserProfile(req: Request) async throws -> UserProfileResponse {
        let currentUser = try req.auth.require(User.self)
        let currentUserID = try currentUser.requireID()
        
        guard let targetUserID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "ID de usuario inválido")
        }
        
        guard let targetUser = try await User.find(targetUserID, on: req.db) else {
            throw Abort(.notFound, reason: "Usuario no encontrado")
        }
        
        let isOwnProfile = currentUserID == targetUserID
        
        let followStatus = isOwnProfile ? nil : try await getFollowStatus(
            followerID: currentUserID,
            followingID: targetUserID,
            on: req.db
        )
        
        let canViewProfile: Bool
        if isOwnProfile {
            canViewProfile = true
        } else if targetUser.isPrivate ?? false {
            canViewProfile = followStatus == "following"
        } else {
            canViewProfile = true
        }
        
        let followersCount = try await UserFollow.query(on: req.db)
            .filter(\.$following.$id == targetUserID)
            .filter(\.$status == .accepted)
            .count()
        
        let followingCount = try await UserFollow.query(on: req.db)
            .filter(\.$follower.$id == targetUserID)
            .filter(\.$status == .accepted)
            .count()
        
        var favoriteMovies: [UserMovieDTO]?
        var watchedMovies: [UserMovieDTO]?
        
        if canViewProfile {
            let userMovies = try await UserMovie.query(on: req.db)
                .filter(\.$user.$id == targetUserID)
                .all()
            
            favoriteMovies = userMovies
                .filter { $0.isFavorite }
                .map { UserMovieDTO(movieID: $0.movieID, title: $0.title, posterPath: $0.posterPath) }
            
            watchedMovies = userMovies
                .filter { $0.isWatched }
                .map { UserMovieDTO(movieID: $0.movieID, title: $0.title, posterPath: $0.posterPath) }
        }
        
        return UserProfileResponse(
            id: targetUserID,
            username: targetUser.username,
            email: isOwnProfile ? targetUser.email : nil,
            avatar: targetUser.avatar,
            isPrivate: targetUser.isPrivate ?? false,
            followStatus: followStatus,
            canViewProfile: canViewProfile,
            followersCount: followersCount,
            followingCount: followingCount,
            favoriteMovies: favoriteMovies,
            watchedMovies: watchedMovies
        )
    }
    
    // MARK: - Seguir Usuario (CON NOTIFICACIÓN)
       func followUser(req: Request) async throws -> HTTPStatus {
           let currentUser = try req.auth.require(User.self)
           let currentUserID = try currentUser.requireID()
           
           guard let targetUserID = req.parameters.get("userID", as: UUID.self) else {
               throw Abort(.badRequest)
           }
           
           guard currentUserID != targetUserID else {
               throw Abort(.badRequest, reason: "No puedes seguirte a ti mismo")
           }
           
           guard let targetUser = try await User.find(targetUserID, on: req.db) else {
               throw Abort(.notFound)
           }
           
           let existingFollow = try await UserFollow.query(on: req.db)
               .filter(\.$follower.$id == currentUserID)
               .filter(\.$following.$id == targetUserID)
               .first()
           
           if let existing = existingFollow {
               if existing.status == .rejected {
                   existing.status = targetUser.isPrivate ?? false ? .pending : .accepted
                   try await existing.save(on: req.db)
               }
               return .ok
           }
           
           let status: FollowStatus = (targetUser.isPrivate ?? false) ? .pending : .accepted
           let follow = UserFollow(followerID: currentUserID, followingID: targetUserID, status: status)
           try await follow.save(on: req.db)
           
           // 🔔 CREAR NOTIFICACIÓN
           if status == .accepted {
               // Cuenta pública - notificar directamente
               try await req.application.createNotificationWithPush(
                   for: targetUserID,
                   type: .newFollower,
                   title: "Nuevo seguidor",
                   message: "\(currentUser.username) ha comenzado a seguirte",
                   relatedUserID: currentUserID,
                   relatedUsername: currentUser.username
               )
           } else {
               // Cuenta privada - notificar solicitud
               try await req.application.createNotificationWithPush(
                   for: targetUserID,
                   type: .newFollowRequest,
                   title: "Nueva solicitud de seguimiento",
                   message: "\(currentUser.username) quiere seguirte",
                   relatedUserID: currentUserID,
                   relatedUsername: currentUser.username
               )

           }
           
           return .created
       }
    
    // MARK: - Dejar de seguir
    func unfollowUser(req: Request) async throws -> HTTPStatus {
        let currentUser = try req.auth.require(User.self)
        let currentUserID = try currentUser.requireID()
        
        guard let targetUserID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let follow = try await UserFollow.query(on: req.db)
            .filter(\.$follower.$id == currentUserID)
            .filter(\.$following.$id == targetUserID)
            .first() else {
            throw Abort(.notFound)
        }
        
        try await follow.delete(on: req.db)
        return .noContent
    }
    
    // MARK: - Solicitudes
    func getFollowRequests(req: Request) async throws -> [FollowRequestDTO] {
        let currentUser = try req.auth.require(User.self)
        let currentUserID = try currentUser.requireID()
        
        let requests = try await UserFollow.query(on: req.db)
            .filter(\.$following.$id == currentUserID)
            .filter(\.$status == .pending)
            .with(\.$follower)
            .all()
        
        var results: [FollowRequestDTO] = []
        
        for request in requests {
            // No usamos guard let porque .follower no es opcional cuando se usa .with()
            let follower = request.follower
            let followerID = try follower.requireID()
            
            let followersCount = try await UserFollow.query(on: req.db)
                .filter(\.$following.$id == followerID)
                .filter(\.$status == .accepted)
                .count()
            
            let followingCount = try await UserFollow.query(on: req.db)
                .filter(\.$follower.$id == followerID)
                .filter(\.$status == .accepted)
                .count()
            
            results.append(FollowRequestDTO(
                id: try request.requireID(),
                follower: UserSearchResult(
                    id: followerID,
                    username: follower.username,
                    avatar: follower.avatar,
                    isPrivate: follower.isPrivate ?? false,
                    followStatus: nil,
                    followersCount: followersCount,
                    followingCount: followingCount
                ),
                createdAt: request.createdAt ?? Date()
            ))
        }
        
        return results
    }
    
    func acceptFollowRequest(req: Request) async throws -> HTTPStatus {
           let currentUser = try req.auth.require(User.self)
           let currentUserID = try currentUser.requireID()
           
           guard let requestID = req.parameters.get("requestID", as: UUID.self) else {
               throw Abort(.badRequest)
           }
           
           guard let follow = try await UserFollow.find(requestID, on: req.db) else {
               throw Abort(.notFound)
           }
           
           guard follow.$following.id == currentUserID else {
               throw Abort(.forbidden)
           }
           
           follow.status = .accepted
           try await follow.save(on: req.db)
           
           // 🔔 NOTIFICAR AL USUARIO QUE SU SOLICITUD FUE ACEPTADA
           let followerID = follow.$follower.id
            try await req.application.createNotificationWithPush(
                for: followerID,
                type: .followRequestAccepted,
                title: "Solicitud aceptada",
                message: "\(currentUser.username) ha aceptado tu solicitud",
                relatedUserID: currentUserID,
                relatedUsername: currentUser.username
            )
           return .ok
       }
    
    func rejectFollowRequest(req: Request) async throws -> HTTPStatus {
        let currentUser = try req.auth.require(User.self)
        let currentUserID = try currentUser.requireID()
        
        guard let requestID = req.parameters.get("requestID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        guard let follow = try await UserFollow.find(requestID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        guard follow.$following.id == currentUserID else {
            throw Abort(.forbidden)
        }
        
        follow.status = .rejected
        try await follow.save(on: req.db)
        
        return .ok
    }
    
    // MARK: - Listas
    func getFollowers(req: Request) async throws -> [UserSearchResult] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let followers = try await UserFollow.query(on: req.db)
            .filter(\.$following.$id == userID)
            .filter(\.$status == .accepted)
            .with(\.$follower)
            .all()
        
        var results: [UserSearchResult] = []
        for follow in followers {
            let follower = follow.follower
            let followerID = try follower.requireID()
            
            let followersCount = try await UserFollow.query(on: req.db)
                .filter(\.$following.$id == followerID)
                .filter(\.$status == .accepted)
                .count()
            
            let followingCount = try await UserFollow.query(on: req.db)
                .filter(\.$follower.$id == followerID)
                .filter(\.$status == .accepted)
                .count()
            
            results.append(UserSearchResult(
                id: followerID,
                username: follower.username,
                avatar: follower.avatar,
                isPrivate: follower.isPrivate ?? false,
                followStatus: nil,
                followersCount: followersCount,
                followingCount: followingCount
            ))
        }
        
        return results
    }
    
    func getFollowing(req: Request) async throws -> [UserSearchResult] {
        guard let userID = req.parameters.get("userID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let following = try await UserFollow.query(on: req.db)
            .filter(\.$follower.$id == userID)
            .filter(\.$status == .accepted)
            .with(\.$following)
            .all()
        
        var results: [UserSearchResult] = []
        for follow in following {
            let followedUser = follow.following
            let followedUserID = try followedUser.requireID()
            
            let followersCount = try await UserFollow.query(on: req.db)
                .filter(\.$following.$id == followedUserID)
                .filter(\.$status == .accepted)
                .count()
            
            let followingCount = try await UserFollow.query(on: req.db)
                .filter(\.$follower.$id == followedUserID)
                .filter(\.$status == .accepted)
                .count()
            
            results.append(UserSearchResult(
                id: followedUserID,
                username: followedUser.username,
                avatar: followedUser.avatar,
                isPrivate: followedUser.isPrivate ?? false,
                followStatus: nil,
                followersCount: followersCount,
                followingCount: followingCount
            ))
        }
        
        return results
    }
    
    // MARK: - Estadísticas
    func getUserStats(req: Request) async throws -> UserStatsResponse {
        let currentUser = try req.auth.require(User.self)
        let currentUserID = try currentUser.requireID()
        
        let followersCount = try await UserFollow.query(on: req.db)
            .filter(\.$following.$id == currentUserID)
            .filter(\.$status == .accepted)
            .count()
        
        let followingCount = try await UserFollow.query(on: req.db)
            .filter(\.$follower.$id == currentUserID)
            .filter(\.$status == .accepted)
            .count()
        
        let pendingRequestsCount = try await UserFollow.query(on: req.db)
            .filter(\.$following.$id == currentUserID)
            .filter(\.$status == .pending)
            .count()
        
        return UserStatsResponse(
            followersCount: followersCount,
            followingCount: followingCount,
            pendingRequestsCount: pendingRequestsCount
        )
    }
    
    func removeFollower(req: Request) async throws -> HTTPStatus {
          let currentUser = try req.auth.require(User.self)
          let currentUserID = try currentUser.requireID()
          
          guard let followerUserID = req.parameters.get("userID", as: UUID.self) else {
              throw Abort(.badRequest)
          }
          
          // Buscar la relación donde:
          // followerUserID me sigue a mí (currentUserID)
          guard let follow = try await UserFollow.query(on: req.db)
              .filter(\.$follower.$id == followerUserID)
              .filter(\.$following.$id == currentUserID)
              .first() else {
              throw Abort(.notFound, reason: "Esta persona no te sigue")
          }
          
          try await follow.delete(on: req.db)
          return .noContent
      }
    
    // MARK: - Helper
    private func getFollowStatus(followerID: UUID, followingID: UUID, on db: Database) async throws -> String? {
        guard let follow = try await UserFollow.query(on: db)
            .filter(\.$follower.$id == followerID)
            .filter(\.$following.$id == followingID)
            .first() else {
            return "not_following"
        }
        
        switch follow.status {
        case .accepted: return "following"
        case .pending: return "pending"
        case .rejected: return "not_following"
        }
    }
}
