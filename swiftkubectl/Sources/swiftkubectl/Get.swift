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
import NIO
import SwiftkubeModel
import SwiftkubeClient

struct Get: ParsableCommand {

	public static let configuration = CommandConfiguration(
		abstract: "Display one or many resources."
	)

	@Argument(
		help: "A kuberentes resource kind."
	)
	var kind: String

	@Argument(
		help: "The resource name."
	)
	var name: String?

	@Option(
		name: [.customShort("n"), .long],
		help: "If present, the namespace scope for this CLI request."
	)
	var namespace: String?

	@Flag(
		help: """
			If present, list the requested object(s) across all namespaces. Namespace in current context
			is ignored even if specified with --namespace.
			"""
	)
	var allNamespaces: Bool = false

	func run() throws {
		guard let client = KubernetesClient(provider: .shared(MultiThreadedEventLoopGroup(numberOfThreads: 1))) else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		if name != nil && allNamespaces {
			throw SwiftkubectlError.configError("A resource cannot be retrieved by name across all namespaces")
		}

		let namespaceSelector = resolveNamespace() ?? NamespaceSelector.namespace(client.config.namespace)

		let resources: [MetadataHavingResource]
		if let name = name {
			resources = try getResource(client, in: namespaceSelector, name: name)
		} else {
			resources = try listResources(client, in: namespaceSelector)
		}

		if resources.isEmpty {
			print("No resources found in \(namespace ?? client.config.namespace) namespace.")
			return
		}

		output(resources: resources)
	}

	private func getResource(_ client: KubernetesClient, in namespaceSelector: NamespaceSelector, name: String) throws -> [MetadataHavingResource] {
		guard let gvk = try? GroupVersionKind(forName: kind) else {
			throw SwiftkubectlError.commandError("Unknown object kind: \(kind)")
		}

		let resource = try client.for(gvk: gvk)
			.get(in: gvk.namespaced ? namespaceSelector : .allNamespaces, name: name)
			.wait()

		return [resource]
	}

	private func listResources(_ client: KubernetesClient, in namespaceSelector: NamespaceSelector) throws -> [MetadataHavingResource] {
		guard let gvk = try? GroupVersionKind(forName: kind) else {
			throw SwiftkubectlError.commandError("Unknown object kind: \(kind)")
		}

		return try client.for(gvk: gvk)
			.list(in: gvk.namespaced ? namespaceSelector : .allNamespaces)
			.wait()
			.items
	}

	private func resolveNamespace() -> NamespaceSelector? {
		switch (namespace, allNamespaces) {
		case (.none, false):
			return nil
		case let (.some(namespace), false):
			return .namespace(namespace)
		case (_, true):
			return .allNamespaces
		}
	}

	private func output(resources: [MetadataHavingResource]) {
		print(
			kind.uppercased().padding(toLength: 40, withPad: " ", startingAt: 0),
			"NAMESPACE".padding(toLength: 16, withPad: " ", startingAt: 0),
			"CREATED AT".padding(toLength: 20, withPad: " ", startingAt: 0)
		)

		resources.forEach { resource in
			print(
				resource.name!.padding(toLength: 40, withPad: " ", startingAt: 0),
				resource.metadata!.namespace!.padding(toLength: 16, withPad: " ", startingAt: 0),
				resource.metadata!.creationTimestamp!.padding(toLength: 20, withPad: " ", startingAt: 0)
			)
		}
	}
}
