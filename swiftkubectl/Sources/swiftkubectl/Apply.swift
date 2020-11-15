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

final class Apply: ParsableCommand {

	public static let configuration = CommandConfiguration(
		abstract: "Apply a configuration to a resource by filename."
	)

	@Option(
		name: [.customShort("f"), .long],
		help: "Filename that contains the configuration to apply."
	)
	var file: String

	func run() throws {
		// Initialize a new KubernetesClient
		guard let client = KubernetesClient(provider: .shared(MultiThreadedEventLoopGroup(numberOfThreads: 1))) else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		let url = URL(fileURLWithPath: file)
		let yaml = try String(contentsOf: url)

		let decoder = YAMLDecoder()

		// Read the passed YAML file
		// YAMS's `load_all` return a sequnence of `Any` and `compose_all` returns a sequence of `Node`
		// hence the compose -> serialize -> decode workaround
		// in order to get a list of type-erased `AnyKubernetesAPIResources`
		let resources: [AnyKubernetesAPIResource] = try Yams.compose_all(yaml: yaml)
			.map { node -> AnyKubernetesAPIResource in
				let resourceYAML = try Yams.serialize(node: node)
				return try decoder.decode(AnyKubernetesAPIResource.self, from: resourceYAML)
			}

		resources.forEach { applyResource(client: client, resource: $0) }
	}

	private func applyResource(client: KubernetesClient, resource: AnyKubernetesAPIResource) {
		guard let gvk = try? GroupVersionKind(forName: "\(resource.apiVersion)/\(resource.kind)") else {
			print("Unknown Kubernetes resource [\(resource.apiVersion)/\(resource.kind)]")
			return
		}

		guard let name = resource.metadata?.name else {
			print("Skipping resource of type [\(gvk.rawValue)], because it doesn't define a name.")
			return
		}

		guard let namespace = resource.metadata?.namespace else {
			print("Skipping resource [\(gvk.rawValue)/\(name)], because it doesn't define a namespace.")
			return
		}

		let namespaceSelector = NamespaceSelector.namespace(namespace)
		let genericClient = client.for(gvk: gvk)

		// Load the resource
		let _ = try? genericClient.get(in: namespaceSelector, name: name)
			.flatMap { existing -> EventLoopFuture<AnyKubernetesAPIResource> in
				// if it exists, then update it
				let res = genericClient.update(in: namespaceSelector, resource)
				print("Resource [\(gvk.rawValue)/\(name)] updated in namespace: \(namespace)")
				return res
			}
			.flatMapError { error -> EventLoopFuture<AnyKubernetesAPIResource> in
				// if it doesn't exist yet, then create it
				let res = genericClient.create(in: namespaceSelector, resource)
				print("Resource [\(gvk.rawValue)/\(name)] created in namespace: \(namespace)")
				return res
			}
			.wait()
	}
}
