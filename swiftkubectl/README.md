# swiftkube-c-t-l

<p style="text-align: center;">
	<img src="https://img.shields.io/badge/Swift-5.5-orange.svg" />
	<img src="https://img.shields.io/badge/SwiftkubeClient-0.12.0-blue.svg" />
	<img src="https://img.shields.io/badge/platforms-mac+linux-brightgreen.svg?style=flat" alt="Mac + Linux" />
</p>

## Overview

An example  Kubernetes CLI using [SwiftkubeClient](https://github.com/swiftkube/client) implementing a tiny subset of 
the functionality for demo purposes.

This example demonstrates using [SwiftkubeClient](https://github.com/swiftkube/client) and 
[SwiftkubeModel](https://github.com/swiftkube/model) to communicate with API server. The implemented API mimicks `kubectl`.

## Showcases

- [x] Load Kubernetes objects
  - [x] by name in a given namespace
  - [x] list objects in all namespaces
- [x] Create Kubernetes objects
  - [x] `ConfigMaps` via `--from-literal` and `--from-file`
  - [x] `Deployments` with a given `image`
- [x] Apply object manifests from a file
- [x] Server version information
- [x] Server API Versions
- [x] Server API Resources

`SwiftkubeClient`  detects the current local `kubeconfig` automatically, i.e. if you've got a `kubeconfig` under
`~/.kube/config` it will be picked up and used for all `swiftkubectl` calls.

## Usage

Clone this repository and run:

```bash
$ swift build
$ .build/debug/swiftkubectl -h
OVERVIEW: Swiftkube-c-t-l

An example kubernetes cli using SwiftkubeClient implementing
a tiny subset of the functionality for demo purposes.

USAGE: swiftkubectl <subcommand>

OPTIONS:
  -h, --help              Show help information.

SUBCOMMANDS:
  apply                   Apply a configuration to a resource by filename.
  get                     Display one or many resources.
  create                  Create a resource.
  version                 Print the client and server version information for the current context.
  api-versions            Print the supported API versions on the server, in the form of 'group/version'.
  api-resources           Print the supported API resources on the server.

  See 'swiftkubectl help <subcommand>' for detailed help.
```
