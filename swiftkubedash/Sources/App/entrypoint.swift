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

import Vapor
import Logging
import Metrics
import NIOCore
import NIOPosix
import Prometheus

@main
enum Entrypoint {
	static func main() async throws {
		var env = try Environment.detect()
		try LoggingSystem.bootstrap(from: &env)
		MetricsSystem.bootstrap(PrometheusMetricsFactory())

		let app = try await Application.make(env)
		let executorTakeoverSuccess = NIOSingletons.unsafeTryInstallSingletonPosixEventLoopGroupAsConcurrencyGlobalExecutor()
		app.logger.debug(
			"Tried to install SwiftNIO's EventLoopGroup as Swift's global concurrency executor",
			metadata: ["success": .stringConvertible(executorTakeoverSuccess)]
		)

		do {
			try configure(app)
		} catch {
			app.logger.report(error: error)
			try? await app.asyncShutdown()
			throw error
		}
		try await app.execute()
		try await app.asyncShutdown()
	}
}
