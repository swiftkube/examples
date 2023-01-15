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

final class CreateDeploynet: AsyncParsableCommand {

	public static let configuration = CommandConfiguration(
		commandName: "deployment",
		abstract: "Create a Deployment."
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
		help: "Image name to run."
	)
	var image: String

	func run() async throws {
		// Initialize a new KubernetesClient
		guard let client = KubernetesClient() else {
			throw SwiftkubectlError.configError("Error initializing client")
		}

		defer {
			try? client.syncShutdown()
		}

		let labels = ["app": "swiftkube-c-t-l"]

		// Create the Deployment object using the model closure-based builders
		let deployment = sk.deployment(name: name) {
			$0.spec = sk.deploymentSpec {
				$0.replicas = 1
				$0.selector = sk.match(labels: labels)
				$0.template = sk.podTemplate {
					$0.metadata = sk.metadata {
						$0.labels = labels
					}
					$0.spec = sk.podSpec {
						$0.containers = [
							sk.container(name: "swiftkube-c-t-l") {
								$0.image = image
							}
						]
					}
				}
			}
		}

		// Create the Deployment in the given namespace
		let res = try await client.appsV1.deployments.create(inNamespace: .namespace(namespace ?? client.config.namespace), deployment)
		print("Deployment \(name) created in namespace \(res.metadata!.namespace!)")
	}
}
