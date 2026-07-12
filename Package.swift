// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ScreenPet",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScreenPet", targets: ["ScreenPet"])
    ],
    targets: [
        .executableTarget(name: "ScreenPet"),
        .testTarget(
            name: "ScreenPetTests",
            dependencies: ["ScreenPet"]
        )
    ]
)
