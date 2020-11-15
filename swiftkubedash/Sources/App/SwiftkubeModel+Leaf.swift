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

extension apps.v1.Deployment: LeafDataRepresentable {

	public var leafData: LeafData {
		return .dictionary([
			"name": name,
			"namespace": metadata?.namespace,
			"ready": "\(status?.readyReplicas ?? 0)/\(spec?.replicas ?? 0)",
			"available": "\(status?.availableReplicas ?? 0)",
			"age": age(),
			"labels": labels(),
			"selectors": selectors()
		])
	}

	private func labels() -> [String] {
		return metadata?.labels?.compactMap { "\($0.key):\($0.value)" } ?? []
	}

	private func selectors() -> [String]? {
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

extension core.v1.Pod: LeafDataRepresentable {

	public var leafData: LeafData {

		return .dictionary([
			"name": name,
			"namespace": metadata?.namespace,
			"phase": status?.phase,
			"age": age(),
			"containers": status?.containerStatuses
		])
	}
}

extension core.v1.ContainerStatus: LeafDataRepresentable {

	public var leafData: LeafData {

		return .dictionary([
			"name": name,
			"image": image,
			"restartCount": restartCount,
			"state": state,
			"stateColor": state?.stateColor
		])
	}
}

extension core.v1.ContainerState: LeafDataRepresentable {

	public var leafData: LeafData {
		if let running = running {
			return .string("Running since: \(running.startedAt?.description ?? "N/A")")
		} else if let terminated = terminated {
			return .string("Terminated since: \(terminated.finishedAt?.description ?? "N/A")")
		} else if let waiting = waiting {
			return .string("Waiting: \(waiting.message ?? "N/A")")
		} else {
			return .trueNil
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
