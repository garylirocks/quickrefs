# Azure

- [Azure AD, tenant, subscriptions](#azure-ad-tenant-subscriptions)
  - [Azure AD](#azure-ad)
  - [Tenant](#tenant)
  - [Subscription](#subscription)
- [Cloud computing fundamentals](#cloud-computing-fundamentals)
  - [Compute](#compute)
    - [VMs](#vms)
  - [Storage](#storage)
    - [Storage tiers](#storage-tiers)
  - [Networking](#networking)

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
- Azure App Service
  - PaaS
  - Designed to host enterprise-grade web-oriented applications;
- Serverless computing
  - Completely abstracts the underlying hosting environment;

#### VMs

Scaling VMs:

- Availability sets
  ![Availability Set](images/azure-vm_availability_sets.png)

  - logical grouping of VMs across multiple Fault Domains (separate server racks) or Update Domains (logical part of a data center);

- Virtual Machine Scale Sets

  - let you create and manage a group of identical, load balanced VMs;
  - number of instances can automatically increase or decrease in response to demand or a defined schedule;

- Azure Batch
  - large-scale job scheduling and compute management;

### Storage

- SQL Database: structured data;
- Cosmos DB: semi-structured data;
- Blob storage: unstructured data;
- Data Lake storage: for analytics;
- Azure files

  - can be mounted _concurrently_ by cloud or on-premise machines;
  - use SMB protocol;
  - can be shared anywhere in the world;

  ![azure files](images/azure_files.png)

- Azure Queue

  - store large amount of messages;
  - can be accessed from anywhere in the world;

  ![azure queue](images/azure_queue.png)

- Disk storage

  - suitable for storing data only for the attached VM;
  - can be standard or premium SSD/HDD;

#### Storage tiers

1. Hot: for data that is accessed frequently;
2. Cool: for infrequently accessed data and stored for at least 30 days;
3. Archive: rarely accessed data, stored for >180 days;

### Networking
