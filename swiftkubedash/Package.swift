// swift-tools-version:5.2
import PackageDescription

let package = Package(
	name: "SwiftkubeDash",
	platforms: [
		.macOS(.v10_15)
	],
	dependencies: [
		.package(name: "SwiftkubeClient", path: "../../client"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
		.package(url: "https://github.com/vapor/leaf", from: "4.0.0-tau.1"),
	],
	targets: [
		.target(
			name: "App",
			dependencies: [
				.product(name: "SwiftkubeClient", package: "SwiftkubeClient"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Leaf", package: "leaf")
			],
			swiftSettings: [
				.unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
			]
		),
		.target(name: "Run", dependencies: [.target(name: "App")])
	]
)
