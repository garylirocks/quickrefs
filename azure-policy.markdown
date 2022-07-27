# Azure Policy

- [Overview](#overview)
- [Assignments](#assignments)
- [Effects](#effects)
- [Order of evaluation](#order-of-evaluation)
- [Remediation](#remediation)
- [Conditions](#conditions)
- [RBAC Permissions](#rbac-permissions)
- [Best practices](#best-practices)
- [Gotchas](#gotchas)


## Overview

- Policies apply and enforce rules your resources need to follow, such as:

  - only allow specific types of resources to be created;
  - only allow resources in specific regions;
  - enforce naming conventions;
  - specific tags are applied;

- A group of policies is called an **initiative**, it's recommended to use initiatives even when there's only a few policies
- Some Azure Policy resources, such as policy definitions, initiative definitions, and assignments are visible to all users.

Three types of objects

- Policy definition
- Initiative definition
- Assignments


## Assignments

Scopes:

| Definition scopes | Assignment scopes                                          |
| ----------------- | ---------------------------------------------------------- |
| management group  | children management groups, subscriptions, resource groups |
| subscription      | subscriptions, resource groups                             |

An assignment could have

- **Excluded scopes**: a property of the assignment, apply to all policies in a set
- **Exemptions**: a separate resource associated with an assignment, you could specify the scope, expiration date and which policies to exempt

## Effects

An assignment could have one of the following effects:

- **Append**:
  - create/update: add additional fields to the requested resource, eg. allowed IPs for a storage account
  - existing: no changes, mark the resource as non-compliant, use "modify" if you need to remediate existing resources
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
  - Used to add, update, or remove properties or tags on a subscription or resource during creation or update
  - A single modify rule can have multiple operations
  - Evaluates before the request gets processed by a Resource Provider
  -  If you're managing tags, it's recommended to use `Modify` instead of `Append` as `Modify` provides additional operation types and the ability to remediate existing resources. However, `Append` is recommended if you aren't able to create a managed identity or `Modify` doesn't yet support the alias for the resource property.
  - When assign a policy with this effect, the assignment must have a managed identity, which
    - should have proper roles for remediation (eg. "Tag Contributor" for tags)
    - needs to be residing in a location
  - Example: tags
    ```json
    "then": {
      "effect": "modify",
      "details": {
          "roleDefinitionIds": [
              "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
          ],
          "conflictEffect": "deny",
          "operations": [
              {
                  "operation": "Remove",
                  "field": "tags['env']"
              },
              {
                  "operation": "addOrReplace",
                  "field": "tags['environment']",
                  "value": "[parameters('tagValue')]"
              }
          ]
      }
    }
    ```
  - Example: property

    ```json
    "then": {
        "effect": "modify",
        "details": {
            "roleDefinitionIds": [
                "/providers/microsoft.authorization/roleDefinitions/17d1049b-9a84-46fb-8f53-869881c3d3ab"
            ],
            "conflictEffect": "audit",
            "operations": [
                {
                    "condition": "[greaterOrEquals(requestContext().apiVersion, '2019-04-01')]",
                    "operation": "addOrReplace",
                    "field": "Microsoft.Storage/storageAccounts/allowBlobPublicAccess",
                    "value": false
                }
            ]
        }
    }
    ```


Evaluation times or events:

- A resource is created or updated
- A new assignment created
- A policy or initiative already assigned to a scope is updated
- Standard compliance evaluation cycle, once every 24 hours
- You could trigger an on-demand scan with `az policy state trigger-scan`

## Order of evaluation

When a request to create or update a resource comes in, Azure Policy creates a list of all assignments that apply to the resource.

Azure Policy evaluate policies in an order determined by policy effects:

- **Disabled**: checked first
- **Append** and **Modify**, they could alter the request
- **Deny**
- **Audit**
- *sends request to Resource Provider (during creation/update)*
- *Resource Provider returns a success code*
- **AuditIfNotExists** and **DeployIfNotExists**: evalute to determine whether additional logging or action is required.


## Remediation

- When you create or update resources, `deployIfNotExists` or `modify` happens automatically
- **But during standard evaluation cycle, existing resources are only marked as non-compliant, you need to create remediation tasks manually to remediate them**
- Remediation tasks deploy the `deployIfNotExists` template or the `modify` operations of the assigned policy
- Uses a managed identity(system or user assigned) that is associated with the policy assignment
- The managed identity needs to be assigned the minimum RBAC roles required
- When using the Portal, Azure Policy automatically grants the managed identity the listed roles once assignment starts
- When using an Azure SDK, **the roles must manually be granted to the managed identity**, the location of the managed identity doesn't impact its operation with Azure Policy

A `deployIfNotExists` or `modify` policy should define the roles it requires:

```json
"details": {
    ...
    "roleDefinitionIds": [
        "/subscriptions/{subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/{roleGUID}",
        "/providers/Microsoft.Authorization/roleDefinitions/{builtinroleGUID}"
    ]
}
```


## Conditions

- There is no support for regex yet
- `like`, `notLike`, you could use one wildcard `*`

    ```
    {
        "field": "type",
        "notLike": "Microsoft.Network/*"
    }
    ```
- Most conditions evaluate *stringValue* case-insensitively
- `match`, `notMatch`, case-sensitive, `#` for a digit, `?` for a letter, `.` matches any character


## RBAC Permissions

- `Owner`: full rights
- `Contributor`: can't create or update definitions and assignments, may trigger resource remediation
- `Reader`: can read definitions and assignments (defined at current scope or any ancestral scopes)
- `User Access Administrator`: needed to grant permissions to the managed identity on `deployIfNotExists` or `modify` assignments


## Best practices

- Creating and assigning initiative definitions even for a single policy definition
- Creating definitions at higher levels, then create the assignment at the next child level
- Put everything in code
- Start with an "audit" effect instead of a "deny" effect to track impact of your policy definition


## Gotchas

- You can't remove/rename parameter(s) when updating a policy/initiative
- New parameters could only be added to an existing policy/initiative if they have a default value

    So with Terraform, you'd better put **md5 hash of the parameters file** in the name of the policy/set, whenever you update/remove/rename a parameter, it would force replacing the old policy/set with a new one.

-
