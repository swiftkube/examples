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
import Vapor
import Leaf

extension Application {

	private struct SwiftkubeClientKey: StorageKey, Sendable {
		typealias Value = KubernetesClient
	}

	var kubernetesClient: KubernetesClient {
		get {
			return storage[SwiftkubeClientKey.self]!
		}
		set {
			storage[SwiftkubeClientKey.self] = newValue
		}
	}

	func initKubernetesClient() {
		self.kubernetesClient = KubernetesClient(logger: logger)!
	}
}

extension Request {

	var kubernetesClient: KubernetesClient {
		return application.kubernetesClient
	}
}

public func configure(_ app: Application) throws {

	app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
	app.initKubernetesClient()
	app.views.use(.leaf)

	try routes(app)
}
