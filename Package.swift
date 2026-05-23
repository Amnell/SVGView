// swift-tools-version:6.3

import PackageDescription

let package = Package(
	name: "SVGView",
    platforms: [
        .macOS(.v14),
        .iOS(.v14),
        .watchOS(.v7)
    ],
    products: [
    	.library(
    		name: "SVGView", 
    		targets: ["SVGView"]
    	),
        .executable(
            name: "GenerateReferencesCLI",
            targets: ["GenerateReferencesCLI"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.5.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "GenerateReferencesCLI",
            dependencies: [
                "SVGView",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "GenerateReferencesCLI"
        ),
    	.target(
    		name: "SVGView",
            path: "Source",
        ),
        .testTarget(
            name: "CoreGraphicsPolyfillTests",
            dependencies: ["SVGView"]
        ),
        .testTarget(
            name: "SVGViewTests",
            dependencies: ["SVGView"],
            resources: [
                .copy("w3c")
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
