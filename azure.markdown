# Azure

## Overview

### Deployment model

- Public cloud
- Private cloud

  Azure Stack

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

### DevOps

- DevOps Service: pipelines, private Git repos, automated and cloud-based load testing
- Lab Services: provision environment using reusable templates and artifacts, scale up load testing by provisioning multiple test agents and create pre-provisioned envs for training and demos


## Resource management

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

### Management groups

![Management groups](images/azure_management-groups.png)

- A way to efficiently manage access, policies, and compliance for subscriptions
  - Apply a policy to limit regions available to subscriptions under a group
  - Create a RBAC assignment on a group
- All subscriptions and management groups are within a single hierarchy in each directory

### Subscription

- A tenant can have multiple subscriptions;
- Billing is done monthly at subscription level;


### Resource group

- A logical container for resources;
- All resources must be in one and only one group;
- Resources in one group can span multiple regions;
- Groups can't be nested;


You can organize resource groups in different ways:

  - by resource type(vm, db),
  - by department(hr, marketing),
  - by environment (prod, qa, dev),
  - Life cycle

    When you delete a group, all resources within are deleted, if you just want to try out something, put all new resources in one group, and then everything can be deleted together;

  - Authorization

    A group can be a scope for applying role-based access control (RBAC);

  - Billing

    Can be used to filter and sort costs in billing reports;


### Tags

Another way to organize resources

- **NOT** all types of resources support tags;
- There are limitations on number of tags for each resource, lengths of tag name and value;
- Tags are not inherited;
- Can be used to automate task, such as adding `shutdown:6PM` and `startup:7AM` to virtual machines, then create an automation job that accomplish tasks based on tags;

### Policy

Policies apply and enforce rules your resources need to follow, such as:

- only allow specific types of resources to be created;
- only allow resources in specific regions;
- enforce naming conventions;
- specific tags are applied;

### Locks

A setting that can by applied to any resource to block inadvertent modification or deletion.

- Two types: **Delete** or **Read-only**
- Can be applied at different levels: subscriptions, resource groups, and individual resources
- Are inherited from higher levels;
- Apply regardless of RBAC permissions, even you are the owner , you still need to remove the lock before delete the resource;


### Resource Group Manager (RGM)

![Resource manager](images/azure_resource-manager.png)

Resource Group Manager (RGM) is the management layer which allows you automate the deployment and configuration of resources;


### Resource Manager templates

- JSON file that defines the resources you need to deploy
- For resources deployed based on a template, after you update and redeploy the template, the resources will reflect the changes
- With parameters, you can use the same template to create multiple versions of your infrastructure, such as staging and production
- Modular: you can create small templates and combine them

Example:

```json
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "",

  // values you provide when run a template
  "parameters": {
    "adminUsername": {
      "type": "string",
      "metadata": {
        "description": "Username for the Virtual Machine."
      }
    },
    "adminPassword": {
      "type": "securestring",
      "metadata": {
        "description": "Password for the Virtual Machine."
      }
    }
  },


  // global variables
  "variables": {
    "nicName": "myVMNic",
    "addressPrefix": "10.0.0.0/16",
    "subnetName": "Subnet",
    "subnetPrefix": "10.0.0.0/24",
    "publicIPAddressName": "myPublicIP",
    "virtualNetworkName": "MyVNET"
  },

  // utility functions
  "functions": [
    {
      "namespace": "contoso",
      "members": {
        "uniqueName": {
          "parameters": [
            {
              "name": "namePrefix",
              "type": "string"
            }
          ],
          "output": {
            "type": "string",
            "value": "[concat(toLower(parameters('namePrefix')), uniqueString(resourceGroup().id))]"
          }
        }
      }
    }
  ],

  "resources": [
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "name": "[variables('publicIPAddressName')]",
      "location": "[parameters('location')]",
      "apiVersion": "2018-08-01",
      "properties": {
        "publicIPAllocationMethod": "Dynamic",
        "dnsSettings": {
          "domainNameLabel": "[parameters('dnsLabelPrefix')]"
        }
      }
    }
  ],

  "outputs": {
    "hostname": {
      "type": "string",
      "value": "[reference(variables('publicIPAddressName')).dnsSettings.fqdn]"
    }
  }
}
```

Note:

- Expressions need to be enclosed in brackets `[`, `]`



```sh
# validate a template file
az deployment group validate \
    --resource-group learn-63336b5a-694e-4b61-a1a5-1f173253244e \
    --template-file basic-template.json
    --parameters @params.json

# deploy
az deployment group create \
    --name MyDeployment \
    --resource-group learn-63336b5a-694e-4b61-a1a5-1f173253244e \
    --template-file basic-template.json
    --parameters @params.json

# verify
az deployment group show \
    --name MyDeployment \
    --resource-group learn-63336b5a-694e-4b61-a1a5-1f173253244e
```


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

- Azure SDKs

  - SDKs are based on Reset API, but are easier to use

### CLI

- Get help

  ```sh
  az vm --help

  # this uses AI to get usage examples:
  az find `az vm`
  ```

- Connect and config

  ```sh
  az login

  # list subscriptions
  az account list

  # set active subscription
  az account set --subscription gary-default

  # list resource groups
  az group list

  # set default group and location
  az configure \
    --defaults group=<groupName> location=australiasoutheast

  # list default configs
  az configure -l
  ```

- Create

  ```sh
  # create a resource group, <location> here is only for group metadata, resources in the group can be in other locations
  az group create --name <name> --location <location>

  # verify
  az group list
  ```

- Full example

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

- Tips
  - Use `--no-wait` to move on to next command and avoid blocking
  - It's often useful to use `--output tsv` to put the output of a command in a variable
  - `--query` uses [JMESPath](https://jmespath.org/) to query JSON data

### PowerShell

- Windows include PowerShell, on Linux or Mac, you can use PowerShell Core
- Azure PowerShell is a PowerShell module, you need install it by `Install-Module Az -AllowClobber`

```sh
# start PowerShell
sudo pwsh
```

```powershell
# import Az module
Import-Module Az

# login
Connect-AzAccount

# list subscriptions
Get-AzSubscription

# select a subscription
Select-AzSubscription -Subscription "gary-default"

# get resource groups in the active subscription
Get-AzResourceGroup

# or show results in table format
Get-AzResourceGroup | Format-Table

# create a resource group
New-AzResourceGroup -Name <name> -Location <location>

# get resources
Get-AzResource -ResourceType Microsoft.Compute/virtualMachines

# create a VM
# 'Get-Credential' cmdlet will prompt you for username/password
New-AzVm -ResourceGroupName <resource-group-name>
  -Name "testvm-eus-01"
  -Credential (Get-Credential)
  -Location "East US"
  -Image UbuntuLTS
  -OpenPorts 22

# get a VM object
$vm = Get-AzVM -Name "testvm-eus-01" -ResourceGroupName learn-baaf2cfd-95ef-4c32-be59-55c78729a07d

# show the object
$vm

# get a field
$vm.Location
# eastus

# stop vm
Stop-AzVM -Name $vm.Name -ResourceGroup $vm.ResourceGroupName

# remove vm (it doesn't cleanup related resources)
Remove-AzVM -Name $vm.Name -ResourceGroup $vm.ResourceGroupName
```

PowerShell script example, creating three VMs

```powershell
# assign first param to a variable
param([string]$resourceGroup)

# prompt for username/password
$adminCredential = Get-Credential -Message "Enter a username and password for the VM administrator."

For ($i = 1; $i -le 3; $i++)
{
    $vmName = "ConferenceDemo" + $i
    Write-Host "Creating VM: " $vmName
    New-AzVm -ResourceGroupName $resourceGroup -Name $vmName -Credential $adminCredential -Image UbuntuLTS
}
```

Run the script by

```
./script.ps1 learn-baaf2cfd-95ef-4c32-be59-55c78729a07d
```


## Azure AD

- Each Azure subscription is associated with a single Azure AD directory (tenant);
- Users, groups and applications in that directory can manage resources in the subscription;
- Subscriptions use Azure AD for SSO;
- Microsoft 365 uses Azure AD;

Licenses:

- Free
  - user, groups, basic reports
  - on-premises AD sync
  - self-service password reset
  - SSO for Microsoft 365, Azure services, other third-party SaaS applications

- Premium P1
  - dynamic groups
  - on-premises identity management suite
  - conditional access policy

- Premium P2
  - Active Directory Identity Protection: risk-based conditional access
  - privileged identity management: detailed restrictions on administrators

- Pay-as-you-go
  - Azure AD B2C: manage identity and access for consumer users

Features:

- B2B identity services (allow you to invite guest users, *available to all tiers*)

  ![B2B process](images/azure_ad-b2b.svg)

- B2C identity services (customer users, *pay-as-you-go*)

  ![B2B process](images/azure_ad-b2c.svg)

### Compare with Active Directory

- Active Directory manages objects, like devices and users on your on-premises network;
- AAD does not replace Active Directory;
- They can be used together;

### Best practices

- Give at least two accounts the **Global Administrator** role, DON'T use them daily;
- Use regular administrator roles wherever possible;
- Create a list of banned passwords (such as company name);
- Configure conditional-access policies to require users to pass multiple authentication challenges;


### Providing identities to services

- Service principals

  A service principal is an identity used by any service or application, it can have assigned roles, use a different service principal for each of your applications

- Managed identities for Azure services

  When you create a managed identity for a service, you are creating an account on your organization's AD.

  - System-assigned

    A resource can have only one system-assigned managed identity, if the resource is deleted, so is the managed identity

    ```sh
    # assign a system-assigned managed identity to a VM
    az vm identity assign \
        --name <vm name> \
        --resource-group <resource group>
    ```

  - User-assigned

    A user-assigned managed identity is independent of any resources, so if your app is running on multiple VMs, it can use the same identity

    ```sh
    az identity create \
        --name <identity name> \
        --resource-group <resource group>

    # view identities, including system-assigned
    az identity list \
        --resource-group <resource group>

    # assign an identity to a function app
    az functionapp identity assign \
        --name <function app name> \
        --resource-group <resource group> \
        --role <principal id>

    # grant key vault permissions to an identity
    az keyvault set-policy \
        --name <key vault name> \
        --object-id <principal id> \
        --secret-permissions get list
    ```

### Role-based access control (RBAC)

RBAC allows you to grant access to Azure resources that you control. You do this by creating role assignments, which control how permissions are enforces. There are three elements in a role assignment:

1. Security principal (who)

  ![RBAC principal](images/azure_rbac-principal.png)

2. Role definition (what)

  A collection of permissions, `NotActions` are subtracted from `Actions`

  ![RBAC role definition](images/azure_rbac-role.png)

  Four fundamental built-in roles:

  - Owner - full access, including the right to delegate access to others
  - Contributor - create and manage, but can't grant access to others
  - Reader - view
  - User Access Administrator - can manage user access

3. Scope (where)

  ![role scopes hierarchy](images/azure_rbac-scopes.png)


Role Assignment

![Role Assignment](images/azure_rbac-role-assignment.png)

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
- Configured in a JSON file _function.json_

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

## Logic Apps

![Trigger types](images/azure_logic-app-trigger-types.png)

JSON definition example:

- There is a trigger named `myManualTrigger`, which is an HTTP request trigger, here we define two url path parameters `width` and `height`
- There is one action named `myResponse`, which output a string, doing an area calculation based on `width` and `height`
- Variables should be inclosed like `@{varName}`
- You can trigger this app by visiting a URL like `https://prod-57.westus.logic.azure.com/workflows/90cb01f9a2534ee5a9a0a50f95e5a34b/triggers/myManualTrigger/paths/invoke/{width}/{height}?api-version=2016-10-01&sp=%2Ftriggers%2FmyManualTrigger%2Frun&sv=1.0&sig=nn8JG1P1aOzXFN2lv1haoEQYcRxP4kCaeSyG33yE5sQ`

```json
{
  "definition": {
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "triggers": {
      "myManualTrigger": {
        "type": "Request",
        "kind": "Http",
        "inputs": {
          "method": "GET",
          "relativePath": "{width}/{height}",
          "schema": {}
        }
      }
    },
    "actions": {
      "myResponse": {
        "type": "Response",
        "kind": "Http",
        "runAfter": {},
        "inputs": {
          "body": "Response from @{workflow().name}  Total area = @{triggerBody()}@{mul( int(triggerOutputs()['relativePathParameters']['height'])  , int(triggerOutputs()['relativePathParameters']['width'])  )}",
          "statusCode": 200
        }
      }
    },
    "outputs": {}
  },
  "parameters": {}
}
```

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

| Service     | Type                          | Purpose                         | When to use                              |
| ----------- | ----------------------------- | ------------------------------- | ---------------------------------------- |
| Service Bus | Message                       | **High-value enterprise** messaging | Order processing, financial transactions |
| Event Grid  | Event distribution (discrete) | Reactive programming            | React to status change                   |
| Event Hubs  | Event streaming (series)      | Big data pipeline               | Telemetry and distributed data streaming |

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

### Files

Network files shares, accessed over SMB protocol

Common scenarios:

- Storing shared configuration files for VMs, tools.
- Log files such as diagnostics, metrics and crash dumps.
- Shared data between on-premises applications and Azure VMs to allow migration.

### Organization

- Account
  - Can have unlimited containers
  - Usually created by an admin
- Containers
  - Can contain unlimited blobs
  - Can be seen as a security boundary for blobs, you can set an individual container as public.
  - Usually created in an app as needed (calling `CreateIfNotExistsAsync` on a `CloudBlobContainer` is the best way to create a container when your application starts or when it first tries to use it)
- Virtual directories: technically containers are "flat", there is no folders. But if you give blobs hierarchical names looking like file paths, the API's listing operation can filter results to specific prefixes.

### Security

Security features:

- Encryption at rest

  - All data is automatically encrypted by Storage Service Encryption (SSE) with a 256-bit AES cipher. This can't be disabled.
  - For VMs, Azure let's you encrypt virtual hard disks(VHDs) by using Azure Disk Encryption (BitLocker for Windows images, `dm-crypt` for Linux)
  - Azure Key Vault stores the keys automatically.

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

- Like a root password, allow **full access**.
- Typically stored within env variables, database, or configuration file.
- *Should be private, don't include the config file in source control or store in public repos*
- Each storage account has two access keys, this allows key to be rotated:
  1. update connection strings in your app to use secondary access key
  2. Regenerate primary key using Azure portal or CLI.
  3. Update connection string in your code to reference the new primary key.
  4. Regenerate the secondary access key.

#### Shared access signature (SAS)

- support expiration and limited permissions
- suitable for external third-party applications
- can be applied to only containers or objects

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

## Blobs

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

### CLI

- Can't resume if upload/download fails, so NOT suitable for large files
- `az storage` commands require an account name and key to authenticate, you can either specify them everytime or use environment variables `AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY`
- There are options to specify overwritting behavior based on ETag or modification date, eg. `--if-unmodified-since`

```sh
# get account keys
az storage account keys list \
  --account-name <Account> \
  --output table

# specify default account and key
export AZURE_STORAGE_ACCOUNT=<Account>
export AZURE_STORAGE_KEY=<Key>

# (sync) upload file to a blob
az storage blob upload \
  --container-name MyContainer \
  --file /path/to/file \
  --name MyBlob \
  --if-unmodified-since 2019-05-26T10:30Z

# (sync) batch upload
az storage blob upload-batch \
  --destination myContainer \
  --source myFolder \
  --pattern *.bmp

# list
az storage blob list ...

# archive a blob
az storage blob set-tier \
  --container-name myContainer \
  --name myPhoto.png \
  --tier Archive
```

Copy blobs, there are options for selecting source blobs, e.g. use `--source-if-unmodified-since` to copy old blobs from hot storage to cool storage

```sh
# (async) start copying between containers/accounts
# only
az storage blob copy start \
  ... \
  --source-if-unmodified-since [date]

# check state of dest blob
az storage blob show ...
```

To move a blob, you need to copy it, then delete the source blob.

```sh
# delete a blob
az storage blob delete --name sourceBlob

# batch delete blobs older than 6 months
date=`date -d "6 months ago" '+%Y-%m-%dT%H:%MZ'`
az storage blob delete-batch \
  --source sourceContainer \
  --if-unmodified-since $date
```

### AzCopy

- All operations are async;
- Suitable for bulk operations, if interrupted, can resume from the point of failure;
- Supports hierarchical containers;
- Supports pattern matching selection;
- Use `--include-after` to only include files changed after a specific date/time;

```sh
# upload file
azcopy copy "myfile.txt" "https://myaccount.blob.core.windows.net/mycontainer/?<sas token>"

# upload folder recursively
azcopy copy "myfolder" "https://myaccount.blob.core.windows.net/mycontainer/?<sas token>" \
  --recursive=true

# transfer between accounts
azcopy copy "https://sourceaccount.blob.core.windows.net/sourcecontainer/*?<source sas token>" \
  "https://destaccount.blob.core.windows.net/destcontainer/*?<dest sas token>"

# sync data
azcopy sync ...

# list data/create new container/remove blobs
azcopy [list|make|remove] ...

# show job status
azcopy jobs list
```

### .NET Storage Client library

- Suitable for complex, repeated tasks
- Provides full access to blob properties
- Supports async operations

### Access tiers

- Hot and Cool can be set as account or blob level;
- Archive
  - can only be set at blob level;
  - data is offline, only metadata available for online query;
  - to access data, the blob must first be **rehydrated** (changing the blob tier from Archive to Hot or Cool, this can take hours);
- Premium: only available for BlobStorage accounts (legacy);

From Hot to Cool to Archive, the cost of storing data decreases but the cost of retrieving data increses.

### Properties and Metadata

- Both containers and blobs have properties and metadata.
- Can be accessed/updated by Portal, CLI, PowerShell, SDK, REST API.

| Properties                     | Metadata                      |
| ------------------------------ | ----------------------------- |
| system-defined                 | user-defined name-value pairs |
| read-only or read-write        | read-write                    |
| `Length`, `LastModifined`, ... | `docType`, `docClass`, ...    |

```sh
export AZURE_STORAGE_ACCOUNT=<account>
export AZURE_STORAGE_SAS_TOKEN=<token>

# get details of a blob
az storage blob show -c myContainer -n 'file.txt'

# set a property on a blob
# this will make CDN don't cache this file
az storage blob update -c myContainer -n 'file.txt' --content-cache-control 'no-cache'
# can be done during upload as well
az storage blob upload -c myContainer -n 'file.txt' -f file.txt -p cacheControl="no-cache"
# using azcopy
azcopy cp file.txt <remote-address> --cache-control 'no-cache'

# get metadata of a blob
az storage blob metadata show -c myContainer -n 'file.txt'

# properties for the whole blob service, not a specific blob
az storage blob service-properties show
```

### Concurrency

Three concurrency strategies:
  - optimistic concurrency;
    - Get the ETag, when saving data, send back this ETag, Azure only updates the blob if the ETag still matches the blob's current ETag;
    - It's not enforced, every app needs to adopt it;

    ![Blob concurrency using ETag](images/azure_blob-concurrency-etag.png)
  - pessimistic concurrency;
    - An app require a lease for a set period of time, no one else can modify the blob before the lease is released or expired;
    - Lease time is from 15s to 60s, so it's more suitable for programmatic processing of records;
    - An app can also renew or break a lease before it expires;

    ![Blob concurrency using lease](images/azure_blob-concurrency-lease.png)


## Cosmos DB

Features

- Multi-model

  It supports multiple API and data models(*each account only supports one model*):

    - Core (SQL) *this is for NoSQL document DB as well, and is recommended, other APIs are mainly for migration purposes*
    - MongoDB
    - Cassandra
    - Azure Table (for migrating data from Azure Table, Cosmos offers global distribution, high availability, scalable throughput)
    - Gremlin(graph)

- Global distribution

### Common CLI operations

```sh
export NAME=cosmos$RANDOM

az cosmosdb create \
    --name $NAME \
    --kind GlobalDocumentDB

az cosmosdb sql database create \
    --account-name $NAME \
    --name "Products"

az cosmosdb sql container create \
    --account-name $NAME \
    --database-name "Products" \
    --name "Clothing" \
    --partition-key-path "/productId" \
    --throughput 1000
```

### Request unit

- You can provision throughput on a database or a container;
- Throughput is meseaured with request units per second (**RU/s**);
- If your request consumes all provisioned throughput, then Azure will rate-limit your requests, you need to retry your request;
- Billing is based on provisioned RUs, whether you use them or not;

A single RU is equal to the approximate cost of performing a single GET request on a 1-KB document using a document's ID. Creating, replacing or deleting the same item requires additional processing, thus more RUs.

The number of RUs consumed by an operation is depending on a range of factors:

- item size
- item indexing
- item property count
- indexed properties
- data consistency level (strong and bounded staleness consume approximately two times more RUs on read)
- complexity of a query (same query on the same data always costs the same amount of RUs)
- script usage (stored procedures and triggers)

### Partitioning

- Partitioning is the distribution and grouping of your data across the underlying resources;
- Documents are grouped in a partition based on the partition key;
- A partition key can be a single or multiple fields of a document;
- Partition key can't be changed after a collection is provisioned;
- Documents with the same partition key are in the same logical partition, but possibly multiple **physical partitions**;

### Indexing

- By default, all document properties are indexed;
- Indexing mode:
  - **Consistent**, index is updated synchronously every time a new document is written
  - **Lazy**, when the index is fully updated depends on the demand
  - **None**

A sample indexing policy:

```sh
{
    "indexingMode": "consistent",
    "automatic": true,
    "includedPaths": [
        {
            "path": "/Item/id/?"
        },
        {
          "path": "/Customer/email/?"
        },
        ...
    ],
    "excludedPaths": [
        {
            "path": "/"
        }
    ]
}
```

### Stored procedures

- Written in JS, stored in container;
- Have acccess to the context object, CAN read/write documents;
- The **only way to ensure ACID transactions**, the client-side SDKs do not support transactions;
- Recommended for batch operations;
- Only works within a **single partition**, so you need to give it a partition key value when executing;

```js
// a sample that sends a simple response
function helloWorld() {
    var context = getContext();
    var response = context.getResponse();

    response.setBody("Hello, World");
}
```

### User-defined functions (UDF)

- To extend SQL query grammar and implement custom business logic, such as calculations on properties or documents;
- Can only be called from queries, do not have access to context object, so they **CAN NOT** read or write documents;

```js
// use a UDF to calculate tax based on price
function producttax(price) {
    if (price == undefined  )
        throw 'no input';

    var amount = parseFloat(price);

    if (amount < 1000)
        return amount * 0.1;
    else if (amount < 10000)
        return amount * 0.2;
    else
        return amount * 0.4;
}
```

Then you can use this UDF in a query

```sql
SELECT c.id, c.productId, c.price, udf.producttax(c.price) AS producttax FROM c
```

### Global distribution

You Cosmos DB can be replicated to multiple regions around the globe. It is recommended to add regions based on Azure Paired Regions.

Common scenarios:
- Deliver low-latency data access
- Add regional resiliency for business continuity and disaster recovery (BCDR)

![Comsos DB global distribution](images/azure_cosmosdb-global-distribution.png)

#### Multi-region writes

AKA multi-master support, when you perform writes in a write-enabled region world-wide, written data is propagated to all other regions immediately.

Rarely, conflicts can happen when an item is changed simultaneously in multiple regions. There are three conflict resolution modes offered by Cosmos DB.

- **Last-Writer-Wins (LWW)** - this is the default mode, based on the `_ts` timestamp
- **Custom - User-defined function** - a user-defined function is a special type of stored procedure
- **Custom - Async** - all conflicts are registered in the read-only conflicts feed for deferred resolution

### Consistency levels

![Consistency spectrum](images/azure_cosmosdb-consistency-spectrum.png)

- Consistency levels are guaranteed for all operations regardless of the region from which the reads and writes are served, the number of regions or whether the account is configured with a single or multiple write regions.
- *You set the default consistency level on your Azure Cosmos DB account, which can be overridden by a specific read request.*

| Consistency Level | Guarantees                                                                                   |
| ----------------- | -------------------------------------------------------------------------------------------- |
| Strong            | Linearizability. Reads are guaranteed to return the most recent version of an item.          |
| Bounded Staleness | Consistent Prefix. Reads lag behind writes by at most k prefixes or t interval.              |
| Session           | Consistent Prefix. Monotonic reads, monotonic writes, read-your-writes, write-follows-reads. |
| Consistent Prefix | Updates returned are some prefix of all the updates, with no gaps.                           |
| Eventual          | Out of order reads.                                                                          |

## Redis Caching

Tiers:

- Basic: single server, ideal for dev/testing, no SLA;
- Standard: supports two servers (master/slave), 99.99% SLA;
- Premium: persistence, clustering and scale-out, virtual network;

Best practices:

- Redis works best with data that is 100K or less
- Longer keys cause longer lookup times because they're compared byte-by-byte

Transactions:

- Use `MULTI`, `EXEC` to init and commit a transaction
  - If a command is queued with incorrect syntax, the transaction will be automatically discarded;
  - If a command fails, the transaction will complete as normal;
- There is no rollback;


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

  - Each VM can have three types of disk:
    - **OS disk** (`/dev/sda` on Linux),
    - **Temporary disk**, is a short-term storage (`/mnt` on Linux, page files, swap files), **local to the server, NOT in a storage account**
    - **Data disk**, for database files, website static content, app code, etc
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

### Provisioning

- Custom scripts

  - Imperative, you specify a custom script to be run on a VM, it can update configuration, install software, etc
  - Doesn't work if reboot is required

  ```sh
  # run an custom script extension
  az vm extension set \
    --resource-group $RESOURCEGROUP \
    --vm-name simpleLinuxVM \
    --name customScript \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --settings '{"fileUris":["https://raw.githubusercontent.com/MicrosoftDocs/mslearn-welcome-to-azure/master/configure-nginx.sh"]}' \
    --protected-settings '{"commandToExecute": "./configure-nginx.sh"}'
  ```

  Or add the custom script extension as a resource in the template, *specify that it dependsOn the VM*, so it runs after the VM is deployed
  ```sh
  {
    "name": "[concat(parameters('vmName'),'/', 'ConfigureNginx')]",
    "type": "Microsoft.Compute/virtualMachines/extensions",
    "apiVersion": "2018-06-01",
    "location": "[parameters('location')]",
    "properties": {
      "publisher": "Microsoft.Azure.Extensions",
      "type": "customScript",
      "typeHandlerVersion": "2.0",
      "autoUpgradeMinorVersion": true,
      "settings": {
        "fileUris": [
          "https://raw.githubusercontent.com/MicrosoftDocs/mslearn-welcome-to-azure/master/configure-nginx.sh"
        ]
      },
      "protectedSettings": {
        "commandToExecute": "./configure-nginx.sh"
      }
    },
    "dependsOn": [
      "[resourceId('Microsoft.Compute/virtualMachines/', parameters('vmName'))]"
    ]
  }
  ```

- Desired State Configuration

  - You specify your required VM state in a configuration file
  - PowerShell only
  - Better to be used with Azure Automation State Configuration, otherwise you need to manage your own DSC configuration and orchestration

- Chef

  - You specify a Chef server and recipes to run
  - It uses a Ruby-based DSL

- Terraform

  - Infrastructure as code
  - Supports Azure, AWS, GCP
  - Use Hashicorp Configuration Language (HCL), also supports JSON
  - Managed separate from Azure, you might not be able to provision some types of resources

  ```
  # Configure the Microsoft Azure as a provider
  provider "azurerm" {
      subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }

  # Create a resource group
  resource "azurerm_resource_group" "myterraformgroup" {
      name     = "myResourceGroup"
      location = "eastus"

      tags = {
          environment = "Terraform Demo"
      }
  }

  # Create the virtual machine
  resource "azurerm_virtual_machine" "myterraformvirtual machine" {
      name                  = "myvirtual machine"
      location              = "eastus"
      resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
      network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
      virtual machine_size               = "Standard_DS1_v2"

      storage_os_disk {
          name              = "myOsDisk"
          caching           = "ReadWrite"
          create_option     = "FromImage"
          managed_disk_type = "Premium_LRS"
      }

      storage_image_reference {
          publisher = "Canonical"
          offer     = "UbuntuServer"
          sku       = "16.04.0-LTS"
          version   = "latest"
      }

      os_profile {
          computer_name  = "myvirtual machine"
          admin_username = "azureuser"
      }

      os_profile_linux_config {
          disable_password_authentication = true
          ssh_keys {
              path     = "/home/azureuser/.ssh/authorized_keys"
              key_data = "ssh-rsa AAAAB3Nz{snip}hwhaa6h"
          }
      }

      boot_diagnostics {
          enabled     = "true"
          storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
      }

      tags = {
          environment = "Terraform Demo"
      }
  }
  ```


## Networking

### Virtual network

- Logically isolated network
- Scoped to a single region
- Can be segmented into one or more *subnets*
- Can use a *VPN gateway* to connect to an on-premises network

### Network security group (NSG)

- it's optional
- a software firewall which filters inbound and outbound traffic on the VNet
- can be associated to a **network interface** (per host rules), a **subnet** in the virtual network, or both
- default rules cannot be modified but *can* be overridden
- rules evaluation starts from the **lowest priority** rule, deny rules always stop the evaluation

![network security group](images/azure_network-security-group.png)

### Private Endpoints

![Private endpoints for storage](images/azure_private-endpoints-for-stroage.jpg)

* A private endpoint is a special network interface for an Azure service in your vNet, it gets an IP from the address range of the vNet;
* Connection between the private endpoint and the storage service uses a private link, which traverses only Microsoft backbone network;
* Applications in the vNet can connect to the storage service over the private endpoint seamlessly, **using the same connection string and authorization mechanisms that they would use otherwise**;
* You DON'T need a firewall rule to allow traffic from a vNet that has a private endpoint, since the storage firewall only controls access through the public endpoint. Private endpoints instead rely on the consent flow for granting subnet access;
* You need a separate private endpoint for each storage service in a storage account that you need to access: Blobs, Files, Static Websites, ...;
* For RA-GRS accounts, you should create a separate private endpoint for the secondary instance;

DNS resolution:

Clients on a vNet using the private endpoint should use the same connection string (not using the *privatelink* URL), as clients connecting to the public endpoint. This requires DNS configuration.

Out of vNet:

```sh
# before private endpoint
garystoryagefoo.blob.core.windows.net. 78 IN CNAME blob.syd26prdstr02a.store.core.windows.net.
blob.syd26prdstr02a.store.core.windows.net. 75 IN A 20.150.66.4

# after
garystoryagefoo.blob.core.windows.net. 120 IN CNAME garystoryagefoo.privatelink.blob.core.windows.net.
garystoryagefoo.privatelink.blob.core.windows.net. 119 IN CNAME blob.syd26prdstr02a.store.core.windows.net.
blob.syd26prdstr02a.store.core.windows.net. 119 IN A 20.150.66.4
```

In the vNet (private DNS auto configured):

```sh
# after
garystoryagefoo.blob.core.windows.net. 60 IN CNAME garystoryagefoo.privatelink.blob.core.windows.net.
garystoryagefoo.privatelink.blob.core.windows.net. 9 IN A 10.0.0.5
```

CLI example:

```sh
# get the resource id of the storage account
id=$(az storage account show \
      -g default-rg \
      -n garystoryagefoo \
      --query '[id]' \
      -o tsv
    )

# disable private endpoint network policies for the subnet
az network vnet subnet update \
    --name default \
    --resource-group default-rg \
    --vnet-name default-vnet \
    --disable-private-endpoint-network-policies true

# create private endpoint in a vnet
az network private-endpoint create \
      --name myPrivateEndpoint \
      -g default-rg \
      --vnet-name default-vnet \
      --subnet default \
      --private-connection-resource-id $id \
      --group-id blob \
      --connection-name myConnection

# create a private dns zone
az network private-dns zone create \
    --name "privatelink.blob.core.windows.net"

# link the private dns to a vnet
az network private-dns link vnet create \
    --zone-name "privatelink.blob.core.windows.net" \
    --name MyDNSLink \
    --virtual-network default-vnet \
    --registration-enabled false

# register the private endpoint in the private dns
az network private-endpoint dns-zone-group create \
   --endpoint-name myPrivateEndpoint \
   --private-dns-zone "privatelink.blob.core.windows.net" \
   --name MyZoneGroup \
   --zone-name storage
```

Compare private endpoint and private link service:

- **Azure Private Endpoint**: Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. You can use Private Endpoints to connect to an Azure PaaS service that supports Private Link or to your own Private Link Service.

- **Azure Private Link Service**: Azure Private Link service is a service created by a service provider. Currently, a Private Link service can be attached to the frontend IP configuration of a Standard Load Balancer.

- A Private Link service receives connections from multiple private endpoints. A private endpoint connects to one Private Link service.


### Service endpoints

![Service endpoints overview](images/azure_vnet_service_endpoints_overview.png)

- A virtual network service endpoint provides the identity of your virtual network to an Azure service. Then you can secure the access to an Azure service to a vNet;

- After enabling a service endpoint, the source IP addresses switch from using public IPv4 addresses to using their private IPv4 address when communicating with the service from that subnet. This switch allows you to access the services without the need for reserved, public IP addresses used in IP firewalls.

- With service endpoints, DNS entries for Azure services don't change, continue to resolve to public IP addresses assigned to the Azure service. (**Different from private endpoints**)

- Virtual networks and Azure service resources can be in the same or different subscriptions. Certain Azure Services (not all) such as Azure Storage and Azure Key Vault also support service endpoints across different Active Directory(AD) tenants i.e., the virtual network and Azure service resource can be in different Active Directory (AD) tenants.

**Private endpoints** vs. **service endpoints**:

- Private Endpoints allows you to connect to a service via a private IP address in a vNet, easily extensible to on-prem network;
- A service endpoint remains a publicly routable IP address, scoped to subnets;

### Azure Load Balancer

- Can be used with incoming internet traffic, internal traffic, port forwarding for specific traffic, or outbound connectivity for VMs

Example multi-tier architecture with load balancers

![Azure Load Balancer](images/azure_load-balancer.png)

### Application Gateway

- Is a load balancer for web apps
- Uses Azure Load Balancer at TCP level
- Understands HTTP, applies routing at application layer (L7)

Benefits over a simple LB

- Cookie affinity
- SSL termination
- Web application firewall (WAF): detailed monitoring and logging to detect malicious attacks
- URL rule-based routes: based on URL patterns, source IP and port, helpful when setting up a CDN
- Rewrite HTTP headers: such as scrubing server names

![Application Gateway](images/azure_aplication-gateway.png)

### Traffic Manager

Comparing to Load Balancer:

|                 | Use                                                                                     | Resiliency                                                                                                   |
| --------------- | --------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Load Balancer   | makes your service **highly available** by distributing traffic within the same region  | monitor the health of VMs                                                                                    |
| Traffic Manager | works at the DNS level, directs the client to a preferred endpoint, **reduces latency** | monitors the health of endpoints, when one endpoint is unresponsive, directs traffic to the next closest one |

![Traffic Manager](images/azure_traffic-manager.png)

### Front Door

![Front door](images/azure_front-door.png)

It's like the Application Gateway at a global scale, plus a CDN
  - operates at the edge, not within a vNet
  - resilient to failures to an entire Azure region
  - can cache content
  - a backend can be within or outside Azure

Supports:
  - URL-path based routing
  - health probe: determines the **proximity** and health of each backend
  - cookie-based session affinity
  - SSL offloading
  - WAF
  - URL redirect/rewrite
  - Caching: like a CDN

```sh
az extension add --name front-door

az network front-door create \
  --resource-group myRG \
  --name gary-frontend \
  --accepted-protocols http https \
  --backend-address webapp1.azurewebsites.net webapp2.azurewebsites.net
```

### CDN

- Get content to users in their local region to **minimize latency**
- Can be hosted by Azure or other providers
- Standard Microsoft tier has less features than Akamai and Verizon CDNs
- Asset TTL is determined by the `Cache-Control` header from the origin server, if not set, Azure sets a default value. This can be changed by caching rules.
- In Standard Microsoft tier, you can't set specific caching rules for a file, if you do not want to cache a file, you should set the **`Cache-Control` to be `no-cache` in the origin server**

#### Standard rules engine notes

The rules engine rules are not so easy to debug, the rules takes quite a while to take effect, and the doc is not so detailed or seems to be wrong in some cases.

- https://docs.microsoft.com/en-us/azure/cdn/cdn-standard-rules-engine-match-conditions#url-file-name says multiple file names can be separated with a single space, but
  - If URL file name 'Contains' 'xxx yyy' => matches 'https://garytest.azureedge.net/xxx%20yyy' instead of 'https://garytest.azureedge.net/xxx'
- Some of the operators are numeric, like *Less than* or *Greater than*, example:
  - If URL file name 'Greater than' '6' => matches 'https://garytest.azureedge.net/verylongname'
  - If URL file extension 'Less than or equals' '0' => matches any url without a file extension, eg. 'https://garytest.azureedge.net/foo'
- The doc says *Equals* is a numeric operator, but:
  - If URL path 'Equals' '/abc' => matches 'https://garytest.azureedge.net/abc', does not work if you set a number
- URL path matches the whole path

#### Custom domain HTTPS

Although Azure Vault supports both `.pem` and `.pfx` formats for certificates, when you load it to Azure CDN, only the `.pfx` format is supported (it includes the private key, which is needed in CDN), to convert a certificate from `.pem` to `.pfx`:

```sh
openssl pkcs12 -export -out server.pfx -inkey server.key -in server.crt -certfile root_or_intermediary_cert.crt
```

Common X.509 certificate encoding formats and extensions:

- Base64 (ASCII)
  - PEM
    - .pem
    - .crt
    - .ca-bundle
  - PKCS#7
    - .p7b
    - .p7s
- Binary
  - DER
    - .der
    - .cer
  - PKCS#12
    - .pfx
    - .p12

`*.pem`, `*.crt`, `*.ca-bundle`, `*.cer`, `*.p7b`, `*.p7s` files contain one or more X.509 digital certificate files that use base64 (ASCII) encoding.

A `.pfx` file, also known as PKCS #12, is a single, password protected certificate archive that **contains the entire certificate chain plus the matching private key**. Essentially it is everything that any server will need to import a certificate and private key from a single file.

see:
- https://www.ssls.com/knowledgebase/what-are-certificate-formats-and-what-is-the-difference-between-them/
- https://blog.neilsabol.site/post/azure-cdn-custom-https-secret-contains-unsupported-content-type-x-pkcs12/

## DNS

- Supports private DNS zones, which provide name resolution for VMs within a virtual network, and between virtual networks.
  - Host names for VMs in your virtual network are automatically maintained;
  - Split-horizon DNS support: allows the same domain name to exist in both private and public zones, resolves to the correct one based on the originating request location.

- Alias record sets: allows you to setup alias record to direct traffic to an Azure public IP address(load balancer), an Azure Traffic Manager profile, or an Azure CDN endpoint.
  - It's a dynamic link between a record and a resource, so when the resource's IP changes, it's automatically handled;
  - Supports these record types: A, AAAA, CNAME;

### VPN

Different types:

- **site to site**: your on-premise to vNet
- **point to site**: your local machine to a vNet
  ![Azure VPN point to site](images/azure_vpn-point-to-site.png)
- **vNet to vNet**

#### Point to site

Follow the doc (https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-howto-point-to-site-resource-manager-portal)

The following covers how to generate CA/client certificates on Linux:

```sh
sudo apt install strongswan strongswan-pki libstrongswan-extra-plugins

# generate CA certificates
ipsec pki --gen --outform pem > caKey.pem
ipsec pki --self --in caKey.pem --dn "CN=VPN CA" --ca --outform pem > caCert.pem

# print certificate in base64 format (put this in Azure portal)
openssl x509 -in caCert.pem -outform der | base64 -w0 ; echo
```

Use following script to create client cert/key for multiple users

```sh
#!/bin/bash

USERS=$@

create_cert_key() {
  local PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)
  local U=$1

  echo "$PASSWORD" > "${U}_key_password"
  ipsec pki --gen --outform pem > "${U}_key.pem"
  ipsec pki --pub --in "${U}_key.pem" | ipsec pki --issue --cacert caCert.pem --cakey caKey.pem --dn "CN=${U}" --san "${U}" --flag clientAuth --outform pem > "${U}_cert.pem"

  # create a p12 bundle (need to be installed on client machine to connect to VPN)
  openssl pkcs12 -in "${U}_cert.pem" -inkey "${U}_key.pem" -certfile caCert.pem -export -out "${U}.p12" -password "pass:${PASSWORD}"
}


for U in $USERS; do
  echo "creating cert for ${U}"
  create_cert_key "${U}"
  mkdir "$U"
  mv "${U}_key_password" "${U}_key.pem" "${U}_cert.pem" "${U}.p12" "${U}"
done
```

Then you download a VPNClient package from Azure portal, extract the file, it has clients/configs for Windows, OpenVPN, etc.

  - OpenVPN on Linux
    - make sure openvpn is installed
    ```sh
    sudo apt-get install openvpn network-manager-openvpn network-manager-openvpn-gnome
    ```
    - then create a OpenVPN connection by importing the OpenVPN config file from the package, set your cert file, key file, key password

  - Windows (IKEv2)

    - Open the `.p12` bundle to import client key (need to know the key password)
    - Run the Windows client provided by Azure to create a VPN connection


To revoke a client certificate, use the following scripts to get a client certificate's fingerprint:

```sh
a=$(openssl x509 -in my_cert.pem -fingerprint -noout)
a=${a#*=}       # remove everthing before '='
echo ${a//:}    # remove ':'
```


## App Service

Fully managed web application hosting platform, PaaS.

### App Service plans

A plan's **size** (aka **sku**, **pricing tier**) determines
  - the performance characteristics of the underlying virtual servers
  - features available to apps in the plan

#### SKUs

| Usage      | Tier                 | Instances | New Features                                  |
| ---------- | -------------------- | --------- | --------------------------------------------- |
| Dev/Test   | Free                 | 1         |                                               |
| Dev/Test   | Shared(Windows only) | 1         | Custom domains                                |
| Dev/Test   | Basic                | <=3       | Custom domains/SSL                            |
| Production | Standard             | <=10      | Staging slots, Daily backups, Traffic Manager |
| Production | Premium              | <=20      | More slots, backups                           |
| Isolated   | Isolated             | <=100     | Isolated network, Internal Load Balancing     |

- **Shared compute**: **Free**, **Shared** and **Basic**, VM shared with other customers
- **Dedicated compute**: only apps in the same plan can share the same compute resources
- **Isolated**: network isolation on top of compute isolation, using App Service Environment(ASE)

Plans are the unit of billing. How much you pay for a plan is determined by the plan size(sku) and bandwidth usage, not the number of apps in the plan.

You can start from an cheaper plan and scale up later.

### Deployment

There are multiple ways to deploy an app:

- Azure DevOps
- GitHub (App Service can setup a GitHub action for you)
- BitBucket
- Local Git: You will be given a remote git url, pushing to it triggers a build.
- OneDrive
- Dropbox
- FTP
- CLI

  Example:

  ```sh
  # get all variables
  APPNAME=$(az webapp list --query [0].name --output tsv)
  APPRG=$(az webapp list --query [0].resourceGroup --output tsv)
  APPPLAN=$(az appservice plan list --query [0].name --output tsv)
  APPSKU=$(az appservice plan list --query [0].sku.name --output tsv)
  APPLOCATION=$(az appservice plan list --query [0].location --output tsv)

  # go to your app directory
  cd ~/helloworld

  # deploy current working directory as an app
  az webapp up \
    --name $APPNAME \
    --resource-group $APPRG \
    --plan $APPPLAN \
    --sku $APPSKU \
    --location "$APPLOCATION"

  # set as default
  az configure --defaults web=garyapp

  # open the app
  az webapp browse

  # live logs
  az webapp log tail
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
# `--name` here is the task name, not image name
az acr task create
  --name buildwebapp \
  --registry <container_registry_name> \
  --image webimage \
  --context https://github.com/MicrosoftDocs/mslearn-deploy-run-container-app-service.git --branch master \
  --file Dockerfile \
  --git-access-token <access_token>
```

The above command creates a task `buildwebapp`, creates a webhook in the GitHub repo using an access token, this webhook triggers image rebuild in ACR when repo changes.

### Authentication options

| Method                               | How                                                                                                   | Scenarios                                                                                                                                | RBAC                            | Limitations                                                     |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- | --------------------------------------------------------------- |
| Individual AD identity               | `az acr login`                                                                                        | interactive push/pull by dev/testers                                                                                                     | Yes                             | AD token must be renewed every 3 hours                          |
| Admin user                           | `docker login`                                                                                        | interactive push/pull by individual dev/tester                                                                                           | No, always pull and push access | Single account per registry, not recommended for multiple users |
| Integrate with AKS                   | Attach registry when AKS cluster created or updated                                                   | Unattended pull to AKS cluster                                                                                                           | No, pull access only            | Only for AKS cluster                                            |
| Managed identity for Azure resources | `docker login` / `az acr login`                                                                       | Unattended push from Azure CI/CD, Unattended pull to Azure services                                                                      | Yes                             | Only for Azure services that support managed identities         |
| AD service principal                 | `docker login` / `az acr login` / Registry login settings in APIs or tooling / Kubernetes pull secret | Unattended push from CI/CD, Unattended pull to Azure or external services                                                                | Yes                             | SP password default expiry is 1 year                            |
| Repository-scoped access token       | `docker login` / `az acr login`                                                                       | Interactive push/pull to repository by individual dev/tester, Unattended push/pull to repository by individual system or external device | Yes                             | Not integrated with AD                                          |


#### Individual AD identity

```sh
az acr login --name <acrName>
```

- The CLI uses the token created when you executed `az login` to seamlessly authenticate your session with your registry;
- Docker CLI and daemon must by running in your env;
- `az acr login` uses the Docker client to set an Azure AD token in the `docker.config` file;
- Once logged in, your credentials are cached, valid for 3 hours;

If Docker daemon isn't running in your env, use `--expose-token` parameter

```sh
# expose an access token
az acr login -name <acrName> --expose-token
# {
#   "accessToken": "eyJhbGciOiJSUzI1NiIs[...]24V7wA",
#   "loginServer": "myregistry.azurecr.io"
# }

# use a special username and accessToken as password to login
docker login myregistry.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password eyJhbGciOiJSUzI1NiIs[...]24V7wA
```


#### Service principal

Best suited for **headless scenarios**, that is, any application/service/script that must push or pull container images in an automated manner.

Create a service principal with the following script, which output an ID and password (also called *client ID* and *client secret*)

*Note that this principal's scope is limited to a specific registry*

```sh
#!/bin/bash

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant
ACR_NAME=<container-registry-name>
SERVICE_PRINCIPAL_NAME=acr-service-principal

# Obtain the full registry ID for subsequent command args
ACR_REGISTRY_ID=$(az acr show \
                    --name $ACR_NAME \
                    --query id \
                    --output tsv)

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
SP_PASSWD=$(az ad sp create-for-rbac \
              --name http://$SERVICE_PRINCIPAL_NAME \
              --scopes $ACR_REGISTRY_ID \
              --role acrpull \
              --query password \
              --output tsv)
SP_APP_ID=$(az ad sp show \
              --id http://$SERVICE_PRINCIPAL_NAME \
              --query appId \
              --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $SP_APP_ID"
echo "Service principal password: $SP_PASSWD"
```

For existing principal

```sh
#!/bin/bash

ACR_NAME=mycontainerregistry
SERVICE_PRINCIPAL_ID=<service-principal-ID>

ACR_REGISTRY_ID=$(az acr show \
                    --name $ACR_NAME \
                    --query id \
                    --output tsv)

# Assign the desired role to the service principal. Modify the '--role' argument
az role assignment create \
  --assignee $SERVICE_PRINCIPAL_ID \
  --scope $ACR_REGISTRY_ID \
  --role acrpull
```

Then you can

- Use with docker login

  ```sh
  # Log in to Docker with service principal credentials
  docker login myregistry.azurecr.io \
    --username $SP_APP_ID \
    --password $SP_PASSWD
  ```

- Use with certificate

  ```sh
  # login with service principal certificate file (which includes the private key)
  az login --service-principal
    --username $SP_APP_ID \
    --tenant $SP_TENANT_ID \
    --password /path/to/cert/pem/file

  # then authenticate with the registry
  az acr login --name myregistry
  ```

### Replication

A registry can be replicated to multiple regions, this allows for
- Network-close registry access
- No additional egress fees, as images are pulled from the same region as your container host

```sh
az acr replication create --registry $ACR_NAME --location japaneast
az acr replication list --registry $ACR_NAME --output table
```


## Container Instance

- Fit for executing run-once tasks like image rendering or building/testing applications;
- Billed by seconds;

Some options:

- `--restart-policy` one of 'Always', 'Never' or 'OnFailure'
- `--environment-variables`: environment variables
- `--secure-environment-variables`: secure environment variables


```sh
az container create \
  --resource-group learn-deploy-aci-rg \
  --name mycontainer \
  --image microsoft/aci-helloworld \
  --ports 80 \
  --dns-name-label $DNS_NAME_LABEL \
  --location eastus

# OR
# create a container instance using an image from ACR
# you need to provide registry url/username/password
az container create \
    --resource-group learn-deploy-acr-rg \
    --name acr-tasks \
    --image $ACR_NAME.azurecr.io/helloacrtasks:v1 \
    --ip-address Public \
    --location <location> \
    --registry-login-server $ACR_NAME.azurecr.io \
    --registry-username [username] \
    --registry-password [password]

# get ip/domain name/state of a container
az container show \
  --resource-group learn-deploy-aci-rg \
  --name mycontainer \
  --query "{IP:ipAddress.ip,FQDN:ipAddress.fqdn,ProvisioningState:provisioningState}" \
  --out table

# IP            FQDN                                     ProvisioningState
# ------------  ---------------------------------------  -------------------
# 40.71.238.13  aci-demo-12631.eastus.azurecontainer.io  Succeeded

# get container logs
az container logs \
  --resource-group learn-deploy-aci-rg \
  --name mycontainer-restart-demo
```

## Key Vault


### Concepts

- Vaults

  Are logical groups of keys and secrets, like folders

- Secrets

  - Name-value pair of strings
  - Can be passwords, SQL connection strings, etc
  - You app can retrive secrets through REST API

- Keys

  - Such as asymmetric master key of Microsoft Azure RMS, SQL Server TDE (Transparent Data Encryption), CLE.
  - Once created or added to a key vault, your app **NEVER** has direct access to the keys.
  - Can be single instanced or be versioned (primary and secondary keys)
  - There are hardware-protected and software-protected keys.

### Usage

- Secrets management
- Key management
  - Encryption keys
  - Azure services such as App Service integrate directly with Key Vault
- Certificate management
  - Provision, manage and deploy SSL/TLS certificate;
  - Request and renew certificates through parternership with certificate authorities

### Security

- Use AAD to authenticate users and applications
- Three kind of actions: Get, List and Set
- Most apps only need 'Get' permission, some may need 'List'

### Vault authentication

Vault uses AAD to authenticate users and apps:

1. Register your app as a service principle in AAD

  - you register your app as a service principle, and assign vault permissions to it;
  - the app uses its password or certificate to get an AAD authentication token;
  - then the app can access Vault secrets using the token;
  - there is a *bootstrapping problem*, all your secrets are securely saved in the Vault, but you still need to keep a secret outside of the vault to access them;

2. Managed identities for Azure resources

  When you enable managed identity on your web app, Azure activates a **separate token-granting REST service** specifically for use by your app, your app request tokens from this service instead of directly from AAD. Your app needs a secret to access this service, but that **secret is injected into your app's environment variables** by App Service when it starts up. You don't need to manage or store the secret value, and nothing outside of your app can access this secret or the managed identity token service endpoint.

  - this registers your app in AAD for you, and will delete the registration if you delete the app or disable its managed identity;
  - managed identities are free, and you can enable/disable it on an app at any time;




### Example

```sh
az keyvault create \
    --name <your-unique-vault-name>

az keyvault secret set \
    --name password \
    --value TOP_SECRET \
    --vault-name <your-unique-vault-name>

# enable managed identity for a App Service app and grant vault access
az webapp identity assign \
    --resource-group <rg> \
    --name <app-name>

az keyvault set-policy \
    --secret-permissions get list \
    --name <vault-name> \
    --object-id <managed-identity-principleid-from-last-step>
```

In Node, Azure provides packages to access Vault secrets:

- `azure-keyvault`:
  - `KeyVaultClient.getSecret`: to read a secret;
  - `KeyVaultClient.getSecrets`: get a list of all secrets;
- `ms-rest-azure` authenticate to Azure:
  - `loginWithAppServiceMSI` login using managed identity credentials available via your environment variables;
  - `loginWithServicePrincipalSecret` login using your service principle secret;

### Best practices

- It's recommended to set up a **separate vault for each environment of each of your applications**, so if someone gained access to one of your vaults, the impace is limited;
- Don't read secrets from the vault everytime, you should cache secret values locally or load them into memory at startup time;


## Monitoring

### Azure Monitor

![Azure Monitor Overview](images/azure_monitor.svg)

- Collects two fundamental types of data:
  - metrics
  - logs
- Functions: analysis, alerting, autoscaling, streaming to external systems
- Collects data automatically, can be extended by:
  - Enabling diagnostics: only get full info about a resource after you have enabled diagnostic logging for it, e.g. SQL Database
  - Adding an agent: e.g. install a Log Analytics agent to a VM
- Can be used to **unify** multiple monitoring solutions:
  - Azure Application Insights and Azure Security Center store their collected data in workspace for Azure Monitor, you can then use Azure Monitor Log Analytics to interactively query the data;
- Use Data Collector API to send data from your custom code

| logs | metrics |
| --- | --- |
| text (can have numeric fields) | numeric values |
| sporadic | at fixed interval |
| record event | describe some aspect of a system |
| identify root causes | performance, alerting |
| Log Analytics workspace | time-series database |

### Azure Security Center

- Collects data from resources such as VMs by using the Log Analytics Agent, and puts it into a workspace;
  - Log Analytics Agent can be provisioned automatically

### Azure Application Insights

- Is an APM (Application Performance Management) service, mostly captures two kinds of data: *events* and *metrics*
- Instrumentation methods:
  - Runtime instrumentation: can be enabled without making any changes to code (Windows IIS web app only, works best with ASP.NET)
  - Build-time instrumentation: by installing SDK to code, enables full functionality, supports custom events
  - Client-side instrumentation: JavaScript SDK, you can configure App Service to inject it automatically (Windows IIS web app only)


### Kusto Query Language

Example:

```
Events
| where StartTime >= datetime(2018-11-01) and StartTime < datetime(2018-12-01)
| where State == "FLORIDA"
| count
```

```
Heartbeat
| summarize arg_max(TimeGenerated, *) by ComputerIP
```

### Alerting

- Metric alerts
- Log alerts
- Activity Log alerts (resource creation, deletion, etc)

## CLI Cheatsheats

```sh
# list resouces
az resource list -g learn-rg -o table

# show details of a resource
az resource show -g learn-rg \
  --resource-type Microsoft.Network/publicIPAddresses
  --name simpleLinuxVMPublicIP \

# delete a resource group
az group delete -g learn-rg
```
