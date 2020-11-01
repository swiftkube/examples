// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swiftkubectl",
	dependencies: [
		.package(name: "SwiftkubeClient", path: "../../client"),
		.package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.3.0"))
	],
	targets: [
		.target(
			name: "swiftkubectl",
			dependencies: [
				.product(name: "SwiftkubeClient", package: "SwiftkubeClient"),
				.product(name: "ArgumentParser", package: "swift-argument-parser")
		])
	]
)
