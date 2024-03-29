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
import Yams

final class Apply: AsyncParsableCommand {

	public static let configuration = CommandConfiguration(
		abstract: "Apply a configuration to a resource by filename."
	)

	@Option(
		name: [.customShort("f"), .long],
		help: "Filename that contains the configuration to apply."
	)
	var file: String

	func run() async throws {
		// Initialize a new KubernetesClient
		guard let client = KubernetesClient() else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		defer {
			try? client.syncShutdown()
		}

		let url = URL(fileURLWithPath: file)
		let yaml = try String(contentsOf: url)

		let decoder = YAMLDecoder()

		// Read the passed YAML file
		// YAMS's `load_all` return a sequnence of `Any` and `compose_all` returns a sequence of `Node`
		// hence the compose -> serialize -> decode workaround
		// in order to get a list of type-erased `AnyKubernetesAPIResources`
		let resources: [UnstructuredResource] = try Yams.compose_all(yaml: yaml)
			.map { node -> UnstructuredResource in
				let resourceYAML = try Yams.serialize(node: node)
				return try decoder.decode(UnstructuredResource.self, from: resourceYAML)
			}

		for resource in resources {
			try await applyResource(client: client, resource: resource)
		}
	}

	private func applyResource(client: KubernetesClient, resource: UnstructuredResource) async throws {
		guard let gvr = GroupVersionResource(for: resource.kind) else {
			print("Unknown Kubernetes resource [\(resource.apiVersion)/\(resource.kind)]")
			return
		}

		guard let name = resource.metadata?.name else {
			print("Skipping resource of type [\(gvr.resource)], because it doesn't define a name.")
			return
		}

		guard let namespace = resource.metadata?.namespace else {
			print("Skipping resource [\(gvr.resource)/\(name)], because it doesn't define a namespace.")
			return
		}

		let namespaceSelector = NamespaceSelector.namespace(namespace)
		let genericClient = client.for(gvr: gvr)

		// Load the resource
		do {
			let resource = try await genericClient.get(in: namespaceSelector, name: name)
			// if it exists, then update it
			let _ = try await genericClient.update(in: namespaceSelector, resource)
			print("Resource [\(gvr.resource)/\(name)] updated in namespace: \(namespace)")
		} catch {
			// if it doesn't exist yet, then create it
			let _ = try await genericClient.create(in: namespaceSelector, resource)
			print("Resource [\(gvr.resource)/\(name)] created in namespace: \(namespace)")
		}
	}
}
