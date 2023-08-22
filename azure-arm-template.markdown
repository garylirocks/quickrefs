# Resource Manager template

- [Overview](#overview)
- [Template file syntax](#template-file-syntax)
- [CLI](#cli)
- [Nested template](#nested-template)
- [Linked template](#linked-template)
- [Scopes](#scopes)
  - [Deployment location and name](#deployment-location-and-name)
- [Resource group scope](#resource-group-scope)
  - [Scopes](#scopes-1)
- [Template specs](#template-specs)

## Overview

- JSON file that defines the resources you need to deploy
- Idempotent, multiple deployments create resources in the same state
- For resources deployed based on a template, after you update and redeploy the template, the resources will reflect the changes
- With parameters, you can use the same template to create multiple versions of your infrastructure, such as staging and production
- Modular: you can create small templates and combine them

## Template file syntax

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

- Expressions need to be enclosed in brackets `[variables('var1')]`
- `reference()`, `parameters()` and `variables()` etc are functions
- Parameters can be of type
  - string
  - secureString
  - integers
  - boolean
  - object
  - secureObject
  - array
- Resource type is in the format **`{resource-provider}/{resource-type}`**, like `Microsoft.Compute/virtualMachines`, common resource providers include:
  - Microsoft.Compute
  - Microsoft.Network
  - Microsoft.Storage
  - Microsoft.Web

- A resource type could be a child of another resource type,
  - such as virtual network peering's type is `Microsoft.Network/virtualNetworks/virtualNetworkPeerings`
  - to create parent and child resources in one deployment, the child resource could be put outside the parent resource, but its `type` and `name` need to be scoped, and it needs `dependsOn`, do it like:

    ```json
    "resources": [
      {
        "type": "Microsoft.Network/virtualNetworks",
        "apiVersion": "2020-05-01",
        "name": "[parameters('vnetName')]",
        "location": "eastus",
        "properties": {
          // ...
        }
      },
      {
        // type name scoped under parent type
        "type": "Microsoft.Network/virtualNetworks/virtualNetworkPeerings",
        "apiVersion": "2020-05-01",
        // name scoped under parent name
        "name": "[concat(parameters('vnetName'), '/peer-to-', parameters('existingVnetName'))]",
        "properties": {
          // ...
        },
        // need this
        "dependsOn": [
          "[resourceId('Microsoft.Network/virtualNetworks', parameters('vnetName'))]"
        ]
      }
    ]
    ```

## CLI

```sh
# validate a template file
az deployment group validate \
    --resource-group my-RG \
    --template-file basic-template.json \
    --parameters @params.json

# deploy (parameters on command line)
az deployment group create \
  --name my-deployment \
  --template-file basic-template.json \
  --parameters adminUsername=gary

# deploy (with a parameters file)
az deployment group create \
    --name MyDeployment \
    --resource-group my-RG \
    --mode [Incremental|Complete] \
    --template-file basic-template.json \
    --parameters @params.json

# show deployment status
az deployment group show \
    --name MyDeployment \
    --resource-group my-rg

# get an output value from the result
az deployment group show \
    --name MyDeployment \
    --resource-group my-RG
    --query "properties.outputs.hostname.value"

```

Manage deployments:

```sh
# show deployment in a resource group
az deployment group list -g my-rg -otable
# Name         State       Timestamp                         Mode         ResourceGroup
# -----------  ----------  --------------------------------  -----------  -------------
# my-tempate    Succeeded  2022-02-21T22:21:58.747976+00:00  Incremental  my-rg
# my-tempate-2  Succeeded  2022-02-21T22:21:58.747976+00:00  Incremental  my-rg

# this deletes the deployment metadata, leaving the deployed resources UNAFFECTED
az deployment group delete -g my-rg --name my-template
```

- By default, deployment runs in `Incremental` mode, which leaves existing resources in the RG but not in the template *unchanged*, in `Complete` mode, those resources would be deleted
- For resources in the template, all properties are reapplied, so you need to specify the final state of the resources, NOT only the properties you want to update

## Nested template

- The main template includes a 'deployment' resource with an embedded template
- Deployment mode could only be `Incremental`

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "variables": {},
  "resources": [
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2021-04-01",
      "name": "nestedTemplate1",
      "properties": {
        "mode": "Incremental",
        "template": {
          <nested-template-syntax>
        }
      }
    }
  ],
  "outputs": {
  }
}
```


## Linked template

It's like the a nested template, but instead of nested directly within the main template, the linked template is referenced via a link from the main template.

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "variables": {},
  "resources": [
    {
      "type": "Microsoft.Resources/deployments",
      "apiVersion": "2021-04-01",
      "name": "linkedTemplate",
      "properties": {
        "mode": "Incremental",
        "templateLink": {
          "uri":"https://mystorageaccount.blob.core.windows.net/AzureTemplates/newStorageAccount.json",
          "contentVersion":"1.0.0.0"
        }
      }
    }
  ],
  "outputs": {
  }
}
```

- The `templateLink.uri` can't be a local file, it needs to be a downloadable HTTP or HTTPS URL accessible to Azure Resource Manager.
- You could construct the URL using parameters, like:

  ```
  "uri": "[concat(parameters('_artifactsLocation'), '/path/to/my-template.json', parameters('_artifactsLocationSasToken'))]"
  ```

## Scopes

- You could have templates at different scopes for scope specific resources, such as:
  - 'resourceGroups' can only be at Subscription level
  - 'roleAssignments' could be at Tenant, Management Group, Subscription, Resource Group level
  - 'deployment' could be at Tenant, Management Group, Subscription, Resource Group level

- Specify the level and action in the CLI command like this:

  ```sh
  az deployment [group|sub|mg|tenant] [validate|create|show|delete|...]
  ```

- The schemas you use for deployment at different levels are different, in VS Code, the ARM Tools extension could help generate scaffolding snippets for you.

### Deployment location and name

```sh
az deployment sub create \
  --name demoSubDeployment \
  --location eastus \
  --template-file "azuredeploy.json" \
  --parameters x=1
```

- For Resource Group scope deployment, the location of the resource group is used to store the deployment data.
- For other levels, you need to specify the location, it's just for the deployment data, not the actual resources.
- You can optionally provide a deployment name, otherwise the template file name would be used.
- Deployment name needs to be **unique** across locations, if you have deployment named "azuredeploy" in `eastus`, you can't use the same deployment name in `westus`.

## Resource group scope

### Scopes

With nested deployment, you are not limited to the target resource group, you could actually deploy to other resource groups, subscriptions or the tenant.

- The target resource group

  ```json
  {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "resources": [
      //** resources here **
    ],
  }
  ```

- Another resource group (same or different subscription)

  Both `subscriptionId` and `resourceGroup` for the nested deployment are **optional**, if missing, values from the parent template are used

  ```json
  {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "resources": [
      {
        "type": "Microsoft.Resources/deployments",
        "apiVersion": "2021-04-01",
        "name": "nestedDeployment",
        "subscriptionId": "00000000-0000-0000-0000-000000000000",
        "resourceGroup": "demoResourceGroup",
        "properties": {
          "mode": "Incremental",
          "template": {
            // ** template here **
          }
        }
      }
    ],
    "outputs": {}
  }
  ```

- Another subscription

  Specify `subscriptionId` and `location` for the nested deployment

  ```json
  {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "resources": [
      {
        "type": "Microsoft.Resources/deployments",
        "apiVersion": "2021-04-01",
        "name": "nestedDeployment",
        "location": "centralus",
        "subscriptionId": "0000000-0000-0000-0000-000000000000",
        "properties": {
          "mode": "Incremental",
          "template": {
            // ** template here **
          }
        }
      }
    ],
    "outputs": {}
  }
  ```

- Tenant

  Specify `location`, and set `scope` to be `/` for the nested deployment

  ```json
  {
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "resources": [
      {
        "type": "Microsoft.Resources/deployments",
        "apiVersion": "2021-04-01",
        "name": "nestedDeployment",
        "location": "centralus",
        "scope": "/",
        "properties": {
          "mode": "Incremental",
          "template": {
            // ** template here **
          }
        }
      }
    ],
    "outputs": {}
  }
  ```


## Template specs

A template spec is a stored ARM template in Azure
  - Its resource type is `Microsoft.Resources/templateSpecs`
  - You can use RBAC for access control
  - Anyone with read access can deploy it
  - If the main template references linked templates, all of them will be packaged together
  - Supports versioning
  - A template spec itself could be used in another template

```sh
# create a template spec
az ts create \
  --name my ts-test-001 \
  --version "1.0a" \
  --resource-group rg-template-spec \
  --location "westus2" \
  --template-file "./mainTemplate.json"

# get the ID of a template spec
id = $(az ts show --name storageSpec --resource-group templateSpecRG --version "1.0a" --query "id")

# deploy with parameters on command line
az deployment group create \
  --resource-group rg-demo \
  --template-spec $id \
  --parameters storageAccountType='Standard_GRS'

# deploy with a parameter file
az deployment group create \
  --resource-group rg-demo \
  --template-spec $id \
  --parameters "./mainTemplate.parameters.json"
```
