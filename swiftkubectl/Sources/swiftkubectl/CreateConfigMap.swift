//
// Copyright 2020 Iskandar Abudiab (iabudiab.dev)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import ArgumentParser
import Foundation
import NIO
import SwiftkubeModel
import SwiftkubeClient

/// Type for transforming CLI options from `--from-literal key=value`
struct LiteralKeyValue {

	let key: String
	let value: String

	init(input: String) throws {
		let split = input.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)
		guard split.count == 2 else {
			throw SwiftkubectlError.configError("Invalid --from-literal value provided")
		}
		self.key = String(split[0])
		self.value = String(split[1])
	}
}

/// Type for transforming CLI options from `--from-file file` or `--from-file key=file`
struct FileKeyValue {

	let key: String
	let url: URL

	init(input: String) throws {
		let split = input.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: true)

		switch split.count {
		case 1:
			self.url = URL(fileURLWithPath: String(split[0]))
			self.key = url.lastPathComponent
		case 2:
			self.url = URL(fileURLWithPath: String(split[1]))
			self.key = String(split[0])
		default:
			throw SwiftkubectlError.configError("Invalid --from-file value provided")
		}
	}
}

final class CreateConfigMap: ParsableCommand {

	public static let configuration = CommandConfiguration(
		commandName: "configmap",
		abstract: "Create a ConfigMap."
	)

	@Argument(
		help: "The resource name."
	)
	var name: String

	@Option(
		name: [.customShort("n"), .long],
		help: "If present, the namespace scope for this CLI request."
	)
	var namespace: String?

	@Option(
		name: [.customLong("from-literal")],
		help: "Specify a key and literal value to insert in configmap (i.e. mykey=somevalue).",
		transform: LiteralKeyValue.init
	)
	var literals: [LiteralKeyValue] = []

	@Option(
		name: [.customLong("from-file")],
		help: """
			Key file can be specified using its file path, in which case file basename will be used as configmap key,
			or optionally with a key and file path, in which case the given key will be used.
			""",
		transform: FileKeyValue.init
	)
	var files: [FileKeyValue] = []

	func run() throws {
		// Initialize a new KubernetesClient
		guard let client = KubernetesClient(provider: .shared(MultiThreadedEventLoopGroup(numberOfThreads: 1))) else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		// Create an empty ConfigMap
		var configMap = sk.configMap(name: name)

		// Add the parsed CLI literals to the config map
		literals.forEach { literal in
			// core.v1.ConfigMap provides helper methods for populating the data field with literlas
			configMap.add(data: literal.value, forKey: literal.key)
		}

		// Add the parsed CLI files and their contents to the config map
		try files.forEach { file in
			// core.v1.ConfigMap provides helper methods for populating the data field with files
			try configMap.add(file: file.url, forKey: file.key)
		}

		// Create the ConfigMap in the given namespace
		let res = try client.configMaps.create(inNamespace: namespace, configMap).wait()
		print("ConfigMap \(name) created in namespace \(res.metadata!.namespace!)")
	}
}
