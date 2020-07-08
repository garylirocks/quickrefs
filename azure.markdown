# Azure

[[toc]]

## Azure AD, tenant, subscriptions

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

### Subscription

- A tenant can have multiple subscriptions;
- Billing is done monthly at subscription level;

## Concepts

### Resource group

- Resources in one group can span multiple regions;
- When you delete a group, all resources within are deleted, if you just want to try out something, put all new resources in one group, and then everything can be deleted together;
- A group can be a scope for applying role-based access control (RBAC);
- Can be used to filter and sort costs in billing reports;
- Resource Group Manager (RGM) is the management layer which allows you automate the deployment and configuration of resources;

You can organize resource groups in different ways: by resource type(vm, db), by department(hr, marketing), by environment (prod, qa, dev), etc

## Cloud computing fundamentals

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
- Serverless computing (Azure Functions)
  - Completely abstracts the underlying hosting environment

#### VMs

Scaling VMs:

- Availability sets

  - logical grouping of VMs across multiple Fault Domains (separate server racks) or Update Domains (logical part of a data center);

  ![Availability Set](images/azure-vm_availability_sets.png)

- Virtual Machine Scale Sets

  - let you create and manage a group of identical, load balanced VMs;
  - number of instances can automatically increase or decrease in response to demand or a defined schedule;

- Azure Batch
  - large-scale job scheduling and compute management;

VM availability options:

![Availability Options](images/azure-availability-options.png)

- Availability sets (different racks within a datacenter)

  ![Availability Sets](images/azure-availability-sets.png)

- Availability zones (one or multiple datacenters within a region equipped with independent power, cooling and networking)

  - minimum three separate zones for each enabled region

  ![Availability Zones](images/azure-availability-zones.png)

### Storage

- Containers (Blob storage): unstructured data;
  - Serving images and documents directly to a browser;
  - Source for CDN;
  - Data backup and restore, disaster recovery, archiving;
  - Data for analysis;
- Tables: for structured, un-relational data;
- Data Lake storage: for analytics;
- Azure files

  - can be mounted _concurrently_ by cloud or on-premise machines;
  - use SMB protocol;
  - can be shared anywhere in the world using a URL containing a shared access signature(SAS) token (which allows specific access to a private asset for a specific amount of time);

  ![azure files](images/azure_files.png)

- Azure Queue

  - store large amount of messages;
  - can be accessed from anywhere in the world;

  ![azure queue](images/azure_queue.png)

- Disk storage

  - suitable for storing data only for the attached VM;
  - can be standard or premium SSD/HDD;
  - can be managed and configured either by Azure or the user;

#### Storage tiers

1. Hot: for data that is accessed frequently;
2. Cool: for infrequently accessed data and stored for at least 30 days;
3. Archive: rarely accessed data, stored for >180 days;

### Database services

Fully managed PaaS services

- SQL Database: structured data;
  - based on Microsoft SQL Server
- Cosmos DB: semi-structured data;
  - globally distributed

### Networking

- Azure Virtual Network

  - Enables Azure reources to securely communicate with each other, the internet and on-premises networks
  - Scoped to a single region

- Azure Load Balancer

  - Supports inbound and outbound scenarios, TCP, UDP
  - Incoming internet traffic, internal traffic across Azure services, port forwarding for specific traffic, or outbound connectivity fro VMs

- VPN Gateway
- Azure Application Gateway

  - Can route traffic based on source IP/port to a destination IP/port
  - Help protect web app with a web application firewall, redirection, _session affinity_, etc

- CDN
  - Minimize latency
  - Can be hosted in Azure or other locations
