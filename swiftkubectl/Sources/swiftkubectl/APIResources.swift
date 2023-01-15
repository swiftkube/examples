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

struct Resource {
	let name: String
	let groupVersion: String
	let apiVersion: String
	let kind: String
	let shortNames: [String]?
	let namespaced: Bool
}

struct APIResources: AsyncParsableCommand {

	public static let configuration = CommandConfiguration(
		commandName: "api-resources",
		abstract: "Print the supported API resources on the server."
	)

	func run() async throws {
		// Initialize a new KubernetesClient
		guard let client = KubernetesClient(provider: .shared(MultiThreadedEventLoopGroup(numberOfThreads: 1))) else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		defer {
			try? client.syncShutdown()
		}

		do {
			let listOfResourceLists = try await client.discoveryClient.serverResources()
			let resources = listOfResourceLists
				.flatMap { list in
					list.resources
						.map { it in
							Resource(
								name: it.name,
								groupVersion: list.groupVersion,
								apiVersion: list.apiVersion,
								kind: it.kind,
								shortNames: it.shortNames,
								namespaced: it.namespaced
							)
						}
				}
				.sorted {
					$0.name < $1.name
				}

			print(
				"NAME".padding(toLength: 36, withPad: " ", startingAt: 0),
				"SHORTNAMES".padding(toLength: 12, withPad: " ", startingAt: 0),
				"APIVERSION".padding(toLength: 40, withPad: " ", startingAt: 0),
				"NAMESPACED".padding(toLength: 12, withPad: " ", startingAt: 0),
				"KIND".padding(toLength: 20, withPad: " ", startingAt: 0)
			)

			resources.forEach { resource in
				print(
					resource.name.padding(toLength: 36, withPad: " ", startingAt: 0),
					(resource.shortNames?.joined(separator: ",") ?? "").padding(toLength: 12, withPad: " ", startingAt: 0),
					resource.groupVersion.padding(toLength: 40, withPad: " ", startingAt: 0),
					(resource.namespaced ? "true" : "false").padding(toLength: 12, withPad: " ", startingAt: 0),
					resource.kind.padding(toLength: 20, withPad: " ", startingAt: 0)
				)
			}
		} catch let error {
			switch error {
			case let SwiftkubeClientError.statusError(status):
				print(status)
			default:
				print(error)
			}
		}
	}
}
