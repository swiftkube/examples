// swift-tools-version: 5.9
import PackageDescription

let package = Package(
	name: "SwiftkubeDash",
	platforms: [
		.macOS(.v13)
	],
	dependencies: [
		.package(url: "https://github.com/swiftkube/client.git", from: "0.20.0"),
		.package(url: "https://github.com/vapor/vapor.git", from: "4.113.2"),
		.package(url: "https://github.com/vapor/leaf", from: "4.4.1"),
		.package(url: "https://github.com/swift-server/swift-prometheus", from: "2.0.0")
	],
	targets: [
		.executableTarget(
			name: "App",
			dependencies: [
				.product(name: "SwiftkubeClient", package: "client"),
				.product(name: "Vapor", package: "vapor"),
				.product(name: "Leaf", package: "leaf"),
				.product(name: "Prometheus", package: "swift-prometheus"),
			],
			swiftSettings: [
				.unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
			]
		),
	]
)
