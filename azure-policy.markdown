# Azure Policy

- [Overview](#overview)
- [Mode](#mode)
- [Aliases](#aliases)
  - [Array aliases](#array-aliases)
- [Assignments](#assignments)
  - [Concepts](#concepts)
- [Effects](#effects)
- [Policy assignment evaluation](#policy-assignment-evaluation)
  - [Time](#time)
  - [Evaluation Order](#evaluation-order)
- [Remediation](#remediation)
- [Conditions](#conditions)
- [RBAC Permissions](#rbac-permissions)
- [Built-in policies](#built-in-policies)
- [Terminology](#terminology)
- [Regulatory Compliance](#regulatory-compliance)
- [Best practices](#best-practices)
  - [Custom policies](#custom-policies)
  - [Exemptions](#exemptions)
  - [Operations](#operations)
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


## Aliases

### Array aliases

Two types

- `Microsoft.Test/resourceType/stringArray`, the array as a whole
- `Microsoft.Test/resourceType/stringArray[*]`, each element

Examples:

```json
// check existence
{
  "field": "Microsoft.Test/resourceType/stringArray",
  "exists": "true"
}

// check array length
{
  "value": "[length(field('Microsoft.Test/resourceType/stringArray'))]",
  "greater": 0
}

// only true if all elements are equal to "value"
// BUT, if the array is empty, then it's always true, use count expression instead
{
  "field": "Microsoft.Test/resourceType/stringArray[*]",
  "equals": "value"
}

// check `property` of each element in `objectArray`
{
  "field": "Microsoft.Test/resourceType/objectArray[*].property",
  "equals": "value"
}

// count expression
{
  "count": {
    "field": "Microsoft.Test/resourceType/stringArray[*]"
  },
  "equals": 3
}

// in `where`, `[*]` only refere to one element in each interation
{
  "count": {
    "field": "Microsoft.Test/resourceType/stringArray[*]",
    "where": {
      "field": "Microsoft.Test/resourceType/stringArray[*]",
      "equals": "a"
    }
  },
  "equals": 1
}
```

For a resource like this

```json
{
  "tags": {
    "env": "prod"
  },
  "properties":
  {
    "stringArray": [ "a", "b", "c" ],
    "objectArray": [
      {
        "property": "value1",
        "nestedArray": [ 1, 2 ]
      },
      {
        "property": "value2",
        "nestedArray": [ 3, 4 ]
      }
    ]
  }
}
```

- `[field('Microsoft.Test/resourceType/objectArray[*].nestedArray')]` is `[[ 1, 2 ], [ 3, 4 ]]`
- `[field('Microsoft.Test/resourceType/objectArray[*].nestedArray[*]')]` is`[1, 2, 3, 4]`


## Assignments

Scopes:

| Definition scopes | Assignment scopes                                          |
| ----------------- | ---------------------------------------------------------- |
| management group  | children management groups, subscriptions, resource groups |
| subscription      | subscriptions, resource groups                             |

An assignment could have

- **Excluded scopes**: a property of the assignment, apply to all policies in a set
- **Exemptions**: a separate resource associated with an assignment, you could specify the scope, expiration date and which policies to exempt

### Concepts

- Resource selectors

  - Can be added to an assignment
  - One selector could have rules based on locations and resource types.
  - When multiple selectors are added, resources matching any selector will be evaluated
  - This helps gradual rollout of the policy


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
  - The audit occurs if there are no related resources(defined by `then.details`) or if none of the related resources satisfy `then.details.ExistenceCondition`. The resource defined in **if** condition is marked as non-compliant.
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


## Policy assignment evaluation

### Time

Evaluation times or events:

- A resource is created or updated
- A new assignment created
- A policy or initiative already assigned to a scope is updated
- Standard compliance evaluation cycle, once every 24 hours
- You could trigger an on-demand scan on a scope with `az policy state trigger-scan -g "rg-gary-playground"`

### Evaluation Order

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
  - When using the Portal, Azure Policy automatically creates a system-assigned MI, and grants it the required roles
  - When using an Azure API, **the roles must manually be granted to the managed identity**, for a initiative assignment, it means all the required roles from each member policy
  - The location of the managed identity doesn't impact its operation with Azure Policy
  - Use system-assigned managed identity if you can, it can only be used by the policy assignment, eliminates malicious usage
  - Use user-assigned MI to reduce the number of role assignments

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


## Built-in policies

- There are often similar built-in policies with different effects:

    - "Network Watcher should be enabled", which has `AuditIfNotExists` effect, this is in the `Azure Security Benchmark` initiative
    - "Deploy network watcher when virtual networks are created" which has `DeployIfNotExists` effect

- Defender for Cloud (aka Azure Security Center) assigns initiatives automatically to your subscriptions when you enable certain features:

    | When                                                   | Initiative                                                                      | Assignment                                                              |
    | ------------------------------------------------------ | ------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
    | When on-boarding Defender for Cloud for a subscription | Azure Security Benchmark                                                        | ASC Default (subscription: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)        |
    | When Databases plan is enabled ?                       | Configure Azure Defender to be enabled on SQL Servers and SQL Managed Instances | ASC DataProtection (subscription: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) |

- Defender for Cloud depends on the "Azure Security Benchmark" assignment on each subscription.
  - Policies in "ASC Default (subscription: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)" are set to "Audit", "auditIfNotExists" or "Disabled"
  - Some effects should be set to "Deny", it is best to create a new assignment at a MG to change the effects centrally, once done you should remove the auto-created assignment to avoid overlaps.


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


## Best practices

- Create and assign initiative definitions, even for a single policy definition
- Creating definitions at higher levels, then create the assignment at the next child level
- Put everything in code
- Start with an "audit" effect instead of a "deny" effect to track impact of your policy definition
- Set "Enforcement mode" to `Disabled` instead of using "Audit" effect for `Modify` and `DeployIfNotExists (DINE)` policies
  - So you don't need to update the policy definitions
- When "Enforcement mode" is Disabled
  - The assignment effectively becomes an audit-only policy
  - It will NOT generate any policy compliance entries in the resource's activity log
  - Remediation task can still be triggered.
- DINE or Modify policies should only deploy/configure auxiliary or supporting resources, NOT workloads.
- Reassign the Azure Security Benchmark at a MG level, see [Built-in policies](#built-in-policies)
- Limit the number of initiatives (less than 5 ?)
- `Modify` and `Append` can interfere with desired state deployment tools (eg. Terraform), use `ignore_changes` in Terraform

### Custom policies

- **Avoid** custom policies if you can !
- The name should be a GUID or a unique name within your company
- Use `displayName` and `description`
- `metadata.version` should use semantic versioning
- `metadata.category` should be one of the categories in the built-in Policies and Policy Sets
- Do not include system generated properties:
  - `properties.policyType`
  - `properties.metadata`
    - `createdOn`
    - `createdBy`
    - `updatedOn`
    - `updatedBy`
- `effect` should always be a parameter, see https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/azure-policy-recommended-practices/ba-p/3798024
- `Append`, `Modify` and `DeployIfNotExists` only works if the required parameters are known at the time of assignment.
- For custom initiatives,
  - all the policy-level parameters should be surfaced, you'll need to prefix the parameter names with the policy name, eg. `effect` -> `policy1_effect`
  - use a short form of the policy `displayName` as `policyDefinitionReferenceId`

### Exemptions

- Two types:
  - Mitigated: often for permanent exemptions
  - Waiver: temporary
- Add a link the work item in the metadata to track why an exemption was granted
- Exemptions are not deleted along with the assignment, you need to delete it explicitly
- `notScopes` applies to all policies in an initiative, while an exemption only targets one policy

### Operations

- Operational tasks (eg. Remediation tasks, generating documentation) **must be scripted**, then run the scripts when needed
- **DO NOT use CI/CD tools (including Terraform) to execute the operational tasks**, CI/CD is intended to deploy resources, not to operatate them


## Gotchas

- You can't remove/rename parameter(s) when updating a policy/initiative
- New parameters could only be added to an existing policy/initiative if they have a default value

    So with Terraform, you'd better put **md5 hash of the parameters file** in the name of the policy/set, whenever you update/remove/rename a parameter, it would force replacing the old policy/set with a new one.

- For resource groups, use `Microsoft.Resources/subscriptions/resourceGroups` as alias, not `Microsoft.Resources/resourceGroups`

- While the Azure Policy VS Code extension is handy for verifying policy rules locally, it has some shortcomings:
  - Sometimes it doesn't work in WSL, restart the computer and try again
  - The policy file name needs to end with `.pd.json`
  - The policy definition JSON format is a bit different from what you get from the Portal, move things out of `properties`, the format needs to be like:
    ```json
    {
      "displayName": "My policy name",
      "policyType": "Custom",
      "parameters": {
        //...
      },
      "policyRule": {
        "if": {
          //...
        },
        "then": {
          //...
        }
      },
      "id": "...",
      "name": "my_policy_name"
    }
    ```
  - Can't verify rules targeting subscriptions or resource groups
  - It doesn't validate some of the limits, sometimes a rule is fine locally, but would be rejected by Azure when you deploy:
    - 100 "value count" iterations per policy
    - Use of `current()` or `field()` in `count.value`
    - ...
