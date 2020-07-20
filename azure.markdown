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
- Serverless computing
  - Azure Functions
    - Completely abstracts the underlying hosting environment
    - Response to an event - REST request, timer, or message form other Azure service
  - Azure Logic Apps (like Zapier)
    - Automate and orchestrate tasks, workflows;
    - Can connect to other services such as Salesforce, SAP, Oracel, etc;
  - Event Grid

    - For apps with event-based architectures, intelligent event routing using publish-subscribe model

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

### Big Data

- Synapse Analytics
- HDInsight
- Data Lake Analytics

### AI

- Cognitive Services: Vision, Speech, Language, Knowledge, Search
- Machine Learning Service: develop train, test, deploy, manage, and track ML models

### DevOps

- DevOps Service: pipelines, private Git repos, automated and cloud-based load testing
- Lab Services: provision environment using reusable templates and artifacts, scale up load testing by provisioning multiple test agents and create pre-provisioned envs for training and demos

## Azure management tools

- Azure Portal

  - Web based, not suitable for reptitive tasks

- Azure PowerShell

  - A module for Windows PowerShell or PowerShell Core(a cross-platform version of PowerShell)

- Azure CLI

- Cloud Shell

  - You can choose to use either CLI or PowerShell
  - A storage account is required

- Azure Mobile App

- Azure Rest API

## Business Process Automation

- Design-first

  - Power Automate
    - No code required
    - Use Logic Apps under the hood
  - Logic Apps
    - Intended for developers

- Code-first
  - Functions (_this should be default choice_)
    - Wider range of triggers / supported languages
    - Pay-per-use price model
  - App Service WebJobs
    - Part of App Service
    - Customization to `JobHost`

## Azure Functions

Benefits:

- Auto scaling, pay for what you use
- No need to manage servers
- Stateless logic
- Event driven

Drawbacks:

- Execution time limits (5 ~ 10min)
- Execution frequency (if need to be ran continously, may be cheaper to use a VM)

Triggers:

- Timer
- HTTP
- Blob (file uploaded/updated)
- Queue messages
- Cosmos DB (a document changes in a collection)
- Event Hub (receives a new event)

Bindings:

- A declarative way to connect to data (so you don't need to write the connection logic)
- Input bindings and output bindings
- Triggers are special types of input bindings
- Configured in a JSON file _function.json_, a sample

Example:

![Azure Functions bindings flow](./images/azure-functions_bindings_example.png)

Pass in an `id` and `url` from a HTTP request, if a bookmark with the id does not already exist, add to DB and push to a queue for further processing

`function.json`

```json
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["get", "post"]
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    },
    {
      "name": "bookmark",
      "direction": "in",
      "type": "cosmosDB",
      "databaseName": "func-io-learn-db",
      "collectionName": "Bookmarks",
      "connectionStringSetting": "gary-cosmos_DOCUMENTDB",
      "id": "{id}",
      "partitionKey": "{id}"
    },
    {
      "name": "newbookmark",
      "direction": "out",
      "type": "cosmosDB",
      "databaseName": "func-io-learn-db",
      "collectionName": "Bookmarks",
      "connectionStringSetting": "gary-cosmos_DOCUMENTDB",
      "partitionKey": "{id}"
    },
    {
      "name": "newmessage",
      "direction": "out",
      "type": "queue",
      "queueName": "bookmarks-post-process",
      "connection": "storageaccountlearna8ff_STORAGE"
    }
  ]
}
```

`index.js`

```js
module.exports = function (context, req) {
  var bookmark = context.bindings.bookmark;
  if (bookmark) {
    context.res = {
      status: 422,
      body: 'Bookmark already exists.',
      headers: {
        'Content-Type': 'application/json'
      }
    };
  } else {
    // Create a JSON string of our bookmark.
    var bookmarkString = JSON.stringify({
      id: req.body.id,
      url: req.body.url
    });

    // Write this bookmark to our database.
    context.bindings.newbookmark = bookmarkString;
    // Push this bookmark onto our queue for further processing.
    context.bindings.newmessage = bookmarkString;
    // Tell the user all is well.
    context.res = {
      status: 200,
      body: 'bookmark added!',
      headers: {
        'Content-Type': 'application/json'
      }
    };
  }
  context.done();
};
```

- `id` in `req` will be available as `id` to the `cosmosDB` binding;
- If `id` is found in the DB, `bookmark` will be set;
- `"connectionStringSetting": "gary-cosmos_DOCUMENTDB"` is an application setting in app scope, not restricted to current function, available to the function as an env variable;
- Simply assign a value to `newbookmark` and `newmessage` for output

### Durable functions

![Durable function patterns](./images/azure-durable_function_workflow_patterns.png)

There are three different functions types, the table below show how to use them in the human interactions workflow:

| Workflow function                                   | Durable Function Type  |
| --------------------------------------------------- | ---------------------- |
| Submitting a project design proposal for approval   | Client Function        |
| Assign an Approval task to relevant member of staff | Orchestration Function |
| Approval task                                       | Activity Function      |
| Escalation task                                     | Activity Function      |
