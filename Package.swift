// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Homie",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "hkctl", targets: ["hkctl"])
    ],
    targets: [
        .executableTarget(
            name: "hkctl",
            path: "hkctl"
        )
    ]
)
