import App
import Vapor
import SwiftkubeClient
import Metrics
import Prometheus

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
MetricsSystem.bootstrap(PrometheusMetricsFactory(client: PrometheusClient()))
let app = Application(env)
defer { app.shutdown() }
try configure(app)
try app.run()
