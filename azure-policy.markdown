# Azure Policy

- [Overview](#overview)
- [Mode](#mode)
- [Assignments](#assignments)
- [Effects](#effects)
- [Order of evaluation](#order-of-evaluation)
- [Remediation](#remediation)
- [Conditions](#conditions)
- [RBAC Permissions](#rbac-permissions)
- [Best practices](#best-practices)
- [Built-in policies](#built-in-policies)
- [Terminology](#terminology)
- [Regulatory Compliance](#regulatory-compliance)
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


## Mode

Depending on whether a policy is targeting an Azure Resource Manager property or a Resource Provider property

- Resource Manager modes

  - **All**: resource groups, subscriptions, and all resource types
    - For most use cases
    - Default for PowerShell, Portal
  - **Indexed**: only evaluate resource types that support tags and location
    - ie. `Microsoft.Network/routeTables/routes` does not support tags and location, so it's not evaluated in this mode
    - Should be used for policies enforcing tags or locations, to prevent resources that don't support tags and locations from showing up as non-compliant
    - But for tags and locations policy on resource groups or subscriptions, you should use `All` mode

- Resource Provider modes

  - `Microsoft.Kubernetes.Data`
  - `Microsoft.KeyVault.Data`: for managing vaults and certificates, could provide compliance information about components (ie. certificates in this case)
  - `Microsoft.Network.Data` for managing Azure Virtual Network Manager custom membership policies using Azure Policy

Resource Provider modes
  - **only support built-in policy definitions**
  - and exemptions are not supported at the component-level


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
- **DenyAction**
  - "DELETE": prevent accidental deletion of critical resources
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
- You could trigger an on-demand scan on a scope with `az policy state trigger-scan -g "rg-gary-playground"`

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

After create or update requests, **`then.details.evaluationDelay`** determines when the existence of the related resources should be evaluated. Allowed values are `AfterProvisioning`, `AfterProvisioningSuccess`, `AfterProvisioningFailure` or an ISO 8601 duration between 0 and 360 minutes. Default is `PT10M` (10 minutes)

**BuiltIn policies usually don't specify the `evaluationDelay`, which means it's 10 minutes. You need to duplicate a builtin policy to change it.**


## Remediation

- When you create or update resources, `deployIfNotExists` or `modify` operations happens automatically
- **But during standard evaluation cycle, existing resources are only marked as non-compliant, you need to create remediation tasks manually to remediate them**
- Remediation tasks deploy the `deployIfNotExists` template or the `modify` operations of the assigned policy
- Uses a managed identity(system or user assigned) that is associated with the policy assignment
- The managed identity needs to be assigned the minimum RBAC roles required
    - When using the Portal, Azure Policy automatically grants the managed identity the listed roles once assignment starts
    - When using an Azure API, **the roles must manually be granted to the managed identity**, for a initiative assignment, it means all the required roles from each member policy
    - The location of the managed identity doesn't impact its operation with Azure Policy

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

- There is NO support for regex yet
- `like`, `notLike`, you could use one wildcard `*`

    ```
    {
        "field": "type",
        "notLike": "Microsoft.Network/*"
    }
    ```
- `match`, `notMatch`, `#` for a digit, `?` for a letter, `.` matches any character, you need to match the whole string, not just part of it
- Most conditions evaluate *stringValue* case-insensitively, but `match`, `notMatch`, use `matchInsensitively`/`notMatchInsensitively` fro case-insensitive matching


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


## Built-in policies

- There are often similar built-in policies with different effects:

    - "Network Watcher should be enabled", which has "AuditIfNotExists" effect, this is in the `Azure Security Benchmark` initiative
    - "Deploy network watcher when virtual networks are created" which has `DeployIfNotExists` effect

- Defender for Cloud (aka Azure Security Center) assigns initiatives automatically to your subscriptions when you enable certain features:

    | When                                                   | Initiative                                                                      | Assignment                                                              |
    | ------------------------------------------------------ | ------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
    | When on-boarding Defender for Cloud for a subscription | Azure Security Benchmark                                                        | ASC Default (subscription: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)        |
    | When Databases plan is enabled ?                       | Configure Azure Defender to be enabled on SQL Servers and SQL Managed Instances | ASC DataProtection (subscription: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) |


## Terminology

- Control: high-level description, not specific to a technology or implementation, eg. Data Protection
- Benchmark: security recommendations for a specific technology, eg. Azure Security Benchmark
- Baseline: implementation of the benchmark on individual Azure service, eg. Azure SQL security baseline


## Regulatory Compliance

- Special initiatives for regulatory compliance, eg. PCI-DSS, HIPAA, ISO 27001, NZISM Restricted Regulatory Compliance initiative
- Has special requirements:
  - The initiative category must be `Regulatory Compliance`
  - Field of each grouping in the initiative:
    - `name` - name of the control
    - `category` - the compliance domain of the control
    - `policyMetadata` - a reference to metadata of the control,
        - The content is defined by Microsoft and read-only
        - Displayed in the Portal on the overview page of a control
        - Could be queried with `az policy metadata`
        - Example:
            ```json
            {
                "properties": {
                    "metadataId": "NIST SP 800-53 R4 AC-1",
                    "category": "Access Control",
                    "title": "Access Control Policy and Procedures",
                    "owner": "Shared",
                    "description": "**The organization:** ... ",
                    "requirements": "**a.** ...",
                    "additionalContentUrl": "https://nvd.nist.gov/800-53/Rev4/control/AC-1"
                },
                "id": "/providers/Microsoft.PolicyInsights/policyMetadata/NIST_SP_800-53_R4_AC-1",
                "name": "NIST_SP_800-53_R4_AC-1",
                "type": "Microsoft.PolicyInsights/policyMetadata"
            }
            ```
- A control often contains multiple policies, but usually there is NOT a one-to-one or complete match between a control and one or more Azure Policies.
- Compliance details page in the Portal shows **compliance info** grouped by control
- Compliance status could be viewed in Defender for Cloud
- An initiative could include Microsoft-responsible controls
  - the policies are of type `static`
  - the evaluation type is "Microsoft Managed"
- The initiative could be built-in or custom


## Gotchas

- You can't remove/rename parameter(s) when updating a policy/initiative
- New parameters could only be added to an existing policy/initiative if they have a default value

    So with Terraform, you'd better put **md5 hash of the parameters file** in the name of the policy/set, whenever you update/remove/rename a parameter, it would force replacing the old policy/set with a new one.

- For resource groups, use `Microsoft.Resources/subscriptions/resourceGroups` as alias, not `Microsoft.Resources/resourceGroups`

- While the Azure Policy VS Code extension is handy for verifying policy rules locally, it has some shortcomings:
  - The policy file name needs to end with `.pd.json`
  - Can't verify rules targeting subscriptions or resource groups
  - It doesn't validate some of the limits, sometimes a rule is fine locally, but would be rejected by Azure when you deploy:
    - 100 "value count" iterations per policy
    - Use of `current()` or `field()` in `count.value`
    - ...
