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

import Foundation
import Leaf
import SwiftkubeModel

struct DeploymentModel: Encodable {
	let name: String?
	let namespace: String?
	let ready: String?
	let available: String?
	let age: String?
	let labels: [String]
	let selectors: [String]
}

struct PodModel: Encodable {
	let name: String?
	let namespace: String?
	let phase: String?
	let age: String?
	let containers: [ContainerModel]
}

struct ContainerModel: Encodable {
	let name: String?
	let image: String?
	let restartCount: Int32
	let state: String?
	let stateColor: String?
}

extension apps.v1.Deployment {

	var model: DeploymentModel {
		DeploymentModel(
			name: name,
			namespace: metadata?.namespace,
			ready: "\(status?.readyReplicas ?? 0)/\(spec?.replicas ?? 0)",
			available: "\(status?.availableReplicas ?? 0)",
			age: age(),
			labels: labels(),
			selectors: selectors()
		)
	}

	private func labels() -> [String] {
		metadata?.labels?.compactMap { "\($0.key):\($0.value)" } ?? []
	}

	private func selectors() -> [String] {
		let labels = spec?.selector.matchLabels?.compactMap { "\($0.key):\($0.value)" } ?? []

		let expressions = spec?.selector.matchExpressions?.compactMap { exp -> String in
			let renderedExpression = "\(exp.key) \(exp.operator)"
			if let values = exp.values {
				return "\(renderedExpression) [\(values.joined(separator: ","))]"
			}
			return renderedExpression
		} ?? []

		return labels + expressions
	}
}

extension core.v1.Pod {

	var model: PodModel {
		PodModel(
			name: name,
			namespace: metadata?.namespace,
			phase: status?.phase,
			age: age(),
			containers: status?.containerStatuses?.compactMap { $0.model } ?? []
		)
	}
}

extension core.v1.ContainerStatus {

	var model: ContainerModel {
		ContainerModel(
			name: name,
			image: image,
			restartCount: restartCount,
			state: state?.statePhase,
			stateColor: state?.stateColor
		)
	}
}

extension core.v1.ContainerState {

	var statePhase: String? {
		if let running = running {
			return "Running since: \(running.startedAt?.description ?? "N/A")"
		} else if let terminated = terminated {
			return "Terminated since: \(terminated.finishedAt?.description ?? "N/A")"
		} else if let waiting = waiting {
			return "Waiting: \(waiting.message ?? "N/A")"
		} else {
			return nil
		}
	}

	var stateColor: String {
		if let _ = running {
			return "is-success"
		} else if let _ = terminated {
			return "is-waring"
		} else if let _ = waiting {
			return "is-danger"
		} else {
			return ""
		}
	}
}

extension KubernetesAPIResource {

	func age() -> String {
		if let creationTime = metadata?.creationTimestamp {
			let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: creationTime, to: Date())
			return "\(components.day, unit: "d")\(components.hour, unit: "h")\(components.minute, unit: "m")\(components.second, unit: "s")"
		}

		return "N/A"
	}
}
