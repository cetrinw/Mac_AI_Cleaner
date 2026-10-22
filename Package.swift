// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacAICleaner", platforms: [.macOS(.v14)],
    products: [.library(name: "CleanerCore", targets: ["CleanerCore"]), .executable(name: "MacAICleaner", targets: ["MacAICleaner"]), .executable(name: "cleaner-scan", targets: ["CleanerCLI"])],
    targets: [.target(name: "CleanerCore"), .executableTarget(name: "MacAICleaner", dependencies: ["CleanerCore"]), .executableTarget(name: "CleanerCLI", dependencies: ["CleanerCore"]), .testTarget(name: "CleanerCoreTests", dependencies: ["CleanerCore"])])
