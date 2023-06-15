# Azure Databricks

- [Overview](#overview)
- [VNet injection](#vnet-injection)
- [Private link](#private-link)
  - [Standard deployment](#standard-deployment)
- [Secure cluster connectivity](#secure-cluster-connectivity)
- [Administration](#administration)
- [Data](#data)


## Overview

- Could be used on multiple clouds
- Run big data pipelines using both batch and real-time data
  - Batch data from Data Factory
  - Real-time data from Event Hub, IoT hub
- Train machine-learning models
- Uses Spark

Networking diagram:

![Networking diagram](images/azure_databricks-arch-diagram.png)

- Control plane in MSFT-managed subscription
- Data plane in a MSFT-managed VNet in customer subscription
  - It has MSFT managed NSG associated to subnets
- There's a managed resource group,
  - It contains:
    - DBFS(Databricks filesystem) storage account `dbstoragexxxxx`
    - A user-assigned managed identity `dbmanagedidentity`, this will be assigned to cluster node VMs
    - Cluster nodes(as VMs) you created in the workspace
    - The managed VNet if you are not using your own VNet
  - Databricks adds a Deny Assignment to the RG, so you can't change things, except adding PEP to the DBFS storage account


## VNet injection

- For the workspace VNet, instead of using a MSFT-managed one, you could use your custom VNet
- The vNet must have two subnets dedicated to `Microsoft.Databricks/workspaces`, subnets
  - a container subnet (private subnet)
  - a host subnet (public subnet)
  - the minimum size of each subnet is `/28`
  - each cluster node will have tow NICs, one in container subnet, one in host subnet
- Subnets cannot be shared across workspaces or with other Azure resources
- Azure Databricks auto-provision and manages some rules in the NSG for these two subnets, you can't delete or update these rules
  - Some rules have *VirtualNetwork* assigned as source and destination, this is because Azure does not have subnet-level service tag. All clusters are protected by a second layer of network policy internally, so cluster A cannot connect to Cluster B in the same/another workspace.
  - If you have Azure resources in another subnet you want to protect, add a Inbound *deny* rule
- You might need to configure UDRs for these two subnets, to route via `INTERNET` for following destinations:
  - `Azure Databricks`
  - Extended infrastructure IP (for standby Azure Databricks inferastructure to improve the stability of Databricks services)
  - `Azure SQL` (for Azure Databricks metastore)
  - `Azure Storage` (for artifact Blob storage and log Blob storage)
  - `Azure Event Hub` (for logging to Azure Event Hub)


## Private link

Requirements:
- Workspace must be on premium tier
- Workspace must use VNet injection (even for front-end-only connection)
- You create a separate subnet for PEPs (could be `/27`)

Connection types:

- **Front-end Private Link (user to control plane)**
  - Target sub-resource: `databricks_ui_api`
  - Between users and workspace (the control plane)
  - Used for connection to ADB web application, REST API, Databricks Connect API
  - Also used by JDBC/ODBC and PowerBI integrations
- **Back-end Private Link (data plane to control plane)**
  - Target sub-resource: `databricks_ui_api`
  - From the clusters to the secure cluster connectivity relay endpoint and REST API endpoint
  - **Secure cluster connectivity (SCC / No Public IP / NPIP) must be enabled**
  - *data plane* here refers to the Classic data plane, the compute layer of Azure Databricks, NOT serverless data plane that supports serverless SQL warehouses
- **Web auth private connections**
  - Target sub-resource: `browser_authentication`
  - The domain name for a region is like: `australiaeast.pl-auth.azuredatabricks.net`
    - There might be more than one if there are multiple Azure Databricks control plane instances in the same region, like `australiaeast-c2.pl-auth.azuredatabricks.net`
  - Special configuration for SSO login callbacks to the Azure Databricks web application.
  - Allows AAD to redirect users after login to the correct control plane instance
  - Not needed for REST API calls
  - Exactly one PEP needed for all workspaces in the same region which share one private DNS zone
  - Strongly recommended to create a separate ***private web auth workspace*** for this
    - This workspace exists just for this web auth PEP
    - Don't put any workload in it
    - Don't config it for user login
    - No need for connection from data plane to control plane
    - Don't delete it

Two types of deployment:

- Standard (recommended):
  - Two PEPs for the workspace
  - Back-end PEP in a separate subnet in the workspace VNet
  - Front-end PEP in a spearate VNet

- Simplified:
  - A single PEP for both front-end and back-end connections
  - The transit subnet in the workspace VNet
  - Can't be front-end only

### Standard deployment

![Standard deployment](images/azure_databricks-private-link-standard-deployment.png)

Objects:

![Standard deployment objects](images/azure_databricks-private-link-standard-deployment-objects.png)

- Create a separate *private web auth workspace* per region for SSO login
  - This workspace needs its own VNet for VNet injection (though you won't put anything in it), not shown in the diagram
  - Set a log to this workspace, so it won't be deleted
- You need two separate private DNS zones for the `databricks_ui_api` endpoint, one for backend, one for frontend


## Secure cluster connectivity

![Secure cluster connectivity](./images/azure_databricks-secure-cluster-connectivity.png)

- Also known as *No Public IP* or *NPIP*
- In ARM template, set `enableNoPublicIp` to `true`
- When enabled,
  - customer virtual networks have no open ports
  - Data plane (Databricks Runtime cluster) nodes have no public IP addresses
  - Both container and host subnets are private
- How
  - Each cluster initiates a connection to the control plane secure cluster connectivity relay during cluster creation, using port 443 (HTTPS), and a different IP than is used for web application and REST API
  - When control plane starts new Databricks Runtime jobs or performs other cluster management tasks, these requests are sent to the cluster through this tunnel
- All Azure Databricks network traffic between the data plane VNet and the Azure Databricks control plane goes across the *Microsoft network backbone*, not the public Internet. This is true even if secure cluster connectivity is disabled.

Scenarios:

- Managed VNet
  - Azure Databricks automatically creates a *NAT gateway* for outbound traffic to Azure backbone and public network.
  - This NAT gateway is associated with both subnets

- VNet injection, three options
  - Use an outbound/egress load balancer, its configuration is managed by Azure Databricks
  - Use an Azure NAT gateway
  - Use UDR, directly to the endpoints or through a firewall


## Administration

Two levels:

- Account level
  - At `https://accounts.azuredatabricks.net`
  - Manages:
    - Get SCIM user provisioning URL and token
    - Users and groups
    - IP access list
- Workspace level
  - At `https://adb-xxxxx.xx.azuredatabricks.net`
  - Manages:
    - Users and groups in workspace
    - Workspace settings, eg. Access control, Storage, Cluster, etc
    - SQL settings
    - SQL warehouse settings

Initial setup:

1. An AAD Global Admin user login to Azure Portal
1. Find the Databricks resource, click on "Launch Workspace"
1. This account will be set up as "Account admin", he can assign the "Account admin" role to another user


## Data

Hierarchy:

- Metastore
- Catalog
- Schema (databases)
- Tables/views