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

struct APIVersions: AsyncParsableCommand {

	public static let configuration = CommandConfiguration(
		commandName: "api-versions",
		abstract: "Print the supported API versions on the server, in the form of 'group/version'."
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
			let groupList = try await client.discoveryClient.serverGroups()
			let sorted = groupList.groups.sorted(by: {
				if $0.name == "" {
					return false
				}
				return $0.name < $1.name
			})

			for apiGroup in sorted {
				for apiVersion in apiGroup.versions.sorted(by: { $0.version < $1.version }) {
					if (apiGroup.name == "") {
						print(apiVersion.version)
					} else {
						print("\(apiGroup.name)/\(apiVersion.version)")
					}
				}
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
