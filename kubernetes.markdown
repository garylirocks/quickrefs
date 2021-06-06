# Kubernetes

- [Architecture](#architecture)
- [Pod](#pod)
  - [Pod deployment](#pod-deployment)
- [Networking](#networking)
  - [Kubernetes services](#kubernetes-services)
- [Storage](#storage)
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

![Kubernetes cluster](images/kubernetes_architecture.svg)

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

***Service** here is different from the term in Docker Swarm*

- Is a Kubernetes object that provides stable networking for pods
- Enables communication between nodes, pods and users of your app, both internal and external
- Gets assigned an IP address from a service cluster's IP range (e.g. 10.96.0.0/12), a DNS name and an IP port

Three types of services:

- **ClusterIP** the address assigned to a service makes the service availabel to a set of services inside the cluster
- **NodePort** 
- **LoadBalancer** you typically configure load balancers when you use cloud providers, in this case, traffic from the external load balancer is directed to the pods running your app

![service labels](images/kubernetes_service-with-selector.svg)

You set the selector label in a service definition to match the pod label defined in the pods' definition file

The service here `drone-front-end-service` will group only the pods that match the label `app: front-end-nginx`

## Storage

Kubernetes volume's lifetime matches the pod's lifetime, this means a volume outlives the containers that run in the pod.

- options to provision persistent storage with the use of *PersistentVolumes*
- request specific storage for pods by using *PersistentVolumeClaims*


## MicroK8s

MicroK8s is an option for deploying a single-node Kubernetes cluster as a single plackage to target workstations and IoT devices.

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
















