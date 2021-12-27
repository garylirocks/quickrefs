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
  - [DevOps](#devops)
- [Resource management](#resource-management)
  - [Azure AD](#azure-ad)
  - [Tenant](#tenant)
  - [Management groups](#management-groups)
  - [Subscription](#subscription)
  - [Resource group](#resource-group)
  - [Tags](#tags)
  - [Policy](#policy)
  - [Locks](#locks)
  - [Resource Group Manager (RGM)](#resource-group-manager-rgm)
  - [Resource Manager templates](#resource-manager-templates)
- [Azure management tools](#azure-management-tools)
  - [CLI](#cli)
  - [PowerShell](#powershell)
- [Business Process Automation](#business-process-automation)
- [Logic Apps](#logic-apps)
- [API Management](#api-management)
  - [Policies](#policies)
  - [Client certificates](#client-certificates)
- [Messaging platforms](#messaging-platforms)
  - [Messages vs. Events](#messages-vs-events)
  - [Service bus](#service-bus)
  - [Storage Queues](#storage-queues)
  - [Event Grid](#event-grid)
  - [Event Hub](#event-hub)
- [Key Vault](#key-vault)
  - [Concepts](#concepts)
  - [Usage](#usage)
  - [Security](#security)
  - [Vault authentication](#vault-authentication)
  - [Example](#example)
  - [Best practices](#best-practices)
- [Monitoring and Analytics](#monitoring-and-analytics)
  - [Azure Monitor](#azure-monitor)
  - [Azure Security Center](#azure-security-center)
  - [Azure Application Insights](#azure-application-insights)
  - [Kusto Query Language](#kusto-query-language)
  - [Alerting](#alerting)
- [Troubleshooting](#troubleshooting)

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
    --template-file basic-template.json \
    --parameters @params.json

# deploy
az deployment group create \
    --name MyDeployment \
    --resource-group learn-63336b5a-694e-4b61-a1a5-1f173253244e \
    --mode [Incremental|Complete] \
    --template-file basic-template.json \
    --parameters @params.json

# verify
az deployment group show \
    --name MyDeployment \
    --resource-group learn-63336b5a-694e-4b61-a1a5-1f173253244e
```

- By default, deployment runs in `Incremental` mode, which leaves existing resources in the RG but not in the template *unchanged*, in `Complete` mode, those resources would be deleted
- For resources in the template, all properties are reapplied, so you need to specify the final state of the resources, NOT only the properties you want to update


## Azure management tools

- Azure Portal

  - Web based, not suitable for repetitive tasks

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

Example

```sh
# set default group and location
az configure \
  --defaults group=<groupName> location=australiasoutheast

# === START create / manage a storage account
# get a random account name
STORAGE_NAME=storagename$RANDOM

# create a storage account
az storage account create \
  --name $STORAGE_NAME \
  --sku Standard_RAGRS \
  --encryption-service blob

# list access keys
az storage account keys list \
  --account-name $STORAGE_NAME

# get connection string (key1 is in the string)
az storage account show-connection-string \
  -n $STORAGE_NAME

# create a container in the account
az storage container create \
  -n messages \
  --connection-string "<connection string here>"
```

Tips
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

## Monitoring and Analytics

![monitoring services](images/azure_monitoring-services.png)

Monitoring servcies in logical groups:

- Core monitoring

  Platform level, built-in to Azure, requires little to no configuration to set up.

  - Activity Log
    - Tracks actions on your resources, eg. VM startup, load balancer config change, etc
    - Log data is retained for 90 days, although you can archive your data to a storage account, or send it to Log Analytics
  - Service Health
    - Identifies any issues with Azure services that might affect your application
    - Helps you plan for scheduled maintenance
  - Azure Monitor (metrics and diagnostics)
    - Provide performance statistics for different resources, eg. VM CPU/RAM usage
    - Could be used for time-critical alerts and notifications
  - Advisor
    - Potential performance, cost, high availability or security issues

- Log Analytics: deep infrastructure monitoring

  ![Log Analytics](images/azure_log-analytics.png)

  - More diagnostic information and metrics, eg. pull information from SQL server, free disk space of VMs, network dependencies between your systems and services
  - Azure Monitor data can be configured to be sent to a Log Analytics workspace
  - VMs can have an agent installed to send data

- Application Insights: APM
  - Identify performance issues, usage trends, and the overall availability of services

### Azure Monitor

![Azure Monitor Overview](images/azure_monitor.svg)

- Collects two fundamental types of data:
  - metrics
  - logs
- Functions: analysis, alerting, autoscaling, streaming to external systems
- Collects some metrics for all resources by default, can be extended by enabling diagnostic or installing an agent:
  - For VMs, Azure collects some metrics(host-level) by default, such as CPU usage, OS disk usage, network traffic, boot success, to get a full set of metrics, you need to install two tools directly on the VM: the Azure Diagnostics extension (not the same as boot diagnostics,which you usually enable while creating a VM) and the Log Analytics agent. (Both tools are available for Windows and Linux)
- Can be used to **unify** multiple monitoring solutions:
  - Azure Application Insights and Azure Security Center store their collected data in workspace for Azure Monitor, you can then use Azure Monitor Log Analytics to interactively query the data;
- Use Data Collector API to send data from your custom code

| logs                           | metrics                          |
| ------------------------------ | -------------------------------- |
| text (can have numeric fields) | numeric values                   |
| sporadic                       | at fixed interval                |
| record event                   | describe some aspect of a system |
| identify root causes           | performance, alerting            |
| Log Analytics workspace        | time-series database             |

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


## Troubleshooting

- Delete a locked file in Azure File Share

  A file may get locked and you cannot delete it, you need to find and close file handle on the file. See https://infra.engineer/azure/65-azure-clearing-the-lock-on-a-file-within-an-azure-file-share

  ```powershell
  # get storage account context
  $Context = New-AzStorageContext -StorageAccountName "StorageAccountName" -StorageAccountKey "StorageAccessKey"

  # find all open handles of a file share
  Get-AzStorageFileHandle -Context $Context -ShareName "FileShareName" -Recursive

  # close a handle
  Close-AzStorageFileHandle -Context $Context -ShareName "FileShareName" -Path 'path/to/file' -CloseAll
  ```

