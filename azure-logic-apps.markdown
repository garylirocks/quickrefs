# Logic Apps

- [Types and host environments](#types-and-host-environments)
- [Networking](#networking)
- [Connectors](#connectors)
  - [Built-in connectors](#built-in-connectors)
  - [Managed connectors](#managed-connectors)
  - [Custom connectors](#custom-connectors)
  - [Connections](#connections)
  - [Triggers](#triggers)
- [ARM template](#arm-template)
- [Workflow definition](#workflow-definition)
- [Parameter referencing](#parameter-referencing)
- [Connections](#connections-1)
- [Deployment](#deployment)

## Types and host environments

| Type                               | Note                                                                                                                                                |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Consumption (multi-tenant)         | <ul><li>Only one workflow</li><li>Shared infrastructure</li></ul>                                                                                   |
| Consumption (ISE) - **deprecated** | <ul><li>Only one workflow</li><li>Enterprise scale for large workloads</li><li>Can connect to vNet</li></ul>                                        |
| Standard (single-tenant)           | <ul><li>Can have multiple stateful and stateless workflows</li><li>Support vNet and private endpoints</li></ul>                                     |
| Standard (ASEv3 Windows plan)      | <ul><li>An app can have multiple workflows</li><li>Fully isolated</li><li>Pay only for the ASE</li><li>Support vNet and private endpoints</li></ul> |

Logic Apps Standard
- Powered by Azure Functions and needs an App Service plan
   - Pricing plans specific to Logic Apps Standad: WS1, WS2, WS3
   - Only Windows-based plan is supported
   - Has a domain name like `logic-app-001.azurewebsites.net`
- Multiple workflows (stateful or stateless) can be created in a single logic app
  - Stateful and stateless have different in-app triggers and actions
- Support local development, execution, debugging
- Improved support for source control and automated deployment
- Fully separates infrastructure from code logic
- Needs a storage account
   - A file share for workflow artifacts
     - including `host.json`, `connections.json`, `workflow.json` (for each workflow), logs, etc
   - Blob containers (`azure-webjobs-hosts`, `azure-webjobs-secrets`) for workflow some configurations, secrets, etc
   - Queues: MS docs mentions scheduling for stateful workflows, but it's needed by stateless workflows as well in my test
   - Tables: MS docs mentions storing states for stateful workflows, but seems needed by stateless workflows as well in my test
- If you want to create a standard logic app using a **private-endpoint only storage account**, you need to
   - set `WEBSITE_CONTENTOVERVNET = 1` when creating the logic app, once created, it can be removed
   - enable "Configuration routing" for the vNet integration
   - private endpoints need to be enabled for all four sub services
   - create a file share in the storage account (may need to do this manually if your pipeline can't do it because of the networking restrictions)


## Networking

A logic app has three sets of IP addresses:

- **Access endpoint IP addresses**: public IP of the logic app
- **Connector outgoing IP addresses**: when an outgoing connection is made via a managed connector
  - You can use service tags, `AzureConnectors` or `AzureConnectors.[region]`
   - The same service tag also represents IP address prefixes used by some prebuilt connectors to make inbound webhook callbacks to Azure Logic Apps
- **Runtime outgoing IP addresses**: when an outgoing connection is made with a built-in connector, such as an HTTP action


## Connectors

- Work with data, events and resources in other apps, systems
- A connector could have both triggers and actions
- Connector types:
  - Built-in (aka. In-App)
  - Managed (aka. Shared)
  - Custom
- Some connectors have both built-in and managed versions

### Built-in connectors

- Run in **the same process** as Azure Logic Apps runtime, high throughput, low latency
- Two types:
  - General
    - Available to both Comsumption and Standad workflows
    - Not tied to a specific service
    - May don't require any specific connection
    - eg. HTTP, Schedule, Control, Data time, Inline Code, ...
  - Service provider-based
    - Mostly Standard workflow only, few available for Comsumption workflows
    - Based on Azure Functions extensibility model
    - They have corresponding managed connector version
    - Provide access to a service, eg. Blob Storage, SQL Server, ...
- You can create **custom built-in connectors** for Standard workflows
- Business-to-business (B2B) built-in operations
  - You might need to create and link an integration account to your Logic Apps resource

### Managed connectors

- Usually tied to a specific service or system
- Usually a connection is required for authentication
- Powered by the connector infrastructure in Azure, hosted, run and managed by Microsoft, shared with Power Platform
- A few have a corresponding built-in version (with better performance, capabilities, and pricing)
- Categories based on workflow type
   - Comsumption workflows:
      - Standard connectors: Blob Storage, Office 365, ...
      - Enterprise connectors (additional cost): SAP, IBM MQ, ...
   - Standard stateful workflows: all under the Azure label
   - Standard stateless workflows: can use both In-App and Shared connectors
- Informal groups:
  - On-premise connectors:
    - Access to on-prem systems, such as SQL Server, SharePoint Server, Oracle DB, ...
    - You must set up **on-premise data gateway**
  - Integration account connectors: transform and validate XML, process B2B messages using AS2/EDIFACT/X12 protocols

### Custom connectors

- Comsumption workflow: create from Swagger-based or SOAP-based APIs
- You can also create built-in connectors based on the Azure Functions extensibility model

### Connections

- Connections are individual resources, type `Microsoft.Web/connections`
   - Not deleted with the Logic App resource
- You can use Azure Policy to block connections based on ID

### Triggers

![Trigger types](images/azure_logic-app-trigger-types.png)

Trigger runtime:

- In-App (Built-in): connectors and triggers that run directly within the Azure Logic Apps runtime
- Shared (Azure): stateful workflows only, connectors and triggers that are Microsoft-managed, hosted, and run in multi-tenant Azure


## ARM template

A typical ARM template for a logic app looks like:

```json
{
   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
   "contentVersion": "1.0.0.0",
   "parameters": {<template-parameters>},    // #1
   "variables": {},
   "functions": [],
   "resources": [
      {
         // Start logic app resource definition
         "name": "[parameters('LogicAppName')]", // Template parameter reference
         "type": "Microsoft.Logic/workflows",
         "location": "[parameters('LogicAppLocation')]", // Template parameter reference
         "properties": {
            "state": "<Enabled or Disabled>",
            "integrationAccount": {
               "id": "[parameters('LogicAppIntegrationAccount')]" // Template parameter reference
            },
            "definition": {
              // <workflow-definition>
              "parameters": {},             // #2
              ...
            },
            "parameters": {},               // #3
            "accessControl": {},
            "runtimeConfiguration": {}
         },
         "tags": {
           "displayName": "LogicApp"
         },
         "apiVersion": "2019-05-01",
         "dependsOn": []
      },

      // Start connection resource definitions
      {
         <connection-resource-definition-1>   // #4
      },
      {
         <connection-resource-definition-2>
      }
   ],
   "outputs": {}
}
```

Be careful, there are two types of parameters:

- #1 Template parameter definitions
- #2 Workflow parameter definitions
- #3 Workflow parameter values
- #4 Connections can be created in Logic Apps, but they are separate Azure resources with their own resource definitions

## Workflow definition

*This is what appears in the workflow code view*

```json
{
  "definition": {
    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {                             // #1
      "$connections": {
          "defaultValue": {},
          "type": "Object"
      }
    },
    "triggers": {
      "myManualTrigger": {                      // #2
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
      "myResponse": {                           // #3
        "type": "Response",
        "kind": "Http",
        "runAfter": {},
        "inputs": {
          "body": "Response from @{workflow().name}  Total area = @{triggerBody()}@{mul( int(triggerOutputs()['relativePathParameters']['height'])  , int(triggerOutputs()['relativePathParameters']['width'])  )}",  // #4
          "statusCode": 200
        }
      }
    },
    "outputs": {}
  },
  "parameters": {                              // #5
    "$connections": {}
  }
}
```

- #1 Workflow parameter definition, can be referenced inside trigger or actions, empty by default, if you create connections to other services and systems through managed connectors, a `$connections` key will be added
- #2 A trigger named `myManualTrigger`, which is an HTTP request trigger, here we define two url path parameters `width` and `height`
- #3 An action named `myResponse`, which output a string, doing an area calculation based on `width` and `height`
- #4 Variables should be inclosed like `@{varName}`
- #5 Workflow parameter values, you can reference template parameters here
- You can trigger this app by visiting a URL like `https://prod-57.westus.logic.azure.com/workflows/90cb01f9a2534ee5a9a0a50f95e5a34b/triggers/myManualTrigger/paths/invoke/{width}/{height}?api-version=2016-10-01&sp=%2Ftriggers%2FmyManualTrigger%2Frun&sv=1.0&sig=nn8JG1P1aOzXFN2lv1haoEQYcRxP4kCaeSyG33yE5sQ`

## Parameter referencing

```json
{
   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
   "contentVersion": "1.0.0.0",
   "parameters": {
      <previously-defined-template-parameters>,
      // Additional template parameters for passing values to use in workflow definition
      "TemplateAuthenticationType": {
         "type": "string",
         "defaultValue": "",
         "metadata": {
            "description": "The type of authentication used for the Fabrikam portal"
         }
      },
      "TemplateFabrikamPassword": {
         "type": "securestring",
         "metadata": {
            "description": "The password for the Fabrikam portal"
         }
      },
      "TemplateFabrikamUserName": {
         "type": "securestring",
         "metadata": {
            "description": "The username for the Fabrikam portal"
         }
      }
   },
   "variables": {},
   "functions": [],
   "resources": [
      {
         // Start logic app resource definition
         "properties": {
            <other-logic-app-resource-properties>,
            // Start workflow definition
            "definition": {
               "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
               "actions": {<action-definitions>},
               // Workflow definition parameters
               "parameters": {
                  "authenticationType": {
                     "type": "string",
                     "defaultValue": "",
                     "metadata": {
                        "description": "The type of authentication used for the Fabrikam portal"
                     }
                  },
                  "fabrikamPassword": {
                     "type": "securestring",
                     "metadata": {
                        "description": "The password for the Fabrikam portal"
                     }
                  },
                  "fabrikamUserName": {
                     "type": "securestring",
                     "metadata": {
                        "description": "The username for the Fabrikam portal"
                     }
                  }
               },
               "triggers": {
                  "HTTP": {
                     "inputs": {
                        "authentication": {
                           // Reference workflow definition parameters
                           "password": "@parameters('fabrikamPassword')",   // #1
                           "type": "@parameters('authenticationType')",
                           "username": "@parameters('fabrikamUserName')"
                        }
                     },
                     "recurrence": {<...>},
                     "type": "Http"
                  }
               },
               <...>
            },
            // End workflow definition
            // Start workflow definition parameter values
            "parameters": {
               "authenticationType": {
                  "value": "[parameters('TemplateAuthenticationType')]" // #2 Template parameter reference
               },
               "fabrikamPassword": {
                  "value": "[parameters('TemplateFabrikamPassword')]"
               },
               "fabrikamUserName": {
                  "value": "[parameters('TemplateFabrikamUserName')]"
               }
            },
            "accessControl": {}
         },
         <other-logic-app-resource-attributes>
      }
      // End logic app resource definition
   ],
   "outputs": {}
}
```

- #1 Reference workflow parameters like `@parameters('fabrikamPassword')`, they are evaluated at workflow runtime
- #2 Reference template parameters like `[parameters('TemplateAuthenticationType')]`, they are evaluated at deployment
- Don't use template parameters in workflow definition directly, pass it in through workflow parameters

Parameters file, referencing secrets from key vaults:

```json
{
   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
   "contentVersion": "1.0.0.0",
   // Template parameter values
   "parameters": {
      <previously-defined-template-parameter-values>,
     "TemplateAuthenticationType": {
        "value": "Basic"
     },
     "TemplateFabrikamPassword": {
        "reference": {
           "keyVault": {
              "id": "/subscriptions/<Azure-subscription-ID>/resourceGroups/<Azure-resource-group-name>/Microsoft.KeyVault/vaults/fabrikam-key-vault"
           },
           "secretName": "FabrikamPassword"
        }
     },
     "TemplateFabrikamUserName": {
        "reference": {
           "keyVault": {
              "id": "/subscriptions/<Azure-subscription-ID>/resourceGroups/<Azure-resource-group-name>/Microsoft.KeyVault/vaults/fabrikam-key-vault"
           },
           "secretName": "FabrikamUserName"
        }
     }
   }
}
```

## Connections

```json
{
   "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
   "contentVersion": "1.0.0.0",
   // Template parameters
   "parameters": {
      "LogicAppName": {<parameter-definition>},
      "LogicAppLocation": {<parameter-definition>},
      "office365_1_Connection_Name": {<parameter-definition>},
      "office365_1_Connection_DisplayName": {<parameter-definition>}
   },
   "variables": {},
   "functions": [],
   "resources": [
      {
         // Start logic app resource definition
         "properties": {
            <...>,
            "definition": {
               <...>,
               "parameters": {
                  // Workflow definition "$connections" parameter
                  "$connections": {
                     "defaultValue": {},
                     "type": "Object"
                  }
               },
               <...>
            },
            "parameters": {
               // Workflow definition "$connections" parameter values to use at runtime
               "$connections": {
                  "value": {
                     "office365": {
                        // Template parameter references
                        "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', parameters('LogicAppLocation'), '/managedApis/', 'office365')]",
                        "connectionId": "[resourceId('Microsoft.Web/connections', parameters('office365_1_Connection_Name'))]",
                        "connectionName": "[parameters('office365_1_Connection_Name')]"
                     }
                  }
               }
            }
         },
         <other-logic-app-resource-information>,
         "dependsOn": [
            "[resourceId('Microsoft.Web/connections', parameters('office365_1_Connection_Name'))]"                        // #1
         ]
         // End logic app resource definition
      },
      // Office 365 Outlook API connection resource definition
      {
         "type": "Microsoft.Web/connections",
         "apiVersion": "2016-06-01",
         // Template parameter reference for connection name
         "name": "[parameters('office365_1_Connection_Name')]",
         // Template parameter reference for connection resource location. Must match logic app location.
         "location": "[parameters('LogicAppLocation')]",
         "properties": {
            "api": {
               // Connector ID
               "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', parameters('LogicAppLocation'), '/managedApis/', 'office365')]"
            },
            // Template parameter reference for connection display name
            "displayName": "[parameters('office365_1_Connection_DisplayName')]"
         }
      }
   ],
   "outputs": {}
}
```

- #1 workflow resource is dependent on the connection resource

Depending on the connection, there are different ways to authorize, you often need to put secrets in `properties.parameterValues`, and pass them in as `securestring`:

  - Storage account access key (Blob could use service principal as well)

    ```json
    // Azure Blob Storage API connection resource definition
    {
      "type": "Microsoft.Web/connections",
      "apiVersion": "2016-06-01",
      "name": "[parameters('azureblob_1_Connection_Name')]",
      "location": "[parameters('LogicAppLocation')]",
      "properties": {
        "api": {
            "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', parameters('LogicAppLocation'), '/managedApis/', 'azureblob')]"
        },
        "displayName": "[parameters('azureblob_1_Connection_DisplayName')]",
        // Template parameter reference for values to use at deployment
        "parameterValues": {
            "accountName": "[parameters('azureblob_1_accountName')]",
            "accessKey": "[parameters('azureblob_1_accessKey')]"
        }
      }
    }
    ```

  - AAD service principal:

    ```json
    {
      <other-template-objects>
      "type": "Microsoft.Web/connections",
      "apiVersion": "2016-06-01",
      "name": "[parameters('azuredatalake_1_Connection_Name')]",
      "location": "[parameters('LogicAppLocation')]",
      "properties": {
          "api": {
            "id": "[concat(subscription().id, '/providers/Microsoft.Web/locations/', 'resourceGroup().location', '/managedApis/', 'azuredatalake')]"
          },
          "displayName": "[parameters('azuredatalake_1_Connection_DisplayName')]",
          "parameterValues": {
            "token:clientId": "[parameters('azuredatalake_1_token:clientId')]",
            "token:clientSecret": "[parameters('azuredatalake_1_token:clientSecret')]",
            "token:TenantId": "[parameters('azuredatalake_1_token:TenantId')]",
            "token:grantType": "[parameters('azuredatalake_1_token:grantType')]"
          }
      }
    }
    ```

  - For OAuth connections, you need to authorize manually, an API connection you authorized could be used by multiple logic apps (see: https://docs.microsoft.com/en-us/azure/logic-apps/logic-apps-deploy-azure-resource-manager-templates#authorize-oauth-connections)


## Deployment

You could deploy a logic app with Terraform, but after you edit something in the graphical designer, you need to convert the JSON definition to Terraform code, not so straightforward.

Check this repo (https://github.com/Azure-Samples/azure-logic-apps-deployment-samples) to see how to deploy logic apps using ARM template and PowerShell script (run locally or in Azure Pipelines)
