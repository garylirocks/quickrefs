# Logic Apps

- [Types and host environments](#types-and-host-environments)
- [Triggers](#triggers)
- [ARM template](#arm-template)
- [Workflow definition](#workflow-definition)
- [Parameter referencing](#parameter-referencing)
- [Connections](#connections)

## Types and host environments

| Type                          | Note                                                                                                                                                |
| ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Consumption (multi-tenant)    | <ul><li>Only one workflow</li><li>Shared infrastructure</li></ul>                                                                                   |
| Consumption (ISE)             | <ul><li>Only one workflow</li><li>Enterprise scale for large workloads</li><li>Can connect to vnet</li></ul>                                        |
| Standard (single-tenant)      | <ul><li>Can have multiple stateful and stateless workflows</li><li>Support vnet and private endpoints</li></ul>                                     |
| Standard (ASEv3 Windows plan) | <ul><li>An app can have multiple workflows</li><li>Fully isolated</li><li>Pay only for the ASE</li><li>Support vnet and private endpoints</li></ul> |

## Triggers

![Trigger types](images/azure_logic-app-trigger-types.png)

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

  - For OAuth connections, you need to authorize manually ?