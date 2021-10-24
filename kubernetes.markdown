# Kubernetes

- [Architecture](#architecture)
- [Pod](#pod)
  - [Pod deployment](#pod-deployment)
- [Networking](#networking)
  - [Kubernetes services](#kubernetes-services)
  - [Ingress](#ingress)
- [Storage](#storage)
- [Manifest files](#manifest-files)
- [Labels](#labels)
- [Configs](#configs)
- [Secrets](#secrets)
- [Probes](#probes)
- [Updates and Rollback](#updates-and-rollback)
- [Helm](#helm)
  - [Helm repos](#helm-repos)
  - [Install Helm Chart](#install-helm-chart)
- [Minikube](#minikube)
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
- **NodePort** exposes the service externally, assigns each node a static port that responds to that service. When accessed through `nodeIp:port`, the node automatically redirects the request to an internal service of the `ClusterIP` type
- **LoadBalancer** you typically configure load balancers when you use cloud providers (eg. Azure Load Balancer), automatically creates a `NodePort` service to which the load balancer's traffic is redirected and a `ClusterIP` service to forward internally

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

### Ingress

Ingress exposes routes for HTTP and HTTPS traffic from outside a cluster to services inside the cluster.

So the traffic goes like this: Ingress -> service -> pod

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

Kubernetes volume's lifetime matches the pod's lifetime, this means a volume outlives the containers that run in the pod.

- options to provision persistent storage with the use of *PersistentVolumes*
- request specific storage for pods by using *PersistentVolumeClaims*


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

This is how you reference a config as an env variable:

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

## Secrets

```sh
kubectl create secret generic apikey --from-literal=api_key=12345
# secret/apikey created

kubectl get secrets
# NAME        TYPE         DATA   AGE
# apikey      Opaque       1      7s

kubectl get secret apikey -o yaml
# apiVersion: v1
# data:
#   api_key: MTIzNDU=
# kind: Secret
# metadata:
#   ...
# type: Opaque
```

To reference a secret key

```yaml
env:
- name: api_key
  valueFrom:
    secretKeyRef:
      name: apikey
      key: api_key
```



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

Helm client implements a Go language-based template engine, which creates manifest files by combining the templates in `templates/` with values from `chart.yaml` and `values.yaml`

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
          image: {{ .Values.registry }}/webapp:{{ .Values.dockerTag }}
          imagePullPolicy: {{ .Values.pullPolicy }}
          resources:
          ...
          ports:
            ...
```

An example `values.yaml` file:

```yaml
apiVersion: v2
name: webapp
description: A Helm chart for Kubernetes
...
registry: "my-acr-registry.azurecr.io"
dockerTag: "linux-v1"
pullPolicy: "Always"
```

There are also *predefined* values you could reference, like `{{.Release.Name}}`, `{{.Release.IsInstall}}`

You could reference `Chart.yaml` values as well, like `{{.Chart.version}}`


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

Addons

```sh
minikube addons list

# enable dashboard
minikube addons enable dashboard
minikube addons enable metrics-server

# open dashboard
minikube dashboard
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
















