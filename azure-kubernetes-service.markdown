# Azure Kubernetes Service

- [Overview](#overview)
- [Resources](#resources)
  - [Private DNS zone](#private-dns-zone)
- [Node pools](#node-pools)
- [Authentication](#authentication)
- [Networking](#networking)
  - [kubenet](#kubenet)
  - [API server access options](#api-server-access-options)
  - [`command invoke`](#command-invoke)
  - [Egress](#egress)
- [Application Gateway Ingress Controller](#application-gateway-ingress-controller)
- [Add-ons](#add-ons)
- [Extensions](#extensions)
- [Open-source and third-party integrations](#open-source-and-third-party-integrations)
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


## Authentication

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


## Networking

AKS clusters can use kubenet (basic networking) or Azure CNI (advanced networking)

### kubenet

![Kubenet overview](images/aks_kubenet-overview.png)

- Only nodes receive an IP in the subnet
- Pods can't communicated directly with each other
- AKS creates and maintains UDR and IP forwarding, which is used for connectivity between pods across nodes
- Multiple kubenet clusters can't share a subnet
- Some features not supported:
  - Azure network policies, but Calico are supported
  - Windows node pools
  - Virtual nodes add-on

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


## Application Gateway Ingress Controller

AGIC is a Kubernetes application, it monitors the cluster to update Application Gateway whenever a new service is selected to be exposed to the outside world.


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
