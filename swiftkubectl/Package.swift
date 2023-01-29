// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swiftkubectl",
	platforms: [
		.macOS(.v10_15)
	],
	dependencies: [
		.package(name: "SwiftkubeClient", url: "https://github.com/swiftkube/client.git", from: "0.13.0"),
		.package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser", from: "1.2.0")
	],
	targets: [
		.executableTarget(
			name: "swiftkubectl",
			dependencies: [
				.product(name: "SwiftkubeClient", package: "SwiftkubeClient"),
				.product(name: "ArgumentParser", package: "swift-argument-parser")
		])
	]
)
