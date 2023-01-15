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

struct Get: AsyncParsableCommand {

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

	mutating func run() async throws {
		// Initialize a new KubernetesClient
		guard let client = KubernetesClient(provider: .shared(MultiThreadedEventLoopGroup(numberOfThreads: 1))) else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		defer {
			try? client.syncShutdown()
		}

		if name != nil && allNamespaces {
			throw SwiftkubectlError.configError("A resource cannot be retrieved by name across all namespaces")
		}

		let namespaceSelector = resolveNamespace() ?? NamespaceSelector.namespace(client.config.namespace)

		// Determine the GroupVersionResource
		let gvr = try await determineGVR(client: client, kind: kind)

		// Get or List resources
		let resources: [MetadataHavingResource]
		if let name = name {
			resources = try await getResource(client, gvr: gvr, in: namespaceSelector, name: name)
		} else {
			resources = try await listResources(client, gvr: gvr, in: namespaceSelector)
		}

		if resources.isEmpty {
			print("No resources found in \(namespace ?? client.config.namespace) namespace.")
			return
		}

		// Print results
		output(resources: resources, gvr: gvr)
	}

	private func determineGVR(client: KubernetesClient, kind: String) async throws -> GroupVersionResource {
		if let gvr = GroupVersionResource(for: kind) {
			return gvr
		}

		let lowercasedKind = kind.lowercased()

		let predicate: (meta.v1.APIResource) -> Bool = { resource in
			resource.name.lowercased() == lowercasedKind ||
				resource.shortNames?.contains(lowercasedKind) ?? false ||
				resource.kind.lowercased() == lowercasedKind
		}

		let resourceList = try await findResourceList(client: client, predicate: predicate)
		let name = resourceList.resources.first(where: predicate)!.name

		return GroupVersionResource(apiVersion: resourceList.groupVersion, resource: name)!
	}

	private func findResourceList(client: KubernetesClient, predicate: (meta.v1.APIResource) -> Bool) async throws -> meta.v1.APIResourceList {
		let discoveryClient = client.discoveryClient

		do {
			let allResourcesLists = try await discoveryClient.serverResources()
			let match = allResourcesLists
				.first { list in
					list.resources.contains(where: predicate)
				}

			guard let apiResourceList = match else {
				throw SwiftkubectlError.commandError("The server doesn't have a resource type \(kind)")
			}

			return apiResourceList
		} catch let error {
			switch error {
			case let SwiftkubeClientError.statusError(status):
				throw SwiftkubectlError.commandError("Error querying API resources: \(status.message ?? "[message missing]") \(status.reason ?? "[reason missing]")")
			default:
				throw SwiftkubectlError.commandError("Error querying API resources: \(error)")
			}
		}
	}

	private func getResource(_ client: KubernetesClient, gvr: GroupVersionResource, in namespaceSelector: NamespaceSelector, name: String) async throws -> [MetadataHavingResource] {
		// Use a generic client for the given GroupVersionResource
		let resource = try await client.unstructuredFor(gvr: gvr).get(in: gvr.namespaced ? namespaceSelector : .allNamespaces, name: name)

		if resource.apiVersion == "v1", resource.kind == "Status" {
			return []
		}

		return [resource]
	}

	private func listResources(_ client: KubernetesClient, gvr: GroupVersionResource, in namespaceSelector: NamespaceSelector) async throws -> [MetadataHavingResource] {
		// Use a generic client for the given GroupVersionKind
		return try await client.for (gvr: gvr).list(in: gvr.namespaced ? namespaceSelector : .allNamespaces).items
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

	// Sample output
	private func output(resources: [MetadataHavingResource], gvr: GroupVersionResource) {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = .withInternetDateTime

		if gvr.namespaced {
			print(
				"NAME".padding(toLength: 24, withPad: " ", startingAt: 0),
				"NAMESPACE".padding(toLength: 24, withPad: " ", startingAt: 0),
				"CREATED AT".padding(toLength: 20, withPad: " ", startingAt: 0)
			)

			resources.forEach { resource in
				let date = formatter.string(from: resource.metadata?.creationTimestamp ?? Date())

				print(
					resource.metadata!.name!.padding(toLength: 24, withPad: " ", startingAt: 0),
					resource.metadata!.namespace!.padding(toLength: 24, withPad: " ", startingAt: 0),
					date.padding(toLength: 20, withPad: " ", startingAt: 0)
				)
			}
		} else {
			print(
				"NAME".padding(toLength: 40, withPad: " ", startingAt: 0),
				"CREATED AT".padding(toLength: 20, withPad: " ", startingAt: 0)
			)

			resources.forEach { resource in
				let date = formatter.string(from: resource.metadata!.creationTimestamp!)

				print(
					resource.metadata!.name!.padding(toLength: 40, withPad: " ", startingAt: 0),
					date.padding(toLength: 20, withPad: " ", startingAt: 0)
				)
			}
		}
	}
}
