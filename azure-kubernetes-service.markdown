# Azure Kubernetes Service

- [Overview](#overview)
- [Resources](#resources)
  - [Private DNS zone](#private-dns-zone)
- [Node pools](#node-pools)
  - [Login to a node](#login-to-a-node)
- [Namespace](#namespace)
- [Authentication](#authentication)
  - [Use Entra ID](#use-entra-id)
  - [Use Kubernetes RBAC](#use-kubernetes-rbac)
  - [Use Azure RBAC](#use-azure-rbac)
- [Networking](#networking)
  - [Concepts](#concepts)
  - [Service types](#service-types)
  - [kubenet](#kubenet)
  - [API server access options](#api-server-access-options)
  - [`command invoke`](#command-invoke)
  - [Egress](#egress)
- [Application Gateway Ingress Controller (AGIC)](#application-gateway-ingress-controller-agic)
- [Application Gateway for Containers (AGWC)](#application-gateway-for-containers-agwc)
- [Add-ons](#add-ons)
- [Extensions](#extensions)
- [Open-source and third-party integrations](#open-source-and-third-party-integrations)
- [Azure Policy for AKS](#azure-policy-for-aks)
  - [Policy definitions](#policy-definitions)
  - [How it works](#how-it-works)
- [Monitoring](#monitoring)
  - [Agent](#agent)
- [Settings](#settings)

## Overview

- Master node in your cluster is free, you pay for node VMs, storage and networking resources
- If unspecified, the Azure service creation workflow creates a Kubernetes cluster using default configuration for scaling, authentication, networking and monitoring
- You can use either the standard Kubernetes command-line tools or Azure CLI to manage your deployments
- AKS allows you to integrate any Azure service offering and use it as part of an AKS cluster solution

![AKS workflow](images/azure_aks-workflow.png)

When you create an AKS cluster, you need to specify
- Node pool

  You specify the VM size, node pools use VMSS(virtual machine scale sets) as the underlying infrastructure
- Node count
- Automatic routing

  - A Kubernetes cluster blocks all external communications by default
  - You need to manually create an *ingress* with an exception that allows incoming client connections to that paticular service

![AKS node pool](images/azure_aks-node-pool-diagram.png)

```sh
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --node-count 2 \
    --enable-addons http_application_routing \
    --enable-managed-identity \
    --generate-ssh-keys \
    --node-vm-size Standard_B2s

# add an entry to `~/.kube/config`, so your local `kubectl` can access the cluster
az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP

kubectl get nodes
```

![AKS deployment](images/azure_aks-deployments-diagram.png)


## Resources

When you create an AKS cluster, Azure creates a resource group that contains cluster worker nodes and other supporing resources:

- Worker nodes
  - VMSS
- Networking
  - vNet
  - NSG
    - Only default rules
  - Route table
    - To same subnet `x.x.x.0/24`, next hop IP `x.x.x.4` ?
- Outbound connection (optional)
  - A public load balancer
    - One outbound rule (both TCP/UDP)
    - Backend pools - VMSS
    - NO LB or inbound NAT rules
  - A public IP for the LB
- Managed identities
  - `<aks-name>-agentpool` (for VMSS)
  - `omsagent-<aks-name>-agentpool` (for VMSS)
- Private cluster only
  - Private endpoint for the control plane
  - Private DNS zone (optional, could use an existing one)

### Private DNS zone

If you want to BYO DNS zone (`privatelink.<region>.azmk8s.io`), the cluster needs a user assigned identity, which needs the "Azure Private DNS Zone Contributor" role on the DNS zone.

![Private DNS Zone config](images/aks_private-dns-zone-hub-spoke.png)

*vNet link ("3" on the diagram) is not needed, since all DNS resolution goes through the hub vNet*


## Node pools

- System node pool
  - Host system pods that make up the control plane of your cluster
  - Every AKS cluster needs at least one system node pool with at least one node
  - Linux OS only
  - At most 30 pods on a single node
  - For production environments, a minimum of three nodes are recommended
- User node pool
  - Node count can be 0

You could scale Pods and nodes manually or automatically

- Manual scaling

  ```sh
  # add a node pool
  az aks nodepool add \
      --resource-group resourceGroup \
      --cluster-name aksCluster \
      --name gpunodepool \
      --node-count 1 \
      --node-vm-size Standard_NC6 \
      --no-wait

  # scale node count to 0
  az aks nodepool scale \
      --resource-group resourceGroup \
      --cluster-name aksCluster \
      --name gpunodepool \
      --node-count 0
  ```

- Automatic scaling

  ![AKS auto scaler](images/aks_autoscaler.png)

  Cluster Autoscaler scales nodes, Horizontal Pod Autoscaler scales pods on existing nodes

### Login to a node

For newer versions of Kubernetes with AAD authentication, you need the `kubelogin` plugin, to install:

```sh
az aks install-cli
```

Login to a node

```sh
# list nodes
kubectl get nodes

# SSH to a node by deploying a debug pod
kubectl debug node/aks-nodepool1-37663765-vmss000000 -it --image=mcr.microsoft.com/cbl-mariner/busybox:2.0
```


## Namespace

- Logical isolation boundary for workloads and resources
- For hostile multi-tenant workloads, you should use physically isolated clusters


## Authentication

There are several ways to implement authentication in AKS

### Use Entra ID

This centralizes the identity management layer

- You create Roles or ClusterRoles defining access permissions to resources
- Then bind the roles to Entra users or groups
- Authorization:
  - User authenticate with Entra, get an access token
  - User sends a request to AKS, such as `kubectl create pod`
  - AKS validates token with Entra and fetches user group memberships
  - AKS applies Kubernetes RBAC and cluster policies

### Use Kubernetes RBAC

// TODO

### Use Azure RBAC

// TODO


## Networking

### Concepts

- Cluster nodes are connected to a vNet
- **Kube-proxy**:
  - Runs on each node
- **Services**:
  - logically group a set of pods and provide network connectivity
  - there are multiple service types
- **Network policies**
  - enable security measures and filtering for network traffic in pods
- Network models
  - **kubenet** (basic)
    - network resources are typically created and configured along with AKS deployment
  - **Azure CNI** (advanced)
    - AKS cluster connected to exiting network resources and configs
    - Pods get IP from the cluster vNet

### Service types

- ClusterIP
  - Default type
  - Good for *internal-only* applications

  ![networking-cluster-ip](images/aks_networking-cluster-ip.png)

- NodePort
  - Access via node IP and port

  ![networking-node-port](images/aks_networking-node-port.png)

- LoadBalancer
  - Via an Azure LB, either internal or external
  - For HTTP traffic, another options is *Ingress Controller*

  ![networking-load-balancing](images/aks_networking-load-balancer.png)

### kubenet

![Kubenet overview](images/aks_kubenet-overview.png)

- Each node gets an IP in the subnet
- Each pod gets an IP from a different address space
- NAT configured so pods can reach resources on vNet
  - Source IP address of the traffic is translated to the node's primary IP
- Multiple clusters can't share a subnet
- Some features not supported:
  - Azure network policies, but Calico are supported
  - Windows node pools
  - Virtual nodes add-on
- Not for production workloads

### API server access options

This refers to the API server(control plane) of the cluster, the endpoint which `kubectl` talks with, NOT the worker nodes.

![AKS control plane access](images/aks_control-plane-access-options.drawio.svg)

- Public
  - The API server IP is different from the outbound public IP in the managed resource group

- Private
  - Can only be enabled at creation
  - CI/CD runners needs to be self-hosted, so they can access the PEP
  - Could have multiple private endpoints

- API integration and public IP
  - Public IP for public access, API Integration in AKS vNet for private access
  - A subnet in the AKS vNet dedicated to the API server, an internal load balancer will be deployed in this subnet

- API integration w/o public IP
  - Similar to private access, just the private endpoint replaced with an internal load balancer


| Modes                          | Public FQDN       | Private FQDN |
| ------------------------------ | ----------------- | ------------ |
| Public                         | Yes (public IP)   | No           |
| Private                        | Optional (PEP IP) | Yes (PEP IP) |
| vNet integration + public IP   | Yes (ILB IP)      | No ?         |
| vNet integration w/o public IP | Optional (ILB IP) | Yes (ILB IP) |

Notes:

- The API public FQDN is like `dnsprefix-<xxxx>.hcp.<region>.azmk8s.io`
  - Could be disabled when there is private access
- The API private FQDN is like `<ask-name>-xxxx.<guid>.privatelink.<region>.azmk8s.io`
  - When deploying using API server VNet integration, private FQDN suffix could be `private.<region>.azmk8s.io` or `<subzone>.private.<region>.azmk8s.io`
- When using private cluster, the public FQDN resolves to the private IP, via public DNS
- When using private FQDN, you need a private DNZ zone, connected to AKS vNet or a hub vNet

### `command invoke`

To access a private cluster, apart from connecting to the cluster vNet directly, via a private endpoint, another way is to use the `command invoke` feature.

- Connects through the Azure API without directly connecting to the cluster
- Allows you to invoke commands like `kubectl` and `helm`
- Used by the "Run command" feature in Azure Portal
- Permissions needed: `Microsoft.ContainerService/managedClusters/runcommand/action`, `Microsoft.ContainerService/managedclusters/commandResults/read`
- This creates a command pod in the cluster, the pod has `helm` and latest compatible version of `kubectl` for the cluster

Example:

```sh
az aks command invoke \
  --resource-group myResourceGroup \
  --name myPrivateCluster \
  --command "kubectl get pods -n kube-system"

# multiple commands
az aks command invoke \
  --resource-group myResourceGroup \
  --name myPrivateCluster \
  --command "helm repo add bitnami https://charts.bitnami.com/bitnami && helm repo update && helm install my-release bitnami/nginx"

# with all files in current directory
az aks command invoke \
  --resource-group myResourceGroup \
  --name myPrivateCluster \
  --command "kubectl apply -f deployment.yaml configmap.yaml -n default" \
  --file .
```

### Egress

A few options:

- Load balancer (via a outbound rule)
- Managed NAT gateway
- User defined routing
- User assigned NAT gateway


## Application Gateway Ingress Controller (AGIC)

AGIC is a Kubernetes application, it monitors the cluster to update Application Gateway whenever a new service is selected to be exposed to the outside world.

- Could be deployed via Helm or as an AKS add-on
  - As Add-on
    - Automatic updates and increased support
    - Only one add-on per AKS cluster, and each add-on can only target one AGW
  - Helm
    - Can have multiple AGIC per cluster
    - Other differences
- Does NOT support CNI Overlay
- **The AGW talks to pod directly, not via a K8s service.**



## Application Gateway for Containers (AGWC)

- A new type of Application Gateway, an evolution over AGIC

![AGW for Containers overview](./images/aks_agw-for-containers.png)

- A new data plane, and control plane with new set of ARM APIs, different from existing AGW
- ALB controller implements:
  - K8S Gateway API
  - K8S Ingress API
- Limitations:
  - Only supports Azure CNI networking (pods get IP from cluster vNet)
  - Will support Azure CNI Overlay ??
  - No support for kubenet

**AGWC** is a parent resource, it contains two child resources:
- Frontends
  - Each has a unique FQDN and a public IP (IP is managed by MS, not visible as a resource)
  - Private IP not supported
  - An AGWC can have multiple frontends
- Associations
  - A 1:1 mapping of an association resource to a delegated subnet
    - At least a /24 space for the subnet
    - The subnet must be delegated to `Microsoft.ServiceNetworking/trafficControllers`
    - This subnet typically would be in the AKS cluster vNet, but could be in another peered vNet as well
  - AGWC is designed for multiple associations, but currently limited to 1

**ALB Controller**

- Deployed in Kubernetes via Helm, consists of two running pods:
  - **alb-controller pod**, for propagating configs to AGWC
  - **alb-controller-bootstrap pod**, for management of CRDs (Custom Resource Definition)
- Watches Customer Resources and Resource configurations, eg: Ingress, Gateway and ApplicationLoadBalancer
- Uses AGWC configuration API to propagate configuration to AGWC
- If you use managed AGWC, the controller talks to ARM to create the AGWC, otherwise it doesn't need to talk to ARM
- Needs a user-assigned managed identity, with
  - the build-in RBAC role *AppGw for Containers Configuration Manager* on AKS managed cluster RG
  - `Microsoft.Network/virtualNetworks/subnets/join/action` permission over the AGWC associated subnet (eg. "Network Contributor")
- Create workload identity federation for the UAMI, so Azure trusts AKS OIDC issuer

Two **deployment strategies**:

- Bring your own (BYO)
  - AGWC, association and frontend resources deployed separately
  - When you create a new Gateway resource in Kubernetes, it references frontend resource you created prior
- Managed by ALB Controller
  - ALB controller in Kubernetes manages the lifecycle of AGWC
  - In Kubernetes,
    - When you create a new "ApplicationLoadBalancer" resource, ALB Controller provisions the AGWC and association resource in the AKS MC RG
    - When you create a new "Gateway" resource (or "Ingress"), ALB Controller provisions a new Frontend resource

Requests:

- AGWC adds three headers to the requests before sending it to the backend:
  - x-forwarded-for: client IP address(s)
  - x-forwarded-proto: http or https
  - x-request-id


## Add-ons

- Fully supported way to provide extra capabilities for AKS cluster. Installation, configuration, and lifecycle of addon-ons are managed on AKS.
- Use `az aks enable-addons` to install or manage
- Available add-ons
  - `ingress-appgw` Application Gateway Ingress Controller
  - `keda` event-driven autoscaling
  - `monitoring` container insights (the name is `omsagent`)
  - `azure-policy`
  - `azure-keyvault-secrets-provider`
  - `virtual-node`
  - `web_application_routing` a managed NGINX ingress controller


## Extensions

- Build on top of certain Helm charts
- Available extensions:
  - Dapr: portable, event-driven runtime
  - Azure Machine Learning
  - Flux (GitOps): cluster configuration and application deployment
  - Azure Container Storage: persistent volumes
  - Azure Backup for AKS
- Difference between add-ons and extensions
  - Add-ons: added as part of the AKS resource provider
  - Extensions: added as part of a separate resource provider


## Open-source and third-party integrations

- Helm, Prometheus, Grafana, Couchbase, OpenFaaS, Apache Spark, Istio, Linkerd, Consul


## Azure Policy for AKS

- Extends Gatekeeper v3, an admission controller webhook for Open Policy Agent (OPA)
- Enforcement and safeguards on cluster components: pods, containers, and namespaces
- Supports the following environments:
  - Azure Kubernetes Service (AKS): Azure Policy's Add-On for AKS
  - Azure Arc enabled Kubernetes: Azure Policy's Extension for Arc

### Policy definitions

- Use `Microsoft.Kubernetes.Data` resource provider mode
- Available effects: audit, deny, disabled, and mutate
- Built-in policies usually have a parameter for "Namespace exclusions", it's recommended to exclude: kube-system, gatekeeper-system, and azure-arc.

### How it works

- Checks with Azure Policy service for policy assignment to the cluster
- Deploy policy definitions into the cluster as
  - constraint template
  - or constraint custom resources
  - or mutation template resource
- Reports auditing and compliance details back to Azure Policy service
- *You need to open some ports for AKS to talk to Azure Policy endpoints*
- The add-on checks in with Azure Policy service for changes every 15 minutes
- Init containers may be included during policy evaluation


## Monitoring

![Data collected](images/azure_aks-monitoring-data-collection.png)

- **Managed Prometheus**
  - Collect cluster metrics
  - View them in Grafana dashboards
  - Could be enabled with `az aks create/update --enable-azure-monitor-metrics ...`
- **Container insights**
  - Collect logs from AKS and Arc-enabled Kubernetes clusters
  - Analyze with prebuild workbooks
  - Don't collect Kubernetes audit logs (use Diagnostic settings)
  - You can enable it with CLI `az aks enable-addons -a monitoring ...`

### Agent

- Both Managed Prometheus and Container insights rely on a containerized Azure Monitor Agent for Linux
- This agent is deployed and registered with the specified workspace during deployment
- When you enabled Container Insights
  - You can specify a workspace, otherwise a `DefaultAzureMonitorWorkspace-<mapped_region>` will be created (if not exists already) in `DefaultRG-<cluster_region>`
  - A DCR is created with the name (`MSCI-<cluster-region>-<cluster-name>`), which defines what data should be collected (options: Standard, Cost-optimized, Syslog, Custom, None)
- The Log Analytics workspace could be in another subscription in the same tenant, but usually needs to be in the **same region** (except a few regions)
- For Prometheus metrics collection, these resources are cerated:
  - DCR `MSPROM-<aksclusterregion>-<clustername>`
  - DCE `MSPROM-<aksclusterregion>-<clustername>`


## Settings

- Attach ACR to pull image (*assign AcrPull permission to AKS's managed identity*)

  ```sh
  az aks update \
    -n $AKS_CLUSTER_NAME \
    -g $AKS_RESOURCE_GROUP \
    --attach-acr $ACR_NAME
  ```
