# SwiftkubeDash

<p align="center">
	<img src="https://img.shields.io/badge/Swift-5.2-orange.svg" />
	<img src="https://img.shields.io/badge/SwiftkubeClient-0.1.0-blue.svg" />
	<img src="https://img.shields.io/badge/platforms-mac+linux-brightgreen.svg?style=flat" alt="Mac + Linux" />
</p>

## Overview

A miny example dashboard using [SwiftkubeClient](https://github.com/swiftkube/client) on [Vapor](https://github.com/vaopr/vapor).

## Screenshots

![Deployments](./Screenshots/deployments.png)
![Deployment](./Screenshots/one-deployment.png)
![Pods](./Screenshots/pods.png)
![Pod](./Screenshots/one-pod.png)
![Logs](./Screenshots/logs.png)
![Create](./Screenshots/create-object.png)

## Usage

:information_source: The app tries to determine the kubeconfig automatically so a valid config should be available at the correct location.

To try this just clone this repository and then depending on the environment:

```bash
$ git clone https://github.com/swiftkube/examples
$ cd examples/swiftkubedash
```

### Locally

If you want to run this locally, then just build the prject and start the executable:

```bash
$ swift build
$ .build/debug/Run serve --env production --hostname 0.0.0.0 --port 8080
```

A valid kubeconfig file should exists in your `$HOME/.kube/config`, which will be picked up and used by the app.

### Docker & Docker Compose

Build the docker image and run it. You can mount a valid kubeconfig into the running container via a volumen mount. For example you can mount your local config like this:

```bash
$ docker build . -t <image>
$ docker run -v $HOME/.kube/config:/app/.kube/config -p 8080:8080 <image> 
```

### Kkubernetes

You can deploy the docker image in Kubernetes. The app will configure itself with the mounted service-account and namespace.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: swiftkube-dash
  labels:
    app: swiftkube-dash
spec:
  replicas: 1
  selector:
    matchLabels:
      app: swiftkube-dash
  template:
    metadata:
      labels:
        app: swiftkube-dash
    spec:
      containers:
      - name: swiftkube-dash
        image: swiftkubedash
        ports:
        - containerPort: 8080
```
