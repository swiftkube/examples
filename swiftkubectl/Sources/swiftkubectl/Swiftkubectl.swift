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
import NIO
import SwiftkubeModel
import SwiftkubeClient
import Foundation

enum SwiftkubectlError: Error {
	case commandError(String)
	case configError(String)
	case clientError(Error)
}

@main
struct Swiftkubectl: AsyncParsableCommand {
	static let configuration = CommandConfiguration(
		abstract: "Swiftkube-c-t-l",
		discussion: """
			An example kubernetes cli using SwiftkubeClient implementing
			a tiny subset of the functionality for demo purposes.
			""",
		subcommands: [Apply.self, Get.self, Create.self, ServerVersion.self, APIVersions.self, APIResources.self]
	)
	init() {}
}
