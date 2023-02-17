// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WSIpaManager",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/johnsundell/files.git", from: "4.2.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.4"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/qiuzhifei/swift-commands", from: "0.6.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "WSIpaManager",
            dependencies: [
                .product(name: "Files", package: "files"),
                .product(name: "Alamofire", package: "alamofire"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Commands", package: "swift-commands"),
            ],
            resources:[
//                .copy("downloadmanager"),
                .process("downloadmanager"),
                
                ]
        ),
        
        
        
        
        .testTarget(
            name: "WSIpaManagerTests",
            dependencies: ["WSIpaManager"]),
    ]
)
