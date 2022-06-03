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
  - [Management groups](#management-groups)
  - [Subscription](#subscription)
  - [Resource group](#resource-group)
  - [Tags](#tags)
  - [Locks](#locks)
  - [Azure Resource Manager (ARM)](#azure-resource-manager-arm)
  - [Management tools](#management-tools)
- [Policy](#policy)
  - [Assignment](#assignment)
  - [Effects](#effects)
  - [Order of evaluation](#order-of-evaluation)
- [Blueprints](#blueprints)
- [Azure Cloud Adoption Framework](#azure-cloud-adoption-framework)
- [Business Process Automation](#business-process-automation)
- [API Management](#api-management)
  - [Policies](#policies)
  - [Client certificates](#client-certificates)
- [Messaging platforms](#messaging-platforms)
  - [Messages vs. Events](#messages-vs-events)
  - [Service bus](#service-bus)
  - [Storage Queues](#storage-queues)
  - [Event Grid](#event-grid)
  - [Event Hub](#event-hub)

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

- Bring applications closer to users
- Offer data residency, compliance and resiliency options
- A region contains at least one, but potentially multiple datacenters (Availability Zones)
- Some services or features are only available in certain regions: such as specific VM sizes or storage types
- Some services are global: Azure AD, DNS, Traffic Manager
- Each regions is paired with another region within the same geography, making a **regional pair**
  - Physical isolation
  - Replication: Geo-Redundant Storage provide automatic replication to the paired region
  - Recovery order: one region is prioritized out of every pair
  - Sequential updates
  - Data residency


### Management groups

![Management groups](images/azure_management-groups.png)

- Management groups serve as containers that help you manage access, policy and compliance for multiple subscriptions, eg.
  - Apply a policy to limit regions available to subscriptions under a group
  - Create a RBAC assignment on a group
- All subscriptions and management groups are within a single hierarchy in each directory
- Each directory is given a root management group, it has the same id as the tenant, it could be used for global RBAC assignments and policies
- Up to six levels of depth, excluding the tenant root group

```sh
# list management groups
az account management-group list -otable

# show details of a management group
az account management-group show -n "mg-gary"
```

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


## Policy

- Policies apply and enforce rules your resources need to follow, such as:

  - only allow specific types of resources to be created;
  - only allow resources in specific regions;
  - enforce naming conventions;
  - specific tags are applied;

- A group of policies is called an **initiative**, it's recommended to use initiatives even when there's only a few policies
- Some Azure Policy resources, such as policy definitions, initiative definitions, and assignments are visible to all users.

### Assignment

Scopes:

| Definition scopes | Assignment scopes                                          |
| ----------------- | ---------------------------------------------------------- |
| management group  | children management groups, subscriptions, resource groups |
| subscription      | subscriptions, resource groups                             |

### Effects

An assignment could have one of the following effects:

- **Append**:
  - create/update: add additional fields to the requested resource, eg. allowed IPs for a storage account
  - existing: no changes, mark the resource as non-compliant
- **Audit**:
  - create/update: add a warning event in the activity log
  - existing: compliance status on the resource is updated
- **Deny**:
  - create/update: prevent the resources from being created
  - existing: mark as non-compliant
- **Disabled**
- **AuditIfNotExists**
  - Runs after Resource Provider has handled a create/update resource request and has returned a success status code.
  - The audit occurs if there are no related resources(defined by `then.details`) or if the related resources don't satisfy `then.details.ExistenceCondition`.
  - The resource defined in **if** condition is marked as non-compliant.
  - Example (audit if no Antimalware extension on a VM):
    ```json
    {
        "if": {
            "field": "type",
            "equals": "Microsoft.Compute/virtualMachines"
        },
        "then": {
            "effect": "auditIfNotExists",
            "details": {
                "type": "Microsoft.Compute/virtualMachines/extensions",
                "existenceCondition": {
                    "allOf": [
                        {
                            "field": "Microsoft.Compute/virtualMachines/extensions/publisher",
                            "equals": "Microsoft.Azure.Security"
                        },
                        {
                            "field": "Microsoft.Compute/virtualMachines/extensions/type",
                            "equals": "IaaSAntimalware"
                        }
                    ]
                }
            }
        }
    }
    ```

- **DeployIfNotExists**
- **Modify**

Evaluation times or events:

- A resource is created or updated
- A new assignment created
- A policy or initiative already assigned to a scope is updated
- Standard compliance evaluation cycle, once every 24 hours

### Order of evaluation

When a request to create or update a resource comes in, Azure Policy creates a list of all assignments that apply to the resource.

Azure Policy evaluate policies in an order determined by policy effects:

- **Disabled**: checked first
- **Append** and **Modify**, they could alter the request
- **Deny**
- **Audit**
- *sends request to Resource Provider (during creation/update)*
- *Resource Provider returns a success code*
- **AuditIfNotExists** and **DeployIfNotExists**: evalute to determine whether additional logging or action is required.


## Blueprints

Contains some artifacts that could be deployed to existing or new subscriptions:

- Role assignments
- Policy assignments
- Resource groups
- ARM templates

![Blueprint artifacts example](images/azure_blueprint-artifacts-example.png)

Notes:

- Blueprints are versioned
- The relationship between the blueprint definition and assignment (the deployed resources) is preserved, helping you track and audit your deployments
- You assign a blueprint to a **management group**, it would deploy to existing and new subscriptions under the group


## Azure Cloud Adoption Framework

Cloud Adoption Framework consists of tools, documentation, and proven practices. It has five stages:

1. Define your strategy
    1. Motivation
    1. Goals
    1. Financial considerations
    1. Technical considerations
2. Make a plan.
    1. What digital estate to migrate
    1. Who needs to be involved
    1. Skills readiness
    1. A plan that brings together development, operations and business teams
3. Ready your organization: create a landing zone
4. Adopt the cloud: migrate and innovate
5. Govern and manage your cloud environments.


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

## API Management

- You can import APIs defined in Open API, WSDL, WADL, Azure Functions, API app, ...
- Each API consists of one or more operations
- APIs can be grouped in to Product, which is a scope for policies and subscriptions (*this is API subscription, not your Azure subscription*)
- You can use subscription keys to restrict access to the API, a key can be scoped to
  - all APIs
  - a Product
  - a specific API

Call an API with a subscription key:

```sh
curl --header "Ocp-Apim-Subscription-Key: <my-subscription-key>" https://myApiName.azure-api.net/api/cars

# or as a query parameter
curl https://myApiName.azure-api.net/api/path?subscription-key=<key string>
```
### Policies

- You can add policies to APIs to:
  - cache responses (either internal cache or external Redis cache)
  - transform documents and values (e.g JSON to XML)
  - set limits (rate limit by client IP or subscription key)
  - enforce security requirements
  - call webhooks for notification or audit
- Policies can be applied at four scoped:
  - All
  - Product
  - API
  - Operation

- Policies are defined as XML documents, example:

```xml
<policies>
    <inbound>
        <base />
        <check-header name="Authorization" failed-check-httpcode="401" failed-check-error-message="Not authorized" ignore-case="false">
        </check-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
        <json-to-xml apply="always" consider-accept-header="false" parse-date="false" />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
```

*`<base />` specifies when to run upper-level policies*

### Client certificates

You can configure an **inbound policy** to only allow clients passing trusted certificates.

You can check the following certificate properties:

- Certificate Authority (CA)
- Thumbprint
- Subject
- Expiration date

Ways to verify a certificate:

- Check if it's issued by a trusted CA (you can configure trusted CA in Azure)
- Self-issued certificate (check you know this certificate)

```sh
# generate certificate
pwd='Pa$$w0rd'
pfxFilePath='selfsigncert.pfx'
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -keyout privateKey.key -out selfsigncert.crt -subj /CN=localhost

# convert certificate to PEM format for curl
openssl pkcs12 -export -out $pfxFilePath -inkey privateKey.key -in selfsigncert.crt -password pass:$pwd
openssl pkcs12 -in selfsigncert.pfx -out selfsigncert.pem -nodes

# get fingerprint
Fingerprint="$(openssl x509 -in selfsigncert.pem -noout -fingerprint)"
Fingerprint="${Fingerprint//:}"
echo ${Fingerprint#*=}
```

Add an inbound policy, which checks thumbprint of the certificate

```xml
<inbound>
    <choose>
        <when condition="@(context.Request.Certificate == null || context.Request.Certificate.Thumbprint != "desired-thumbprint")" >
            <return-response>
                <set-status code="403" reason="Invalid client certificate" />
            </return-response>
        </when>
    </choose>
    <base />
</inbound>
```

Call API with both a subscription key and a certificate:

```sh
curl -X GET https://myApiName.azure-api.net/api/Weather/53/-1 \
  -H 'Ocp-Apim-Subscription-Key: [subscription-key]' \
  --cert-type pem \
  --cert selfsigncert.pem
```


## Messaging platforms

### Messages vs. Events

Messages:
  - Generally contains the raw data itself (e.g. raw file data to be stored)
  - Sender and receiver are often coupled by a strict data contract
  - Overall integrity of the application rely on messages being received

Events:
  - Lightweight notification of a condition or a state change
  - Usually have meta data of the event but not the data that triggered the event (e.g. a file was created, but not the actual file data)
  - Most often used for broadcast communications, have a large number of subscribers for each publisher
  - Publisher has no expectation about how the event is handled
  - Can be discrete or part of series

| Service     | Type                          | Purpose                             | When to use                              |
| ----------- | ----------------------------- | ----------------------------------- | ---------------------------------------- |
| Service Bus | Message                       | **High-value enterprise** messaging | Order processing, financial transactions |
| Event Grid  | Event distribution (discrete) | Reactive programming                | React to status change                   |
| Event Hubs  | Event streaming (series)      | Big data pipeline                   | Telemetry and distributed data streaming |

### Service bus

- Intended for traditional enterprise applications, which require transactions, ordering, duplicate detection, and instantaneous consistency.

- Is a brokered messaging system, stores messages in a "broker" (e.g. a queue) until the consuming party is ready.


Queue:

![Service Bus Queue](./images/azure_service-bus-queue.png)

Storage queues are simpler to use but less sophisticated and flexible than Service Bus queues:

| Feature                          | Service Bus Queues                   | Storage Queues |
| -------------------------------- | ------------------------------------ | -------------- |
| Message size                     | 256KB(std tier) / 1MB (premium tier) | 64KB           |
| Queue size                       | 80 GB                                | unlimited      |
| Delivery                         | at-least-once or at-most-once        | -              |
| Guarantee                        | FIFO guarantee                       | -              |
| Transaction                      | Yes                                  | No             |
| Role-based security              | Yes                                  | No             |
| Queue polling on destination end | Not required                         | -              |
| Log                              | -                                    | Yes            |



Topic (supports multiple receivers):

![Service Bus Topic](./images/azure_service-bus-topic.png)


Three filter conditions:

- Boolean filters
- SQL filters: use SQL-like conditional expressions
- Correlation Filters: matches against messages properties, more efficient than SQL filters

All filters evaluate message properties, not message body.


### Storage Queues

![storage queue message flow](images/azure_storage-queue-message-flow.png)

- `get` and `delete` are separate operations, this ensures the *at-least-once delivery*, in case there is a failure in the receiver, after receiver gets a message, the message remains in the queue but is invisible for 30 seconds, after that if not deleted, it becomes visible again and another instance of the receive can process it

### Event Grid


### Event Hub

Often used for a specific type of high-flow stream of communications used for analytics (often used with Stream Analytics)
