# Containers

## Overview

- Container Engines: Docker, CRI-O, Podman, containerd
- Container Runtime: runc, crun, runv


## Podman

- Could manage pods
- Uses `libpod`
- Daemonless
- Could run containers in **rootless** or **rootful** mode
- Compare to Docker
  - Docker calls "containerd", which calls "runc"
  - Podman calls "runc" directly

Podman is not a service, does not start automatically on system boot. You can generate new `systemd` config files to achieve that.


## Pods

- A pod is a group of one or more containers
- Containers share the same network namespace (one IP address) and can communicate with each other over `localhost`
- Useful for applications that require multiple containers to work together, such as a web server and a database

```sh
# create a pod
podman pod create --name myPod -p 8080:80

# add a container to the pod
podman run -d \
  --pod myPod \
  -v /home/user/me/data:/data \
  nginx:latest

# list containers with pod name
podman ps --pod

# stop and start a pod
podman pod stop myPod
podman pod start myPod

# generate a Kubernetes YAML file
podman generate kube myPod > myPod.yaml

podman pod rm -f myPod

# recreate the pod from the YAML file
podman play kube myPod.yaml
```
