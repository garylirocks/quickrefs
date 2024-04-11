# Azure

- [Overview](#overview)
  - [Deployment model](#deployment-model)
  - [Service model](#service-model)
  - [Compute](#compute)
  - [Storage](#storage)
  - [Database services](#database-services)
  - [Networking](#networking)
  - [Big Data](#big-data)
  - [AI](#ai)
  - [IoT services](#iot-services)
  - [DevOps](#devops)
  - [Security](#security)
- [Azure Governance](#azure-governance)
  - [Azure AD](#azure-ad)
  - [Tenant](#tenant)
  - [Regions](#regions)
    - [Paired regions](#paired-regions)
  - [Availability Zones](#availability-zones)
  - [Management groups](#management-groups)
  - [Subscription](#subscription)
  - [Resource group](#resource-group)
  - [Tags](#tags)
  - [Locks](#locks)
  - [Azure Resource Manager (ARM)](#azure-resource-manager-arm)
  - [Management tools](#management-tools)
- [Azure Resource Graph](#azure-resource-graph)
  - [Sample KQL queries](#sample-kql-queries)
  - [`az graph query`](#az-graph-query)
- [Blueprints (To be deprecated)](#blueprints-to-be-deprecated)
- [Business Process Automation](#business-process-automation)

## Overview

### Deployment model

- Public cloud
- Private cloud: Azure Stack
- Hybrid cloud

### Service model

- IaaS
- PaaS
- SaaS

![shared management responsibility](images/azure_iaas-paas-saas-shared-responsibility.png)

### Compute

![Cloud computing approaches](images/azure-cloud_computings_types.png)

- Containers don't need a guest OS, they are more portable to than VMs;

Four types of compute resources:

- Virtual machines

  - IaaS
  - Total control over OS, software;
  - And you are responsible for updating the OS and softwares;

- Containers
  - Azure Container Instances
    - Run a container directly, you choose which docker image to run, specify CPU, memory requirements, etc
  - Azure Kubernetes Service
    - Automating and managing large number of containers and how they interact
- Azure App Service
  - PaaS
  - Designed to host enterprise-grade web-oriented applications
- Serverless computing

  - Azure Functions
    - Completely abstracts the underlying hosting environment
    - Response to an event - REST request, timer, or message form other Azure service
  - Azure Logic Apps (like Zapier)
    - Automate and orchestrate tasks, workflows;
    - Can connect to other services such as Salesforce, SAP, Oracel, etc;
  - Event Grid

    - For apps with event-based architectures, intelligent event routing using publish-subscribe model


### Storage

- Blob storage: unstructured data;
  - Serving images and documents directly to a browser;
  - Source for CDN;
  - Data backup and restore, disaster recovery, archiving;
  - Data for analysis;
- Tables: for structured, un-relational data;
- Data Lake storage: for analytics;
- Azure files

  - Can be mounted _concurrently_ by cloud or on-premise machines (e.g. store config files in a file share and access them from multiple VMs);
  - Use SMB protocol;
  - Can be shared anywhere in the world using a URL containing a shared access signature(SAS) token (which allows specific access to a private asset for a specific amount of time);

  ![azure files](images/azure_files.png)

- Azure Queue

  - store large amount of messages;
  - can be accessed from anywhere in the world;

  ![azure queue](images/azure_queue.png)

- Disk storage

  - Only for attaching to VM;
  - Can be standard or premium SSD/HDD;
  - Can be managed and configured either by Azure or the user;


### Database services

Fully managed PaaS services

- SQL Database: structured data;
  - based on Microsoft SQL Server
- SQL Data Warehouse
  - support OLAP solutions and SQL queries
  - does not support cross-database queries
- Cosmos DB: semi-structured data;
  - globally distributed
  - indexes every field by default

### Networking

- Azure Virtual Network
- Azure Load Balancer
- VPN Gateway
- Azure Application Gateway
- CDN

### Big Data

- Synapse Analytics
- HDInsight
- Data Lake Analytics

### AI

- Cognitive Services: Vision, Speech, Language, Knowledge, Search
- Machine Learning Service: develop train, test, deploy, manage, and track ML models

### IoT services

- **IoT Hub**: bi-directional messaging between application and devices
- **IoT Central**: builds on top of IoT Hub, adding
  - dashboard for reporting and management,
  - alerting,
  - and starter templates for common industry and usage scenarios
- **Azure Sphere**: end-to-end, highly secure solution that encompasses everything from hardware, OS on the device and secure messaging
  - Hardware: Azure Sphere micro-controller unit (MCU)
  - OS: customized Linux, handles communication with the security service, can run the vendor's software
  - Azure Sphere Security service (AS3): certificate-based authentication, pushes OS and software updates to the device

### DevOps

- DevOps Service: pipelines, private Git repos, automated and cloud-based load testing
- Lab Services: provision environment using reusable templates and artifacts, scale up load testing by provisioning multiple test agents and create pre-provisioned envs for training and demos

### Security

![Defense in depth strategy](./images/azure_defense-in-depth.png)

- _Perimeter_: DDoS protection
- _Network_: NSG
- _Compute_: access to VMs

Security posture (CIA):

- _Confidentiality_: principle of least privilege
- _Integrity_: at rest and in transit
- _Availability_: DoS attacks

## Azure Governance

![Azure AD, tenant, subscriptions](images/azure-ad_tenant_subscriptions.png)

### Azure AD

- Is about web-based authentication standards such as OpenID and OAuth;
- _Not_ the same as Windows AD;

### Tenant

- Azure AD is partitioned into separate _tenants_;
- A tenant is a dedicated, isolated instance of the Azure AD service;
- When you sign up for Azure with an email address that's not associated with an existing tenant, the sign-up process will create a tenant for you automatically;
- An email address can be associated with more than one tenant (and you can switch from one to another);
- Each tenant has an _account owner_;

### Regions

Why

- Bring applications closer to users
- Offer data residency, compliance and resiliency options
- A region contains at least one, but potentially multiple datacenters, which could be grouped into Availability Zones

Some resources/SKUs are available globally, some only in specific regions

  | Regional                             | Global                              |
  | ------------------------------------ | ----------------------------------- |
  | specific VM sizes, sotrage SKUs, etc | Azure AD, DNS, Traffic Manager, etc |

Latency
- Within a region: **2ms**
  - allows active-active architecture
  - this allows for synchronous read/write to multiple replicas of a DB
  - to guarantee the lowest possible latency, use **Proximity placement groups** to place compute resources (VMs, VM availability sets, VMSS) close to each other (within a zone)
- Between regions: **> 10ms**
  - DB operations need to by replicated asynchronously
  - usually use active-passive architecture

#### Paired regions

Each regions is paired with another region within the same geopolitical boundary, which provides some benefits:

  - Data residency
  - Physical isolation (> 300 miles apart)
  - Sequential updates
  - Recovery order: one region is prioritized out of every pair
  - Native Replication: some services have native replication to paired region: Storage Account(GRS, GRZS), Key Vault, Recovery Service Vault

### Availability Zones

![Availability Zones](images/azure-availability-zones.png)

Designed for high availability, each zone is made up of one or more datacenters equipped with independent power, cooling and networking.

Three types of Availability Zone support:

| **Zonal**                        | **Zone-redundant**                                                               | **Non-regional (Global)**                          |
| -------------------------------- | -------------------------------------------------------------------------------- | -------------------------------------------------- |
| Can be pinned to a specific zone | Data or underlying resources are replicated or spread across zones automatically | Always available, resilient to region-wide outages |
| VMs, managed disks, etc          | ZRS storage account, VMSS, AKS Node Pool, App Service Plan, etc                  | DNS, Traffic Manager, etc                          |

- *Standard Public IP could be zonal or zone-redundant, which also decides the zone support for Load Balancers and vNet Gateways*
- For VMSS/AKS Node Pool/App Service Plan, you would need at least two (ideally three) underlying instances to make them zone-redundant
- To help distribute workload evenly, zones are **assigned randomly** across subscription, so "Zone 1" in subscription A might **NOT** be "Zone 1" in subscription B


### Management groups

![Management groups](images/azure_management-groups.png)

- Management groups serve as containers that help you manage access, policy and compliance for multiple subscriptions, eg.
  - Apply a policy to limit regions available to subscriptions under a group
  - Create a RBAC assignment on a group
- Full resource ID is like `/providers/Microsoft.Management/managementGroups/{yourMgID}`
- All subscriptions and management groups are within a single hierarchy in each directory
- Each directory is given a **root management group**
  - it has the same id as the tenant
  - it could be used for global RBAC assignments and policies
  - new subscriptions and management groups are placed under it by default
  - everyone can see the root management group
  - no one is given any default access to it (Azure AD Global Administrator can elevate to gain access, then assign roles to others)
- Management groups supports Activity log (role/policy assignment events), could be sent to Log Analytics workspace via REST API
- Up to **six levels of depth**, excluding the tenant root group and subscription level

  ```sh
  # list management groups
  az account management-group list -otable

  # show details of a management group
  az account management-group show -n "mg-gary"
  ```

- Permissions:
  - By default, anyone can can create a new management group
    - There's a setting to make `Microsoft.Management/managementGroups/write` permission required for creating a new management group
  - A new management group will be placed under root MG by default
    - You DON'T need any role on the root management group to create a new management group
  - When you create a new management group, you will be assigned the "Owner" role over it automatically
  - Permissions you need to move a MG/Sub to another MG (see [this](https://learn.microsoft.com/en-us/azure/governance/management-groups/manage#moving-management-groups-and-subscriptions)):
    - MG/write and roleAssignment/write on the child MG/Sub (eg. Owner)
    - MG/write on the target parent MG (eg. Owner, Contributor, MG Contributor)
    - MG/write on the source parent MG (eg. Owner, Contributor, MG Contributor)
  - Exceptions:
    - No permissions needed on the root MG to move MG/sub to or from it
    - If your "Owner" role is inherited on the child MG/sub, you need "Owner" role on the new MG (otherwise you would loose your "Owner" role)

- Settings (only for root MG):
  - You need `Microsoft.Management/managementgroups/settings/write` on root MG to change settings
  - Two settings:
    - Choose a default MG for new subscriptions (default to root MG)
    - Whether you need `Microsoft.Management/managementGroups/write` permission to create a new MG (default "no", anyone can create a new MG)


### Subscription

Subscriptions are logical containers that serve as

- Units of management
- Scale: limits and quotas
- Billing boundaries

Can have different types:

- Enterprise Agreement
- Pay-as-You-Go

Things to consider:

- A dedicated shared services subscription: eg. common network resources (ExpressRoute, Virtual WAN)
- Scale limits: large specialized workloads like high-performance computing, IoT and SAP are all better suited to use separate subscriptions
- Network topologies: virtual networks can't be shared across subscriptions, you need to use virtual network peering or VPN

### Resource group

- A logical container for resources;
- All resources must be in one and only one group;
- Location:
  - A resource group has its own region, for storign metadata
  - Resources within a group can be in **any region**
- Groups can't be nested;
- **Cannot be renamed**;
- Resources can be moved between groups;

You can organize resource groups in different ways:

- By resource type(vm, db)
- By app
- By department(hr, marketing)
- By environment (prod, qa, dev)
- By life cycle

  When you delete a group, all resources within are deleted, if you just want to try out something, put all new resources in one group, and then everything can be deleted together;

- By access: A group can be a scope for applying role-based access control (RBAC), and locks
- By billing: Can be used to filter and sort costs in billing reports


### Tags

Another way to organize resources

- Can be assigned to subscriptions, resource groups and resources
- **NOT** all types of resources support tags
- There are limitations on number of tags for each resource, lengths of tag name and value;
- Tags are not inherited;
- Can be used to automate task, such as adding `shutdown:6PM` and `startup:7AM` to virtual machines, then create an automation job that accomplish tasks based on tags;
- Consider using Azure policy to apply tags and enforce tagging rules and conventions

### Locks

A setting that can by applied to any resource to block inadvertent modification or deletion.

- Two types: **Delete** or **Read-only**
- Can be applied at different levels: subscriptions, resource groups, and individual resources
- Are inherited from higher levels;
- Apply regardless of RBAC permissions, even you are the owner, you still need to remove the lock before deleting a resource;

### Azure Resource Manager (ARM)

![Resource manager](images/azure_resource-manager.png)

Azure Resource Manager (ARM) is the management layer which allows you automate the deployment and configuration of resources;

### Management tools

- Azure Portal: Web based, not suitable for repetitive tasks
- [Azure PowerShell](./azure-powershell.markdown)
- [Azure CLI](./azure-cli.markdown)
- Cloud Shell
  - You can choose to use either CLI or PowerShell
  - A storage account is required
- Azure Mobile App
- Azure Rest API
- Azure SDKs
  - SDKs are based on Rest API, but are easier to use


## Azure Resource Graph

- A readonly database of metadata of all your Azure resource
  - Exposes a separate endpoint other than ARM
  - Faster than ARM, does not need to send query to resource providers
  - Gets updated when you update a resource
- Query resources with complex filtering, grouping, and sorting by resource properties
- Change tracking (in last 14 days)
- Assess the impact of applying policies in a vast environment

Compare with Azure Resource Manager

|                      | Resource Manager                                       | Resource Graph                               |
| -------------------- | ------------------------------------------------------ | -------------------------------------------- |
| Supported properties | name, id, type, resource group, subscription, location | all properties by resource providers         |
| CLI command          | `az resource list`                                     | `az graph query`                             |
| Scope                | one subscription                                       | a list of subscriptions or management groups |
| Query syntax         | -                                                      | KQL                                          |
| Quota                | 12000 per hour ?                                       | 15 per 5 seconds ?                           |


Tables:

- **`Resources`**: default table if not specified
- **`ResourceContainers`**: management group, subscription, and resource group
- **`SecurityResources`**: resources related to `Microsoft.Security`
- ...


### Sample KQL queries

- List top 5 resources ordered by name

  ```kusto
  resources
  | project name, type
  | top 5 by name asc
  ```

- `securityresources` table, find enabled Defender plans

  ```kusto
  securityresources
  | where type == "microsoft.security/pricings"
  | where properties['pricingTier'] == "Standard"
  ```

- `resourcechanges` table

  ```kusto
  resourcechanges
  | extend changeTime=todatetime(properties.changeAttributes.timestamp)
  | project changeTime, properties.changeType, properties.targetResourceId, properties.targetResourceType, properties.changes
  | top 5 by changeTime desc
  ```

- A query can be saved as a shared query, then you could call it like:

  ```kusto
  {{/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-gary-001/providers/microsoft.resourcegraph/queries/my-share-query-001}}
  | project id, name, type
  ```

- Join with `resourcecontainers` to get subscription name

  ```kusto
  // get subscription name
  Resources
  | where type == "microsoft.storage/storageaccounts"
  | join (
      resourcecontainers
      | where type == "microsoft.resources/subscriptions"
      | project subName = name, subscriptionId
      )
      on subscriptionId
  | project name, subName
  ```

- Find storage accounts with public network access

  ```kusto
  Resources
  | where type =~ 'microsoft.storage/storageaccounts'
  | where properties.publicNetworkAccess == 'Enabled' or isnull(properties.publicNetworkAccess)
  | where properties.networkAcls.defaultAction == "Allow"
  | where subscriptionId !in ('xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx')
  | project name, type, subscriptionId
  | sort by subscriptionId
  ```

  The above query is similar to the following CLI command (*it only queries one subscription*):

  ```sh
  az storage account list \
    --query "[? publicNetworkAccess=='Enabled' && networkRuleSet.defaultAction=='Allow'].{Name: name, ID: id}"
  ```

- Find storage accounts with private endpoints

  ```kusto
  // "join" twice to get tags on resource group and subscription name
  resources
  | where type == "microsoft.storage/storageaccounts"
  | where array_length(properties['privateEndpointConnections']) > 0
  | join kind=leftouter (
      resourcecontainers
      | where type =~ "microsoft.resources/subscriptions/resourcegroups"
      | project rgTags = tags, resourceGroup
      )
      on resourceGroup
  | join kind=leftouter (
    resourcecontainers
    | where type == "microsoft.resources/subscriptions"
    | project subName = name, subscriptionId
    )
    on subscriptionId
  | project name, resourceGroup, subName, tags, rgTags
  ```

- Find storage account network access settings, with allowed subnets, allowed IPs, count of private endpoints, etc

  Utilizes `mv-expand`, `split()`, `make_list()` to extract the subnet IDs and IPs

  ```kusto
  // seems this Explorer does not support `as`, `mv-apply`, `let`, otherwise the query below would be simpler
  resources
  | where type == "microsoft.storage/storageaccounts"
  | where subscriptionId == "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  | project id, name, type, kind, location, resourceGroup,
      vNetRules = properties.networkAcls.virtualNetworkRules,
      ipRules = properties.networkAcls.ipRules,
      PEPCount=iff(isnull(properties.privateEndpointConnections), 0, array_length(properties.privateEndpointConnections)),
      PublicAccess=iff(
          properties.networkAcls.defaultAction=="Allow",
          "All",
          iff(
              properties.publicNetworkAccess!="Disabled",
              "Limited",
              "No"
          )
      )
  | mv-expand subnet=iff(array_length(vNetRules) > 0, vNetRules, dynamic(null))
  | extend subnetID = iff(array_length(split(subnet.id, "/")) > 8, strcat((split(subnet.id, "/"))[8], '/', (split(subnet.id, "/")[10])), "")
  | summarize make_list_if(subnetID, strlen(subnetID) > 0) by id, name, kind, location, resourceGroup, PEPCount, PublicAccess
  | join (
      resources
      | where type == "microsoft.storage/storageaccounts"
      | where subscriptionId == "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      | project id, ipRules = properties.networkAcls.ipRules
      | mv-expand ipRule=iff(array_length(ipRules) > 0, ipRules, dynamic(null))
      | extend IP = ipRule.value
      | summarize make_list(IP) by id
  ) on id
  | extend
      c_subnets = array_length(list_subnetID),
      c_IPs = array_length(list_IP),
      subnetIDs = iff(array_length(list_subnetID) > 0, list_subnetID, dynamic(null)),
      IPs = iff(array_length(list_IP) > 0, list_IP, dynamic(null))
  | project id, name, PublicAccess, c_subnets, c_IPs, PEPCount, subnetIDs, IPs, kind, location, resourceGroup
  | sort by PublicAccess, array_length(subnetIDs)
  ```

### `az graph query`

```sh
# get VM name and tags
az graph query \
  --graph-query "where type =~ "Microsoft.Compute" | project name, tags" \
  --subscriptions "11111111-1111-1111-1111-111111111111 22222222-2222-2222-2222-222222222222" \
  --first 1000 \
  --query "data" \
  -otsv

# use a saved query
queryId="/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg-gary-001/providers/microsoft.resourcegraph/queries/my-share-query-001"
subId="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

az graph query \
  --graph-query "{{${queryId}}} | project id, name, type" \
  --subscriptions "${subId}" \
  --query "data" \
  -otsv
```

- No need to specify the `resources` table, which is always used
- Use `--first` to specify how many records to return
- Optionally specify the subscriptions, otherwise all available ones are queried


## Blueprints (To be deprecated)

*This is going to be deprecated, Microsoft suggests migrating to Template Specs and Deployment Stacks*

Contains some artifacts that could be deployed to existing or new subscriptions:

- Role assignments
- Policy assignments
- Resource groups
- ARM templates

![Blueprint artifacts example](images/azure_blueprint-artifacts-example.png)

Notes:

- Blueprints are versioned
- The relationship between the blueprint definition and assignment (the deployed resources) is preserved, helping you track and audit your deployments
- Can be assigned at management group or subscription level
  - If assigned at a **management group** level, it would deploy to **existing and new** subscriptions under the group
- Resource deployed by blueprints are **locked**
  - When you un-assign a blueprint, the resource locking is removed, resources and RBAC assignments do not change
  - A subscription owner can't remove the lock, but can un-assign the blueprint if it's assigned at the subscription level


## Business Process Automation

- Design-first

  - Power Automate
    - No code required
    - Use Logic Apps under the hood
  - Logic Apps
    - Low-code / no-code
    - Has pre-built connectors to well-known services
    - Best for orchestrating multiple systems

- Code-first
  - Functions (_this should be default choice_)
    - Wider range of triggers / supported languages
    - Pay-per-use price model
  - App Service WebJobs
    - Part of App Service
    - Customization to `JobHost`
