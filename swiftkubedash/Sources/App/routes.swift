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

import SwiftkubeClient
import SwiftkubeModel
import Vapor
import Leaf

func routes(_ app: Application) throws {

	app.get { req in
		req.leaf.render(template: "home", context: [
			"selected": "none"
		])
	}

	app.get("deployments") { req in

		req.kubernetesClient.appsV1.deployments.list(in: .allNamespaces)
			.hop(to: req.eventLoop)
			.flatMap { (deployments: apps.v1.DeploymentList) -> EventLoopFuture<View> in
				return req.leaf.render(template: "deployments", context: [
					"deployments": .array(deployments.items.sorted(by: { (lhs, rhs) in lhs.name! < rhs.name! })),
					"selected": "deployments"
				])
			}
	}

	app.get("deployments", ":namespace", ":name") { req -> EventLoopFuture<View> in
		let namespace = req.parameters.get("namespace")!
		let name = req.parameters.get("name")!

		return req.kubernetesClient.appsV1.deployments.get(in: .namespace(namespace), name: name)
			.hop(to: req.eventLoop)
			.flatMap { (deployment: apps.v1.Deployment) -> EventLoopFuture<View> in
				return req.leaf.render(template: "deployment", context: [
					"deployment": deployment.leafData,
					"selected": "deployments"
				])
			}
	}

	app.get("pods") { req in

		req.kubernetesClient.pods.list(in: .allNamespaces)
			.hop(to: req.eventLoop)
			.flatMap { (pods: core.v1.PodList) -> EventLoopFuture<View> in
				return req.leaf.render(template: "pods", context: [
					"pods": .array(pods.items.sorted(by: { (lhs, rhs) in lhs.name! < rhs.name! })),
					"selected": "pods"
				])
			}
	}

	app.get("pods", ":namespace", ":name") { req -> EventLoopFuture<View> in
		let namespace = req.parameters.get("namespace")!
		let name = req.parameters.get("name")!

		return req.kubernetesClient.pods.get(in: .namespace(namespace), name: name)
			.hop(to: req.eventLoop)
			.flatMap { (pod: core.v1.Pod) -> EventLoopFuture<View> in
				return req.leaf.render(template: "pod", context: [
					"pod": pod.leafData,
					"selected": "pods"
				])
			}
	}

	app.post("namespace", ":namespace") { req -> EventLoopFuture<Response> in
		let namespace = req.parameters.get("namespace")!
		guard let payload = req.body.string else {
			return req.eventLoop.makeFailedFuture(Abort(.custom(code: 400, reasonPhrase: "Empty payload")))
		}

		guard let resource = try? AnyKubernetesAPIResource.load(yaml: payload).first else {
			return req.eventLoop.makeFailedFuture(Abort(.custom(code: 400, reasonPhrase: "Payload is not a valid manifest")))
		}

		guard let gvk = try? GroupVersionKind(for: "\(resource.apiVersion)/\(resource.kind)") else {
			return req.eventLoop.makeFailedFuture(Abort(.custom(code: 400, reasonPhrase: "Unknown resource: \(resource.apiVersion)/\(resource.kind)")))
		}

		return req.kubernetesClient.for(gvk: gvk).create(in: .namespace(namespace), resource)
				.flatMapError { error in
					if case let SwiftkubeClientError.requestError(status) = error {
						let abort = Abort(.custom(code: UInt(status.code!), reasonPhrase: status.message!))
						return req.eventLoop.makeFailedFuture(abort)
					}

					let abort = Abort(.custom(code: 500, reasonPhrase: error.localizedDescription))
					return req.eventLoop.makeFailedFuture(abort)
				}
				.hop(to: req.eventLoop)
				.map { resource in
					let data = try! JSONEncoder().encode(resource)
					return Response(status: .created, body: Response.Body(data: data))
				}
	}

	app.webSocket("logs", ":namespace", ":name", ":container") { req, ws in
		let namespace = req.parameters.get("namespace")!
		let name = req.parameters.get("name")!
		let container = req.parameters.get("container")!

		let task: HTTPClient.Task<Void>
		do {
			task = try req.kubernetesClient.pods.follow(in: .namespace(namespace), name: name, container: container) { line in
				ws.send(line)
			}
		} catch let error {
			return ws.send(error.localizedDescription)
		}

		ws.onClose.whenComplete { result in
			task.cancel()
		}
	}
}
