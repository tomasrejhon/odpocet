// swift-tools-version: 5.9
import PackageDescription

// A local test harness for the shared Foundation logic. The iPhone app lives in Odpocet.xcodeproj.
let package = Package(
    name: "CountdownCore",
    platforms: [.macOS(.v13), .iOS(.v17)],
    targets: [
        .target(name: "CountdownCore", path: "Shared"),
        .testTarget(name: "CountdownCoreTests", dependencies: ["CountdownCore"], path: "Tests")
    ]
)
