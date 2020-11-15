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
		// Initialize a new KubernetesClient
		guard let client = KubernetesClient(provider: .shared(MultiThreadedEventLoopGroup(numberOfThreads: 1))) else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		if name != nil && allNamespaces {
			throw SwiftkubectlError.configError("A resource cannot be retrieved by name across all namespaces")
		}

		let namespaceSelector = resolveNamespace() ?? NamespaceSelector.namespace(client.config.namespace)

		// Determine the GroupVersionKind
		guard let gvk = try? GroupVersionKind(forName: kind) else {
			throw SwiftkubectlError.commandError("Unknown object kind: \(kind)")
		}
		JSONDecoder().dateDecodingStrategy = .iso8601
		// Get or List resources
		let resources: [MetadataHavingResource]
		if let name = name {
			resources = try getResource(client, gvk: gvk, in: namespaceSelector, name: name)
		} else {
			resources = try listResources(client, gvk: gvk, in: namespaceSelector)
		}

		if resources.isEmpty {
			print("No resources found in \(namespace ?? client.config.namespace) namespace.")
			return
		}

		// Print results
		output(resources: resources, gvk: gvk)
	}

	private func getResource(_ client: KubernetesClient, gvk: GroupVersionKind, in namespaceSelector: NamespaceSelector, name: String) throws -> [MetadataHavingResource] {
		// Use a generic client for the given GroupVersionKind
		let resource = try client.for(gvk: gvk)
			.get(in: gvk.namespaced ? namespaceSelector : .allNamespaces, name: name)
			.wait()

		return [resource]
	}

	private func listResources(_ client: KubernetesClient, gvk: GroupVersionKind, in namespaceSelector: NamespaceSelector) throws -> [MetadataHavingResource] {
		// Use a generic client for the given GroupVersionKind
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

	// Sample ouput
	private func output(resources: [MetadataHavingResource], gvk: GroupVersionKind) {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = .withInternetDateTime

		if gvk.namespaced {
			print(
				kind.uppercased().padding(toLength: 40, withPad: " ", startingAt: 0),
				"NAMESPACE".padding(toLength: 16, withPad: " ", startingAt: 0),
				"CREATED AT".padding(toLength: 20, withPad: " ", startingAt: 0)
			)

			resources.forEach { resource in
				let date = formatter.string(from: resource.metadata!.creationTimestamp!)

				print(
					resource.name!.padding(toLength: 40, withPad: " ", startingAt: 0),
					resource.metadata!.namespace!.padding(toLength: 16, withPad: " ", startingAt: 0),
					date.padding(toLength: 20, withPad: " ", startingAt: 0)
				)
			}
		} else {
			print(
				kind.uppercased().padding(toLength: 40, withPad: " ", startingAt: 0),
				"CREATED AT".padding(toLength: 20, withPad: " ", startingAt: 0)
			)

			resources.forEach { resource in
				let date = formatter.string(from: resource.metadata!.creationTimestamp!)

				print(
					resource.name!.padding(toLength: 40, withPad: " ", startingAt: 0),
					date.padding(toLength: 20, withPad: " ", startingAt: 0)
				)
			}
		}
	}
}
