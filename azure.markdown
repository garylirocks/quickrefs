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


### Storage

- Blob storage: unstructured data;
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
- SQL Data Warehouse
  - support OLAP solutions and SQL queries
  - does not support cross-database queries
- Cosmos DB: semi-structured data;
  - globally distributed
  - indexes every field by default

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

### CLI

```sh
# set default group and location
az configure --defaults group=<groupName> location=australiasoutheast

# === START create / manage a storage account
# get a random account name
STORAGE_NAME=storagename$RANDOM

# create a storage account
az storage account create --name $STORAGE_NAME --sku Standard_RAGRS --encryption-service blob

# list access keys
az storage account keys list --account-name $STORAGE_NAME

# get connection string (key1 is in the string)
az storage account show-connection-string -n $STORAGE_NAME

# create a container in the account
az storage container create -n messages --connection-string "<connection string here>"
```


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

| Workflow function                    | Durable Function Type             |
| ------------------------------------ | --------------------------------- |
| Submitting a project design proposal | Client Function (trigger)         |
| Assign an Approval task              | Orchestration Function (workflow) |
| Approval task                        | Activity Function                 |
| Escalation task                      | Activity Function                 |

- You need to run `npm install durable-functions` from the `wwwroot` folder of your function app in Kudu

## Messaging platforms

### Messages vs. Events

Messages:
  - Overall integrity of the application rely on messages being received
  - Generally contains the data itself
  - Sender and receiver are often coupled by a strict data contract

Events:
  - 'Lighter' than messages
  - Most often used for broadcast communications, have a large number of subscribers for each publisher
  - Publisher has no expectation about the action a receiving component takes

### Service bus

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

### Storage Queues

![storage queue message flow](images/azure_storage-queue-message-flow.png)

- `get` and `delete` are separate operations, this ensures the *at-least-once delivery*, in case there is a failure in the receiver, after receiver gets a message, the message remains in the queue but is invisible for 30 seconds, after that if not deleted, it becomes visible again and another instance of the receive can process it



### Event Grid

### Event Hub

Often used for a specific type of high-flow stream of communications used for analytics (often used with Stream Analytics)


## Azure Storage

![storage services overview](images/azure_storage-services.png)

Blobs, Files, Queues and Tables are grouped together into Azure storage and are often used together

Storage account level settings:

- Subscription
- Location
- Performance
  - Standard: magnetic disk drives
  - Premium:
    - SSD
    - additional services: unstructured object data as block blobs or append blobs, specialized file storage
- Replication
  - LRS: locally-redundant storage, three copies within a datacenter
  - GRS: geo-redundant storage
- Access tier
  - Hot or cool
  - *Only apply to blobs*
  - Can be specified for each blob
- Secure transer required: whether HTTPS is enforced
- Virtual networks: only allow inbound access request from the specified network(s)

- Account kind
  - StorageV2 (general purpose v2): all storage types, latest features
  - Storage (general purpose v1): legacy
  - Blob storage: legacy, allows only block blobs and append blobs
- Deployment model
  - Resource Manager
  - Classic: legacy


### Blobs

Object storage solution optimized for storing massive amounts of unstructured data, ideal for:

- serving images or documents directly to a browser, including full static websites.
- storing files for distributed access.
- streaming video and audio.
- storing data for backup, disaster recovery and archiving.
- storing data for analysis.

Three kinds of blobs:

- Block blobs: for files that are read from beginning to end, files larger than 100MB must be uploaded as small blocks which are then consolidated into the final blob.
- Page blobs: to hold random-access files up to 8 TB in size, used primarily as storage for the VHDs used to provide durable disks for Azure VMs. They provide random read/write access to 512-byte pages.
- Append blobs: specialized block blobs, but optimized for append operations, frequently used for logging from one or more sources.

Many Azure components use blobs behind the scenes, Cloud Shell stores your files and configuration in blobs, VMs use blobs for hard-disk storage.

#### Organization

- Account
  - Can have unlimited containers
  - Usually created by an admin
- Containers
  - Can contain unlimited blobs
  - Can be seen as a security boundary for blobs, you can set an individual container as public.
  - Usually created in an app as needed (calling `CreateIfNotExistsAsync` on a `CloudBlobContainer` is the best way to create a container when your application starts or when it first tries to use it)
- Virtual directories: technically containers are "flat", there is no folders. But if you give blobs hierarchical names looking like file paths, the API's listing operation can filter results to specific prefixes.

### Files

Network files shares, accessed over SMB protocol

Common scenarios:

- Storing shared configuration files for VMs, tools.
- Log files such as diagnostics, metrics and crash dumps.
- Shared data between on-premises applications and Azure VMs to allow migration.

### Security

Security features:

- Encryption at rest

  All data is automatically encrypted by Storage Service Encryption (SSE) with a 256-bit AES cipher. This can't be disabled.

  For VMs, Azure let's you encrypt virtual hard disks(VHDs) by using Azure Disk Encryption (BitLocker for Windows images, dm-crypt for Linux)

  Azure Key Vault stores the keys automatically.

- Encryption at tansit

  You can enforce HTTPS on an account. This flag will also enforce secure transfer over SMB by requiring SMB 3.0 for all file share mounts.

- CORS support

  An optional flag you can enable on Storage accounts. Apply only for GET requests.

- Role-based access control

  RBAC is the Most flexible access option.
  Can be applied to both resource management(e.g. configuration) and data operations(only for Blob and Queue).

- Auditing access

  Using the built-in Storage Analytics service, which logs every operation in real time.


#### Access keys

- Like a root password, allow full access.
- Typically stored within env variables, database, or configuration file.
- *Should be private, don't include the config file in source control and store in public repos*
- Each storage account has two access keys, this allows key to be rotated:
  1. update connection strings in your app to use secondary access key
  2. Regenerate primary key using Azure portal or CLI.
  3. Update connection string in your code to reference the new primary key.
  4. Regenerate the secondary access key.

#### Shared access signature (SAS)

- support expiration and limited permissions
- suitable for external third-party applications
- can be service-level or account-level

Two typical designs for using Azure Storage to store user data:

  - Front end proxy: all data pass through the proxy

  ![Front end proxy](images/azure_storage-design-front-end-proxy.png)

  - SAS provider: only generates a SAS and pass it to the client

  ![SAS provider](images/azure_storage-design-lightweight.png)


#### Network access

By default, connections from clients on any network are accepted. You can restrict access to specific IP addresses, ranges or virtual networks.

#### Advanced threat protection

- Detects anomalies in account activity
- Only for Blob currently
- Security alerts are integrated with Azure Security Center

## VMs

Checklist for creating VMs

- Network (vNets)
  - Decide network address space;
  - Break network into sections, e.g. 10.1.0.0 for VMs, 10.2.0.0 for SQL Server VMs;
  - Network security groups (NSG)

- Name
  - used as the computer name
  - also defines a manageable Azure resource, not trivial to change later (it can be applied to the associated storage account, VNets, network interface, NSGs, public IPs)
  - a good example `dev-usc-web01` includes environment, location, role and instance of this VM

- Location
  - consider proximity, compliance, price

- Size
  - based on workload
    - general purpose: ideal for testing and dev, small to medium DBs, low to medium traffic web servers
    - compute optimized: medium traffic web servers, network appliances, batch processes, and application servers
    - memory optimized: DBs, caches, in-memory analytics
    - storage optimized: DBs
    - GPU: graphics rendering and video editing
    - high performance compute
  - sizes can be changed

- Pricing model
  - Compute
    - billed on per-minute basis
    - stop and deallocate VM stop compute charging
    - Linux VMs are cheaper than Windows which includes license charges
    - Two payment options:
      - Pay as you go
      - Reserved VM instances

  - Storage
    - charged separately from VM, you will be charged for storage used by the disks even if the VM is deallocated

- Storage

  - Each VM has at least two VHDs, one for OS (`/dev/sda` on Linux), another one for temporary storage (`/mnt` on Linux, stores the swap file), and can add additional disks
  - VHDs are page blobs in Azure Storage
  - two options for managing the relationship between the storage account and each VHD:
    - unmanaged disks: you are responsible for the storage account, an account is capable of supporting 40 standard VHDs, it's hard to scale out
    - **managed disks: newer and recommended**, you only need to specify the size, easier to scale out

- OS
  - Multiple versions of Windows and Linux
  - Marketplace has VM images which include popular tech stacks
  - You can create your disk image and upload to Azure storage and use it to create a VM

### Create VM using CLI

```sh
az vm create \
    --resource-group TestResourceGroup \
    --name test-wp1-eus-vm \
    --image win2016datacenter \
    --admin-username jonc \
    --admin-password aReallyGoodPasswordHere
```

### VM extensions

Small applications that allow you to configure and automate tasks on Azure VMs after initial deployment.


### Initialize data disks

Any additional drives you create from scratch need to be initialized and formatted.

```sh
# list block devices, 'sdc' is not mounted
lsblk
# NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# sda       8:0    0   16G  0 disk
# └─sda1    8:1    0   16G  0 part /mnt
# sdb       8:16   0   30G  0 disk
# ├─sdb1    8:17   0 29.9G  0 part /
# ├─sdb14   8:30   0    4M  0 part
# └─sdb15   8:31   0  106M  0 part /boot/efi
# sdc       8:32   0    1T  0 disk
# sr0      11:0    1  628K  0 rom

# create a new primary partition
(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc

# write a file system to the partition
sudo mkfs -t ext4 /dev/sdc1

# create a mount point and mount
sudo mkdir /data && sudo mount /dev/sdc1 /data
```


### Availability options

![Availability Options](images/azure-availability-options.png)

- Availability sets (different racks within a datacenter)

  - 99.95% SLA
  - VMs in a availability set are spread across Fault Domains and Update Domains

![Availability Sets](images/azure-vm_availability_sets.png)


- Availability zones (one or multiple datacenters within a region equipped with independent power, cooling and networking)

  - minimum three separate zones for each enabled region

  ![Availability Zones](images/azure-availability-zones.png)


### Scaling

- Virtual Machine Scale Sets

  - let you create and manage a group of identical, load balanced VMs;
  - number of instances can automatically increase or decrease in response to demand or a defined schedule;

- Azure Batch
  - large-scale job scheduling and compute management;

## Resource Manager templates

- JSON file that defines the resources you need to deploy
- For resources deployed based on a template, after you update and redeploy the template, the resources will reflect the changes


## Networking

### Network security group (NSG)

- it's optional
- a software firewall which filters inbound and outbound traffic on the VNet
- can be associated to a network interface (per host rules), a subnet in the virtual network, or both
- default rules cannot be modified but *can* be overridden
- rules evaluation starts from the **lowest priority** rule, deny rules always stop the evaluation

![network security group](images/azure_network-security-group.png)


## App Service

Fully managed web application hosting platform, PaaS.

### App Service plans

A plan's **size** (aka **sku**, **pricing tier**) determines
  - the performance characteristics of the underlying virtual servers
  - features available to apps in the plan

SKUs

- **Shared compute**: **Free** and **Shared**, VM shared with other customers, **cannot** scale out
- **Dedicated compute**: only apps in the same plan can share the same compute resources
- **Isolated**: network isolation on top of compute isolation

Plans are the unit of billing. How much you pay for a plan is determined by the plan size(sku) and bandwidth usage, not the number of apps in the plan.

You can start from an cheaper plan and scale up later.

### Deployment

There are multiple ways to deploy an app:

- Azure DevOps
- GitHub
- BitBucket
- Local Git: You will be given a remote git url, pushing to it triggers a build.
- OneDrive
- Dropbox
- FTP
- CLI

  example:

  ```sh
  # get all variables
  APPNAME=$(az webapp list --query [0].name --output tsv)
  APPRG=$(az webapp list --query [0].resourceGroup --output tsv)
  APPPLAN=$(az appservice plan list --query [0].name --output tsv)
  APPSKU=$(az appservice plan list --query [0].sku.name --output tsv)
  APPLOCATION=$(az appservice plan list --query [0].location --output tsv)

  # go to your app directory
  cd ~/helloworld

  az webapp up --name $APPNAME --resource-group $APPRG --plan $APPPLAN --sku $APPSKU --location "$APPLOCATION"
  ```

If your app is based on a docker container, then there will be a webhook url, which allows you to receive notifications from a docker registry when an image is updated. Then App Service can pull the latest image and restart your app.

If you are using an image from Azure Container Registry, when you enable '**Continuous Deployment**', the webhook is automatically configured in Container Registry.

### Deployment slots

- A slot is a separate instance of your app, has its own hostname
- Each slot shares the resources of the App Service plan
- Only available in the Standard, Premium or Isolated tier
- You can create a new slot by cloning the config of an existing slot, but you can't clone the content, which needs to be deployed

If you app name is `garyapp`, the urls would be like

- production: https://garyapp.azurewebsites.net/
- staging: https://garyapp-staging.azurewebsites.net/


#### Swap

- You can create a **staging** slot, after testing, you can **swap** the staging slot with production slot, this happens instantly without any downtime.
- If you want rollback, swap again.
- App Service warms up the app by sending a request to the root of the site after a swap.
- When swapping two slots, configurations get swapped as well, unless a configuration is '**Deployment slot settings**', then it sticks with the slot (this allows you to config different DB connection strings or `NODE_ENV` for production and staging and make sure they don't swap with the app)
- 'Auto Swap' option is available for Windows.

### Scaling

- Built-in auto scale support
- Scale up/down: increasing/decreasing the resources of the underlying machine
- Scale out: increase the number of machines running your app, each tier has a limit on how many instances can be run

### Node app

If it's node, Azure will run `yarn install` automatically to install packages

You need to make sure the app:

- Is listening on `process.env.PORT`
- Uses `start` in `package.json` to start the app

## Docker Container Registry

Like Docker Hub

Unique benefits:

- Runs in Azure, the registry can be replicated to store images where they're likely to be deployed
- Highly scalable, enhanced thoroughput for Docker pulls

```sh
# create a registry
az acr create --name garyrepo --resource-group mygroup --sku standard --admin-enabled true

# instead of building locally and pushing to it
# you can also let the registry build an image for you
# just like 'docker build'
az acr build --file Dockerfile --registry garyrepo --image myimage .

# you can enable 'Admin user' for the registry
# then you can login from your local machine
docker login -u garyrepo garyrepo.azurecr.io

# pull an image
docker pull garyrepo.azurecr.io/myimage:latest
```

### Tasks feature

You can use the tasks feature to rebuild your image whenever its source code changes.

```sh
az acr task create
  --registry <container_registry_name> \
  --name buildwebapp \
  --image webimage \
  --context https://github.com/MicrosoftDocs/mslearn-deploy-run-container-app-service.git --branch master \
  --file Dockerfile \
  --git-access-token <access_token>
```

The above command creates a task `buildwebapp`, creates a webhook in the GitHub repo, when it changes, triggers image rebuild in ACR.



