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
import Metrics
import Prometheus

struct DeploymentsContext: Encodable {
	let deployments: [DeploymentModel]
	let selected = "deployments"

	init(list: apps.v1.DeploymentList) {
		self.deployments = 	list.items.sorted(by: { (lhs, rhs) in lhs.name! < rhs.name! }).map(\.model)
	}
}

struct DeploymentContext: Encodable {
	let deployment: DeploymentModel
	let selected = "deployments"

	init(deployment: apps.v1.Deployment) {
		self.deployment = deployment.model
	}
}

struct PodsContext: Encodable {
	let pods: [PodModel]
	let selected = "pods"

	init(list: core.v1.PodList) {
		self.pods = list.items.sorted(by: { (lhs, rhs) in lhs.name! < rhs.name! }).map(\.model)
	}
}

struct PodContext: Encodable {
	let pod: PodModel
	let selected = "pods"

	init(pod: core.v1.Pod) {
		self.pod = pod.model
	}
}

func routes(_ app: Application) throws {

	app.get { req in
		req.view.render("home", [
			"selected": "none"
		])
	}

	app.get("deployments") { req async throws -> View in
		let deployments = try await req.kubernetesClient.appsV1.deployments.list(in: .allNamespaces)
		return try await req.view.render("deployments", DeploymentsContext(list: deployments))
	}

	app.get("deployments", ":namespace", ":name") { req async throws -> View in
		let namespace = req.parameters.get("namespace")!
		let name = req.parameters.get("name")!

		let deployment = try await req.kubernetesClient.appsV1.deployments.get(in: .namespace(namespace), name: name)
		return try await req.view.render("deployment", DeploymentContext(deployment: deployment))
	}

	app.get("pods") { req async throws -> View in
		let pods = try await req.kubernetesClient.pods.list(in: .allNamespaces)
		return try await req.view.render("pods", PodsContext(list: pods))
	}

	app.get("pods", ":namespace", ":name") { req async throws -> View in
		let namespace = req.parameters.get("namespace")!
		let name = req.parameters.get("name")!

		let pod = try await req.kubernetesClient.pods.get(in: .namespace(namespace), name: name)
		return try await req.view.render("pod", PodContext(pod: pod))
	}

	app.post("namespace", ":namespace") { req async throws -> Response in
		let namespace = req.parameters.get("namespace")!
		guard let payload = req.body.string else {
			throw Abort(.custom(code: 400, reasonPhrase: "Empty payload"))
		}

		guard let resource = try? AnyKubernetesAPIResource.load(yaml: payload).first else {
			throw Abort(.custom(code: 400, reasonPhrase: "Payload is not a valid manifest"))
		}

		guard let gvr = GroupVersionResource(for: resource.kind) else {
			throw Abort(.custom(code: 400, reasonPhrase: "Unknown resource: \(resource.apiVersion)/\(resource.kind)"))
		}

		do {
			let resource = try await req.kubernetesClient.for(gvr: gvr).create(in: .namespace(namespace), resource)
			let data = try! JSONEncoder().encode(resource)
			return Response(status: .created, body: Response.Body(data: data))
		} catch let error {
			if case let SwiftkubeClientError.statusError(status) = error {
				throw Abort(.custom(code: UInt(status.code!), reasonPhrase: status.message!))
			}

			throw Abort(.custom(code: 500, reasonPhrase: error.localizedDescription))
		}
	}

	app.webSocket("logs", ":namespace", ":name", ":container") { req, ws in
		let namespace = req.parameters.get("namespace")!
		let name = req.parameters.get("name")!
		let container = req.parameters.get("container")!

		let task: SwiftkubeClientTask
		do {
			task = try req.kubernetesClient.pods.follow(in: .namespace(namespace), name: name, container: container, retryStrategy: .never) { line in
				ws.send(line)
			}
		} catch let error {
			return ws.send(error.localizedDescription)
		}

		ws.onClose.whenComplete { result in
			task.cancel()
		}
	}

	app.get("metrics") { request -> EventLoopFuture<String> in
		let promise = request.eventLoop.makePromise(of: String.self)
		try MetricsSystem.prometheus().collect(into: promise)
		return promise.futureResult
	}
}
