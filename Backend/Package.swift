// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Backend",
    platforms: [
       .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-mongo-driver.git", from: "1.3.1"),
        // Librería para envío de correos
        .package(url: "https://github.com/Mikroservices/Smtp.git", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "Backend",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentMongoDriver", package: "fluent-mongo-driver"),
                .product(name: "Smtp", package: "Smtp")
            ]
        ),
    ]
)
