// swift-tools-version:5.5
import PackageDescription

let package = Package(
	name: "SwiftkubeDash",
	platforms: [
		.macOS(.v10_15)
	],
	dependencies: [
		.package(name: "SwiftkubeClient", url: "https://github.com/swiftkube/client.git", from: "0.12.0"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.68.0"),
		.package(url: "https://github.com/vapor/leaf", from: "4.2.4"),
		.package(url: "https://github.com/MrLotU/SwiftPrometheus.git", from: "1.0.1")
	],
	targets: [
		.target(
			name: "App",
			dependencies: [
				.product(name: "SwiftkubeClient", package: "SwiftkubeClient"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Leaf", package: "leaf"),
				.product(name: "SwiftPrometheus", package: "SwiftPrometheus"),
			],
			swiftSettings: [
				.unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
			]
		),
		.executableTarget(
			name: "Run",
			dependencies: [
				.target(name: "App")
			]
		)
	]
)
