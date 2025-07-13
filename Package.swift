// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenTextExtractor",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(
            name: "ScreenTextExtractor",
            targets: ["ScreenTextExtractor"])
    ],
    dependencies: [
        .package(url: "https://github.com/cocoabits/MASShortcut.git", branch: "master")
    ],
    targets: [
        .executableTarget(
            name: "ScreenTextExtractor",
            dependencies: ["MASShortcut"],
            path: "Sources"
        )
    ]
)