// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Siliang",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Siliang",
            path: "Sources/Siliang"
        )
    ]
)