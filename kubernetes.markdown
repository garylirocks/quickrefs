# Kubernetes

- [Architecture](#architecture)
- [Pod](#pod)
  - [Pod deployment](#pod-deployment)
- [Networking](#networking)
  - [Kubernetes services](#kubernetes-services)
  - [Ingress](#ingress)
- [Storage](#storage)
  - [PersistentVolume and PersistentVolumeClaims](#persistentvolume-and-persistentvolumeclaims)
  - [StorageClass](#storageclass)
- [Manifest files](#manifest-files)
- [Labels](#labels)
- [Configs](#configs)
  - [Usage](#usage)
  - [Notes](#notes)
- [Secrets](#secrets)
  - [Definition in YAML](#definition-in-yaml)
  - [Usage](#usage-1)
- [Jobs and cronjobs](#jobs-and-cronjobs)
- [DaemonSets](#daemonsets)
- [StatefulSet](#statefulset)
- [Probes](#probes)
- [Updates and Rollback](#updates-and-rollback)
- [Helm](#helm)
  - [Helm repos](#helm-repos)
  - [Install Helm Chart](#install-helm-chart)
- [Prometheus](#prometheus)
- [Minikube](#minikube)
  - [Addons](#addons)
  - [Minikube deepdive](#minikube-deepdive)
  - [Tips](#tips)
- [MicroK8s](#microk8s)
  - [Install a web server on a cluster](#install-a-web-server-on-a-cluster)

Benefits:

- Self-healing: restarting failed containers or replacing containers
- Dynamic scaling
- Automating rolling updates and rollbacks of containers
- Managing storage
- Managing network traffic
- Storing and managing sensitive information, such as passwords


## Architecture

In a general computer cluster:
  - We call the computers that run the scheduling softwares in a cluster as *control planes*
  - Other computers are called *nodes*
  - You give tasks to the *control planes*, then it schedules the tasks to the nodes

![Computer cluster](images/kubernetes_computer-cluster.svg)


In the case of Kubernetes:

![Kubernetes cluster](images/kubernetes_architecture.png)

- Control plane services

  - `kube-api-server`
    - front-end to the control plane, all the communications between the components are through it
    - you use command-line tool `kubectl` to interact with it
    - it exposes a RESTful API, to which you can post commands or YAML configuration files

  - `etcd`
    - high-availability, distributed and reliable key-value store
    - stores the current state and desired state of all objects within the cluster
    - in production, it's recommended to have 3 to 5 replicated instances of the `etcd` database for high availability

  - scheduler
    - assign workloads to nodes

  - controller
    - each controller runs in a non-terminating loop while watching and responding to events in the cluster
    - there are controllers to monitor nodes, containers and endpoints
    - uses the API server to determine the state of the object, and takes action when current state is different from the wanted state

- Node services

  - `kubelet`
    - agents on each node, accepts work request from the API server
    - monitors nodes and makes sure scheduled containers run as expected

  - `kube-proxy`
    - for local cluster networking, ensures that each node has a unique IP address
    - handle routing and load balancing of traffic by using iptables and IPVS
    - doesn't provide DNS services by itself, a DNS add-on based on CoreDNS is recommended

  - Container runtime
    - fetching, starting and stoping container images
    - several container runtime types are supported based on the Container Runtime Interface(CRI)

## Pod

- Represents a single instance of an app
- The smallest object you can create in Kubernetes, you CAN'T run containers directly
- A single pod can hold a group of one or more containers
- A pod includes information about the shared storage and network configuration, and a specification about how to run its packaged containers


![Pod](images/kubernetes_pod.svg)

![Pod Lifecycle](images/kubernetes_pod-lifecycle.svg)


### Pod deployment

With `kubectl`, there are four options to manage the deployment of pods:

- Pod templates
  - contains information such as container image name, ports
  - you can use templates to deploy pods manually, however, a manually-deployed pod isn't relaunched after it fails
- Replication controllers
  - uses pod templates and defines a specified number of pods that must run
  - ensures pods are always running on one or more nodes
  - replacing running pods with new pods if they fail, deleted or terminated
- Replica sets
  - replaces the replication controller as the preferred way to deploy replicas
  - has an extra option to include a selector value

- Deployments
  - A deployment is a management object one level higher than a replica set, enables you to deploy and manage updates for pods
  - update strategies:
    - Rolling: launch one pod at a time
    - Re-create: terminates pods before launching new pods
  - provide rollback strategy
  - enables you to apply any change to a cluster: deploy new versions of an app, update labels, run other replicas of your pods
  - `kubectl run` automatically creates a deployment with required replica set and pods, but the best practice is to manage all deployments with deployment definition files

## Networking

![Pods nodes IP](images/kubernetes_nodes-pods-assigned-ip-addresses.svg)

- Each pod you deploy gets assigned an IP from a pool (10.32.0.0/12 in the example)
- By default, pods and nodes can't communicate with each other by using different IP address ranges
- Kubernetes expects you to configure networking in such a way that:
  - Pods can communicate with one another across nodes without NAT
  - Nodes can communicate with all pods, and vice versa, without NAT
  - Agents on a node can communicate with all nodes and pods

Kubernetes offers several networking options that you can install to configure networking, including Antrea, Cisco Application Centric Infrastructure, Cilium, Flannel, Kubenet, VMware NSX-T


### Kubernetes services

![Kubernetes service](images/kubernetes_service.png)

***Service** here is different from the term in Docker Swarm*

- A Kubernetes service acts as a load balancer and redirects traffic to specific ports of specified pods by using port-forwarding rules
- Gets assigned an IP address from a service cluster's IP range (e.g. 10.96.0.0/12), a DNS name and an IP port
- The service uses the same `selector` key as deployments to select and group resources with matching labels into one single IP
- It needs four pieces of information to route traffic: `Service port`, `Network protocol`, `Target resource`, `Resource port`

Services can be of several types, each changes the behavior of the applications selected by the service:

- **ClusterIP** default value, exposes the applications internally only
  ![service labels](images/kubernetes_service-with-selector.svg)

  You set the selector label in a service definition to match the pod label defined in the pods' definition file

  The service here `drone-front-end-service` will group only the pods that match the label `app: front-end-nginx`

  ```yaml
  #service.yaml
  apiVersion: v1
  kind: Service
  metadata:
    name: contoso-website

  spec:
    type: ClusterIP           # service type
    selector:
      app: contoso-website
    ports:
      - port: 80              # SERVICE exposed port
        name: http            # SERVICE port name
        protocol: TCP         # The protocol the SERVICE will listen to
        targetPort: http      # Port to forward to in the pod
  ```

  ```sh
  kubectl apply -f ./service.yaml

  # show the service
  kubectl get service contoso-website
  ```

- **NodePort** exposes the service externally, assigns each node a static port that responds to that service. When accessed through `nodeIp:port`, the node automatically redirects the request to an internal service of the `ClusterIP` type
  ![nodeport](images/kubernetes_service-nodeport.png)
  - Port on the node need to be in range 30000 - 32767
  - Traffic goes from Node:port -> service:port -> pod:port
- **LoadBalancer** you typically configure load balancers when you use cloud providers (eg. Azure Load Balancer), automatically creates a `NodePort` service to which the load balancer's traffic is redirected and a `ClusterIP` service to forward internally
  ![loadbalancer type](images/kubernetes_service-loadbalancer.png)


### Ingress

- Ingress exposes routes for HTTP and HTTPS traffic from outside a cluster to services inside the cluster.
- The traffic goes like this: Ingress -> service -> pod
- Comparing to the `LoadBalancer` type, `ingress` is more like an `Azure Application Gateway`, it could handle **SSL termination, routing to different services based on url path, etc**
- Relies on the `HTTP application routing` addon in Azure, which routes the traffic, and creates a DNS zone as well (a DNS record is created automatically when you deploy the service)

![Ingress](images/kubernetes_ingress.png)

```yaml
#ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: contoso-website
  annotations:       # Use the HTTP application routing add-on
    kubernetes.io/ingress.class: addon-http-application-routing
spec:
  rules:
    - host: contoso.<uuid>.<region>.aksapp.io
      http:
        paths:
          - backend: # How the ingress will handle the requests
              serviceName: contoso-website # Which service the request will be forwarded to
              servicePort: http # Which port in that service
            path: / # Which path is this rule referring to
```

```sh
kubectl apply -f ./ingress.yaml

kubectl get ingress contoso-website
```

## Storage

### PersistentVolume and PersistentVolumeClaims

![storage abstractions](images/kubernetes_storage-abstractions.png)

```yaml
# persistent volume
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  ...
  mountOptions:
    - hard
    - nfsvers=4.0
  nfs:
    path: /path/on/nfs/server
    server: my-nfs-server-address
---
# persistent volume claims
kind: PersistentVolumeClaims
metadata:
  name: my-pvc
spec:
  storageClassName: manual
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
# pod specs
spec:
  containers:
  - name: my-container
    image: alpine
    command: ["sleep", "3600"]
    volumeMounts:
    - name: my-persistent-storage
      mountPath: "/path/to/mount/"        # absolute path

  volumes:
  - name: my-persistent-storage
    persistentStorageClaim:
      claimName: my-pvc
```

There are many levels of abstraction:

- Admin prepare the actual physical storages, could be local disk, nfs, cloud storages (AWS EBS, Azure Files), etc
- `PersistentVolume`
  - Not namespaced
  - Different properties in the YAML file depending on the storage type
- `PersistentVolumeClaims`
  - Defines storage requirement
  - Connects to a static `PersistentVolume` or a dynamic `StorageClass`, the connection is called `binding`
  - You can not bind two PVC to the same PV, but the same PVC could be used on multiple nodes
- Pod
  - Requests volumes through PVC
  - A container mounts a volume on a path

### StorageClass

This helps provision a storage dynamically, when a PVC requires a storage, the provisioner creates a PV to satisfy the requirement.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: my-storage-class
provisioner: kubernetes.io/aws-ebs
parameters:
  type: io1
  iopsPerGB: "10"
  fsType: ext4
```

## Manifest files

Structure of manifest files differs depending on the type of resource that you create. They share some common instructions:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: contoso-website # This will be the name of the deployment
```

A sample deployment manifest file, it uses `label` to find and group pods

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: contoso-website
spec:
  selector: # Define the wrapping strategy
    matchLabels: # Match all pods with the defined labels
      app: contoso-website # Labels follow the `name: value` template

  template: # This is the template of the pod inside the deployment
    metadata:
      labels:
        app: contoso-website
    spec:
      containers:         # containers inside a pod
        - image: mcr.microsoft.com/mslearn/samples/contoso-website
          name: contoso-website
          resources:
            requests:     # minimum resource requirement
              cpu: 100m
              memory: 128Mi
            limits:       # maximum resource requirement
              cpu: 250m
              memory: 256Mi
          ports:
            - containerPort: 80
              name: http
```

To deploy a file:

```sh
kubectl apply -f ./deployment.yaml

# get deployment
kubectl get deploy contoso-website
# NAME              READY   UP-TO-DATE   AVAILABLE   AGE
# contoso-website   1/1     1            1           44s

kubectl get pods
# NAME                               READY   STATUS    RESTARTS   AGE
# contoso-website-6d959cf499-s2b8s   1/1     Running   0          53s
```

## Labels

```sh
kubectl get pods --show-labels

# add/update label
kubectl label pod/podname myLabel=myValue
# pod/podname labeled

# remove a label
kubectl label pod/podname myLabel-

# search by labels
kubectl get pods --selector env=staging,team=web

# not equal
kubectl get pods --selector env!=staging

# in a range
kubectl get pods -l 'release-version in (1.0,2.0)' --show-labels
kubectl get pods -l 'env in (dev,staging)' --show-labels
```

## Configs

`my-configs.yaml` defines a ConfigMap resource

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-configs
data:
  api-endpoint: https://example.com/api
```

```sh
kubectl apply -f my-configs.yaml
# configmap/my-configs created

kubectl get configmap/my-configs --output yaml

# apiVersion: v1
# data:
#   api-endpoint: https://example.com/api
# ...
```

### Usage

- Mounted as files in a volume on containers inside Pod or Deployment
  - Automatically updated when value changes, no need to restart the Pod

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: configmap-as-files
    namespace: default
  spec:
    containers:
      - name: my-container
        image: alpine
        command: ["sleep", "3600"]
        volumeMounts:
        - name: my-volume
          mountPath: "/path/to/mount/"        # absolute path
          readOnly: true

    volumes:
      - name: my-volume
        configMap:
          name: my-configmap
          items:
          - key: "api-endpoint"
            path: "relative/path/to/file.txt" # must be relative path
  ```

- As env variables
  - Need to restart the Pod to get new values

  ```yaml
  spec:
    containers:
    - name: myContainer
      image: gary/coolimage:latest
      env:
      - name: endpoint
        valueFrom:
          configMapKeyRef:
            name: my-configs
            key: api-endpoint
  ```

### Notes

- Can only be accessed and mounted by containers in the same namespace
- Widely used by tools like Helm and Kubernetes Operator to store and read states

## Secrets

```sh
kubectl create secret generic my_secrets --from-literal=api_key=12345
# secret/apikey created

kubectl get secrets
# NAME            TYPE         DATA   AGE
# my_secrets      Opaque       1      7s

kubectl get secret my_secrets -o yaml
# apiVersion: v1
# data:
#   api_key: MTIzNDU=           # encoded in Base64
# kind: Secret
# metadata:
#   ...
# type: Opaque
```

### Definition in YAML

Use `stringData` and plain text

```yaml
apiVersion: v1
kind: Secret
  name: my_secrets
  namespace: default
type: Opaque
stringData:
  api_key: 12345
```

Or use `data` and Base64 encoded values

```yaml
...
data:
  api_key: MTIzNDU=
```

### Usage

- Mounted as files in a volume on containers inside Pod or Deployment
  - Automatically updates when secret value changes, no need to restart the Pod

- As env variables
  - Need to restart the Pod to get new secret values

  ```yaml
  env:
  - name: api_key
    valueFrom:
      secretKeyRef:
        name: apikey
        key: api_key
  ```

- Used by kubelet when pulling images from private registries via the `imagePullSecret` key in Pod specification

  - Create the secret

    - Use the Docker config.json file, which could contain multiple registry credentials

      ```sh
      kubectl create secret generic my-registry-key \
        --from-file=.dockerconfigjson=.docker/config.json \
        --type=kubernetes.io/dockerconfigjson
      ```

    - Another way for only one registry

      ```sh
      kubectl create secret docker-registry my-registry-key \
        --docker-server=https://registry.example.com \
        --docker-username=gary \
        --docker-password=xxxxxxx
      ```

  - Use the secret in pod template

    ```yaml
    spec:
      imagePullSecrets:
      - name: my-registry-key
      containers:
      - name: my-app
        image: registry.example.com/my-app:1.0
        imagePullPolicy: Always
        ...
    ```


## Jobs and cronjobs

- Jobs run a pod once, then stop, the logs are kept around

  ```yaml
  apiVersion: batch/v1
  kind: Job
  metadata:
    name: finalcountdown
  spec:
    template:
      metadata:
        name: finalcountdown
      spec:
        containers:
        - name: counter
          image: busybox
          command:
          - bin/sh
          - -c
          - "for i in 9 8 7 6 5 4 3 2 1 ; do echo $i ; done"
        restartPolicy: Never #could also be Always or OnFailure
  ```

- Cronjobs run periodically

  ```yaml
  apiVersion: batch/v1beta1
  kind: CronJob
  metadata:
    name: hellocron
  spec:
    schedule: "*/1 * * * *"  #Runs every minute (cron syntax) or @hourly.
    jobTemplate:
      spec:
        template:
          spec:
            containers:
            - name: hellocron
              image: busybox
              args:
              - /bin/sh
              - -c
              - date; echo Hello from your Kubernetes cluster
            restartPolicy: OnFailure #could also be Always or Never
    suspend: false #Set to true if you want to suspend in the future
  ```

  ```sh
  # get cronjobs
  kubectl get cronjobs

  # you could edit a cronjob, e.g. set 'suspend' to true to suspend it
  kubectl edit cronjobs\cronjobname
  ```

## DaemonSets

A DaemonSet ensures all nodes run a copy of a pod, could be used to run your logging and monitoring tools

You could use `nodeSelector` to target nodes with specific labels:

```yaml
...
nodeSelector:
  infra: "production"
...
```

## StatefulSet

For stateful applications thats stores data, such as databases

![statefulset storage](images/kubernetes_statefulset-storage.png)

- Replica pods are not identical, each one has a fixed id (such as `mysql-1`), when this pod restarts, it sticks with the same id, not a random one like in a deployment
- They are started in a fixed order, always start `mysql-0`, then `mysql-1`, and then `mysql-2`
- When deleting, pods get deleted in reverse order, `mysql-2` gets deleted first
- Each pod has a unique DNS endpoint, such as `mysql-0.service1`
- Better to use remote storages, and the data syncing need to be setup, such as the database master-slave syncing


## Probes

```yaml
spec:
  containers:
  - name: helloworld
    image: helloworld:latest

    ports:
    - containerPort: 80

    readinessProbe:
      initialDelaySeconds: 10
      initialDelaySeconds: 1
      httpGet:
        path: /
        port: 80

    livenessProbe:
      initialDelaySeconds: 10
      timeoutSeconds: 1
      httpGet:
        path: /
        port: 80
```

## Updates and Rollback

```sh
# update image of myContainer in myDeployment
kubectl set image deployment/myDeployment myContainer=garylirocks/helloworld:latest

# old replicaset replaced by a new set
kubectl get rs
# NAME                      DESIRED   CURRENT   READY   AGE
# myDeployment-668f5695cf   3         3         3       111s
# myDeployment-66db4977c8   0         0         0       5m6s

# show rollout history
kubectl rollout history deployment/myDeployment

# rollback
kubectl rollout undo deployment myDeployment
```

Trouble shooting

```sh
# inspect a pod
kubectl describe pod/myDeployment-66db4977c8-g79d7

# get logs
kubectl logs pod/myDeployment-66db4977c8-g79d7

# get into a container
kubectl exec -it pod/myDeployment-66db4977c8-g79d7 bash
```

## Helm

![Deploy with yaml files](images/kubernetes_deploy-with-yaml-files.svg)

Without Helm, you need to manage multiple hardcoded YAML files for each environment, this is cumbersome.

Helm allows you **to create templated YAML** script files to manage your application's deployment. These files allow you to specify all dependencies, configuration mapping, and secrets.

![Helm Components](images/kubernetes_helm-components.svg)

```sh
helm create my-app
ls -F1 my-app
# charts/
# Chart.yaml
# templates/
# values.yaml
```

- `Chart.yaml` manifest file, contains name, description, version, etc.
- `charts/` dependencies

Helm client implements a Go language-based template engine, which creates manifest files by combining the templates in `templates/` with values from `Chart.yaml` and `values.yaml`

![Helm chart processing](images/kubernetes_helm-chart-process.svg)

An example `Chart.yaml`

```yaml
apiVersion: v2
name: webapp
description: A Helm chart for Kubernetes

type: application

version: 0.1.0
appVersion: 1.0.0
```

An example `values.yaml` file:

```yaml
image:
  registry: <your-acr-name>
  name: webapp
  tag: latest
  pullPolicy: "Always"
```

An example template file, with `{{.Values.<property>}}` placeholders for every custom value

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  ...
spec:
  ...
  template:
    ...
    spec:
      containers:
        - name: webapp
          image: {{ .Values.image.registry }}/{{ .Values.image.name }}:{{ default "latest" .Values.image.tag }}
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          resources:
          ...
          ports:
            ...
```

- There are also *predefined* values you could reference, like `{{ .Release.Name }}`, `{{ .Release.IsInstall }}`
- You could reference `Chart.yaml` values as well, like `{{ .Chart.version }}`
- Values in `values.yaml` can be overridden by CLI `--set` option

### Helm repos

```sh
helm repo add azure-marketplace https://marketplace.azurecr.io/helm/v1/repo

helm repo list

# search charts
helm search repo aspnet
```

### Install Helm Chart

```sh
# test
helm install --debug --dry-run my-drone-webapp ./drone-webapp

# from a chart folder
#   my-drone-webapp: -> name of the release
helm install my-drone-webapp ./drone-webapp

# from a tar archive
helm install my-drone-webapp ./drone-webapp.tgz

# from a repo
helm install my-release azure-marketplace/aspnet-core
```

Set values

```sh
helm install --set replicaCount=5 aspnet-webapp azure-marketplace/aspnet-core
```

Helm sets some labels for each resources it creates, so you can get resources by using:

```sh
kubectl get all -l 'release=my-release'
```

## Prometheus

![Prometheus architecture](images/kubernetes_prometheus-architecture.png)

Installation:

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack
```

This creates a bunch of statefulset, deployments, demonset, configmaps, secrets, services and CRDs:

```sh
deployment.apps/prometheus-kube-prometheus-operator     # creates the prometheus and alertmanager statefulsets
deployment.apps/prometheus-grafana                      # a dependency, grafana
deployment.apps/prometheus-kube-state-metrics           # a dependency, scrapes K8s components

statefulset.apps/alertmanager-prometheus-kube-prometheus-alertmanager
statefulset.apps/prometheus-prometheus-kube-prometheus-prometheus     # prometheus server

daemonset.apps/prometheus-prometheus-node-exporter      # runs on every node, get nodes metrics (CPU, memory, etc)
```

Access Grafana

By default, all services are using the ClusterIP service type, you need to forward a grafana pod's port to your localhost:

```sh
kubectl port-forward prometheus-grafana-c8787f89b-26rsl 3000
```

## Minikube

For start a K8s cluster on localhost.

```sh
minikube start

kubectl create -f helloworld.yaml
# deployment.apps/helloworld created

kubectl get deployments
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# helloworld   1/1     1            1           15m

# expose a deployment as a new service
kubectl expose deployment helloworld --type NodePort

kubectl get service/helloworld
# NAME         TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
# helloworld   NodePort   10.100.95.14   <none>        80:31796/TCP   62s

# to get output in YAML format
kubectl get service/helloworld -o yaml

# show all resources in the cluster
kubectl get all

# open the service in browser
minikube service helloworld
```

### Addons

- List

  ```sh
  minikube addons list
  ```

- Enable dashboard

  ```sh
  # enable dashboard
  minikube addons enable dashboard
  minikube addons enable metrics-server

  # open dashboard
  minikube dashboard
  ```

- Use a custom image

  ```sh
  minikube addons enable efk --images="Kibana=kibana/kibana:5.6.2-custom"
  ```

### Minikube deepdive

[A Deep Dive Into 5 years of Minikube - Medya Ghazizadeh, Google - YouTube](https://www.youtube.com/watch?v=GHczvbzuVvc&t=926s)

![Minikube architecture](images/kubernetes_minikube-architecture.png)
![Minikube architecture 2](images/kubernetes_minikube-architecture-2.png)

- Hypervisor technology creates a Linux box, which is required to install K8s, it could be container based, VM based or no virtualization at all (bare-metal, SSH)

  ```sh
  # specify a driver, one of: virtualbox, vmwarefusion, kvm2, vmware, none, docker, podman, ssh
  minikube start --driver=kvm2
  ```

- Container runtime manages containers inside K8s (the driver and runtime can both be Docker)

  ```sh
  minikube start --container-runtime=containerd
  ```

- Other options to `minikube start`

  ```sh
  # K8s version
  minikube start --kubernetes-version='v1.2.3'

  # multi-node
  minikube start -n=2

  # start another cluster (called profile in minikube)
  minikube start -p p1

  # extra configs to components, which could be kubelet, kubeadm,
  #     apiserver, controller-manager, etcd, proxy, scheduler
  minikube start \
    --extra-config=apiserver.authorization-mode=RBAC \
    --extra-config=apiserver.oidc-issuer-url=https://example.com

  ```

  - `--addons=[]`: Enable addons. see `minikube addons list` for a list of valid addon names.
  - `--cni=''`: CNI plug-in to use. Valid options: auto, bridge, calico, cilium, flannel, kindnet, or path to a CNI manifest (default: auto)
  - `--cpus='2'`: Number of CPUs allocated to Kubernetes. Use "max" to use the maximum number of CPUs.
  - `--dns-domain='cluster.local'`: The cluster dns domain name used in the Kubernetes cluster
  - `--docker-env=[]`: Environment variables to pass to the Docker daemon. (format: key=value)
  - `--host-dns-resolver=true`: Enable host resolver for NAT DNS requests (virtualbox driver only)
  - `--image-repository=''`: Alternative image repository to pull docker images from. This can be used when you have limited access to gcr.io. Set it to "auto" to let minikube decide one for you. For Chinese mainland users, you may use local gcr.io mirrors such as registry.cn-hangzhou.aliyuncs.com/google_containers
  - `--memory=''`: Amount of RAM to allocate to Kubernetes (format: <number>[<unit>], where unit = b, k, m or g). Use "max" to use the maximum amount of memory.
  - `--mount=false`: This will start the mount daemon and automatically mount files into minikube.
  - `--mount-string='/home/gary`:/minikube-host': The argument to pass the minikube mount command on start.
  - `--namespace='default'`: The named space to activate after start
  - `--ports=[]`: List of ports that should be exposed (docker and podman driver only)
  - `--service-cluster-ip-range='10.96.0.0/12'`: The CIDR to be used for service cluster IPs.

### Tips

```sh
# copy file to minikube node (NOT container)
minikube cp a.txt /home/docker/b.txt

# specify the node
minikube cp a.txt node2:/home/docker/b.txt

# ======

# SSH into a cluster node
minikube ssh

# ======

# pause K8s (the apiserver, etc), but keep your apps running
#  useful to save CPU/battery life
minikube pause

# or use auto-pause addon
minikube addons enable auto-pause

# ======

# automated GCP auth: if your host has auth, your apps will be authenticated automatically
minikube addons enable gcp-auth

# =====

# connect to the docker daemon inside minikube
eval $(minikube docker-env)

# =====

# build images without docker, using buildkit inside minikube
minikube image build -t my-image .
```

## MicroK8s

MicroK8s is an option for deploying a single-node Kubernetes cluster as a single package to target workstations and IoT devices.

```sh
sudo snap install microk8s --classic

# check status
sudo microk8s.status --wait-ready

# enable add-ons
sudo microk8s.enable dns dashboard registry
```

MicroK8s provides a version of `kubectl`, you could also have another system-wide `kubectl` instance, you can use `snap alias` to alias `microk8s.kubectl` to `kubectl`

```sh
sudo snap alias microk8s.kubectl kubectl
```

```sh
# get nodes information
sudo kubectl get nodes -o wide

# get services info
sudo kubectl get services -o wide --all-namespaces

# NAMESPACE            NAME                        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE     SELECTOR
# default              kubernetes                  ClusterIP   10.152.183.1     <none>        443/TCP                  11m     <none>
# kube-system          kube-dns                    ClusterIP   10.152.183.10    <none>        53/UDP,53/TCP,9153/TCP   5m40s   k8s-app=kube-dns
# kube-system          metrics-server              ClusterIP   10.152.183.134   <none>        443/TCP                  5m32s   k8s-app=metrics-server
# kube-system          kubernetes-dashboard        ClusterIP   10.152.183.224   <none>        443/TCP                  5m26s   k8s-app=kubernetes-dashboard
# kube-system          dashboard-metrics-scraper   ClusterIP   10.152.183.196   <none>        8000/TCP                 5m26s   k8s-app=dashboard-metrics-scraper
# container-registry   registry                    NodePort    10.152.183.54    <none>        5000:32000/TCP           5m25s   app=registry
```

`kube-dns`, `registry`, `kubernetes-dashboard` are from the add-ons you installed, some other services are supporting services that were installed alongside

### Install a web server on a cluster

```sh
# create a deployment
sudo kubectl create deployment nginx --image=nginx

sudo kubectl get deployments
# NAME    READY   UP-TO-DATE   AVAILABLE   AGE
# nginx   1/1     1            1           99s

sudo kubectl get pods -o wide
# NAME                     READY   STATUS    RESTARTS   AGE     IP             NODE        NOMINATED NODE   READINESS GATES
# nginx-6799fc88d8-q95rd   1/1     Running   0          4m52s   10.1.251.136   gary-tpx1   <none>           <none>
```

You can now access the nginx server with the pod's IP `curl 10.1.251.136`

```sh
# scale the pod
sudo kubectl scale --replicas=3 deployments/nginx
# deployment.apps/nginx scaled

sudo kubectl get pods -o wide
# NAME                     READY   STATUS    RESTARTS   AGE   IP             NODE        NOMINATED NODE   READINESS GATES
# nginx-6799fc88d8-q95rd   1/1     Running   0          10m   10.1.251.136   gary-tpx1   <none>           <none>
# nginx-6799fc88d8-4wlgk   1/1     Running   0          46s   10.1.251.138   gary-tpx1   <none>           <none>
# nginx-6799fc88d8-26fpx   1/1     Running   0          46s   10.1.251.137   gary-tpx1   <none>           <none>
```
















