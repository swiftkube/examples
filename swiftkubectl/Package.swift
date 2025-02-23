// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swiftkubectl",
	platforms: [
		.macOS(.v12)
	],
	dependencies: [
//		.package(name: "SwiftkubeClient", url: "https://github.com/swiftkube/client.git", from: "0.14.0"),
		.package(url: "../../client", branch: "main"),
		.package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
	],
	targets: [
		.executableTarget(
			name: "swiftkubectl",
			dependencies: [
				.product(name: "SwiftkubeClient", package: "client"),
				.product(name: "ArgumentParser", package: "swift-argument-parser")
		])
	]
)
