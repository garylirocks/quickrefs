# Azure Kubernetes Service

## Overview

- Master node in your cluster is free, you pay for node VMs, storage and networking resources
- If unspecified, the Azure service creation workflow creates a Kubernetes cluster using default configuration for scaling, authentication, networking and monitoring
- You can use either the standard Kubernetes command-line tools or Azure CLI to manage your deployments
- AKS allows you to integrate any Azure service offering and use it as part of an AKS cluster solution

![AKS workflow](images/azure_aks-workflow.png)

When you create an AKS cluster, you need to specify
- Node pool

  You specify the VM size, node pools use virtual machine scale sets as the underlying infrastructure
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