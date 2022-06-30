# Azure Policy

- [Overview](#overview)
- [Assignments](#assignments)
- [Effects](#effects)
- [Order of evaluation](#order-of-evaluation)
- [Remediation](#remediation)
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
  - When assign a policy with this effect, the assignment must have a managed identity, which
    - should have proper roles for remediation (eg. "Tag Contributor" for tags)
    - needs to be residing in a location

Evaluation times or events:

- A resource is created or updated
- A new assignment created
- A policy or initiative already assigned to a scope is updated
- Standard compliance evaluation cycle, once every 24 hours

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

For making existing resources compliant


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

So with Terraform, you'd better put md5 hash of the parameters file in the name of the policy/set, whenever you update/remove/rename a parameter, it would force replacing the old policy/set with a new one.