# Azure Role Based Access Control

- [Overview](#overview)
- [Evaluation](#evaluation)
- [Considerations](#considerations)
  - [Custom roles](#custom-roles)
- [Attribute-based access control (ABAC)](#attribute-based-access-control-abac)
  - [Example scenarios](#example-scenarios)
  - [Conditions in role definition](#conditions-in-role-definition)
- [Azure RBAC roles vs. Azure AD roles](#azure-rbac-roles-vs-azure-ad-roles)
- [PIM for Azure resource roles](#pim-for-azure-resource-roles)
  - [Get eligible assignments or active assignments](#get-eligible-assignments-or-active-assignments)
  - [Self-activate an eligible assignment](#self-activate-an-eligible-assignment)
  - [Azure resource role settings (PIM policies)](#azure-resource-role-settings-pim-policies)
- [CLI](#cli)


## Overview

RBAC allows you to grant access to Azure resources that you control. You do this by creating role assignments, which control how permissions are enforced. There are three elements in a role assignment:

1. Security principal (who)

    ![RBAC principal](images/azure_rbac-principal.png)

2. Role definition (what)

    Four fundamental built-in roles:

    - **Owner** - full access, including the right to delegate access to others
    - **Contributor** - create and manage, but can't delegate access to others
    - **Reader** - view existing resources
    - **User Access Administrator** - manage user access to resources, rather than to managing resources

    Definition for `Contributor`:

    ![RBAC role definition](images/azure_rbac-role.png)

    - `NotActions` are subtracted from `Actions`
    - `dataActions` refer to actions on data within an object, built-in role "Storage Blob Data Reader" has permissions shown below, it can read blob containers and data, but not write or delete them:

      ```
      "permissions": [
        {
          "actions": [
            "Microsoft.Storage/storageAccounts/blobServices/containers/read",
            "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action"
          ],
          "dataActions": [
            "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read"
          ],
        ```

    - All the built-in roles have `"assignableScopes": [ "/" ]`

3. Scope (where)

    ![role scopes hierarchy](images/azure_rbac-scopes.png)


4. Role Assignment

    ![Role Assignment](images/azure_rbac-role-assignment.png)

    ```sh
    # create a role assignment
    az role assignment create \
        --role "Virtual Machine Administrator Login" \
        --assignee $userPrincipalName \
        --scope $vm

    # query role assignment within a scope
    az role assignment list \
        --assignee $userPrincipalName \
        --scope $vm
    ```


## Evaluation

![RBAC evaluation flowchart](images/azure_role-based-access-control-flowchart.png)

*Deny assignments take priority !!*


## Considerations

- Better to assign roles to groups rather than individual users to minimize role assignments
- Use custom roles to control permissions more precisely
- RBAC is an additive model
- Azure policies always apply, no matter who created/updated a resource
- Limits:
  - Up to 2000 role assignments in each subscription, including role assignments at the subscription, resource group, and resource scopes
  - up to 500 role assignments in each management group.

### Custom roles

*Custom roles can't be assigned at tenant or resource level*

| Scope level                                          | Built-in role | Custom role |
| ---------------------------------------------------- | ------------- | ----------- |
| MG (including Root MG), Subscription, Resource group | Yes           | Yes         |
| Resource                                             | Yes           | **No**      |

Example:

```json
{
  "properties": {
    "roleName": "My Custom Role",
    "description": "My custom role for ...",
    "assignableScopes": [
      "/providers/Microsoft.Management/managementGroups/mg-Gary"
    ],
    "permissions": [
      {
        "actions": [
          "*/read",
          // ...
        ],
        "notActions": [],
        "dataActions": [],
        "notDataActions": []
      }
    ]
  }
}
```

- The `assignableScopes` are just the scopes where this custom role could be assigned to, not where it is stored. **The definition is actually tenant-scoped, the role name must be unique within a tenant**.
- You could specify the assignable scopes: either management group, subscription or resource group, CAN'T be a resource


## Attribute-based access control (ABAC)

- Add conditions based on attributes in the context of specific actions.
- A condition filters down permissions granted as a part of the role definition and role assignment.

Currently, conditions can only be added to built-in or custom role assignments that have **blob storage** or **queue storage** **data actions**. Such as assignment of "Storage Blob Data Contributor".

There are several types of attributes you could use:

- `@Resource`
  - Resource attributes: Storage Account name, Blob Container name, tags
- `@Principal`
  - Custom security attributes assigned to users or service principals
- `@Request`
  - Access request attribute, eg. prefix of blobs to be listed
- `@Environment`:
  - `isPrivateLink`
  - `Microsoft.Network/privateEndpoints`, restrict access over a specific PEP
  - `Microsoft.Network/virtualNetworks/subnets`
  - `UtcNow`

See [full list here](https://learn.microsoft.com/en-us/azure/role-based-access-control/conditions-overview#where-can-conditions-be-added)

### Example scenarios

- Read access to blobs
  - with the tag `Project=Apollo`
  - and a path of `logs/2024`
- Read access to blobs
  - with the tag `Project=Apollo`
  - and the user has a matching attribute `Project=Apollo`
- Read access to blobs during a specific date/time range
- Write access to blobs only over a private link or from a specific subnet
- New blobs must include the tag `Project=Apollo`
- Read, write, or delete blobs in containers named `blobs-example-container`

Example code:

```json
(
  (
    !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read'} AND NOT SubOperationMatches{'Blob.List'})
  )
 OR
  (
    @Resource[Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags:Project<$key_case_sensitive$>] ForAnyOfAnyValues:StringEquals @Principal[Microsoft.Directory/CustomSecurityAttributes/Id:Engineering_Project]
  )
)
```

Operation allowed when:

- Not a blob read operation
- Or suboperation is `Blob.List`
- Or blob's `Project` key value matches any values in the user's custom security attribute `Engineering_Project`

### Conditions in role definition

Some builtin roles have condition in role definition.

For example: "Key Vault Data Access Administrator" role allows role assignment, but only for the specified roles, not any role.

```json
{
  "id": "/providers/Microsoft.Authorization/roleDefinitions/8b54135c-b56d-4d72-a534-26097cfdc8d8",
  "properties": {
    "roleName": "Key Vault Data Access Administrator",
    "description": "Manage access to Azure Key Vault by adding or removing role assignments for the Key Vault Administrator, Key Vault Certificates Officer, Key Vault Crypto Officer, Key Vault Crypto Service Encryption User, Key Vault Crypto User, Key Vault Reader, Key Vault Secrets Officer, or Key Vault Secrets User roles. Includes an ABAC condition to constrain role assignments.",
    "assignableScopes": [
      "/"
    ],
    "permissions": [
      {
        "actions": [
          "Microsoft.Authorization/*/read",
          "Microsoft.Authorization/roleAssignments/delete",
          "Microsoft.Authorization/roleAssignments/write",
          "Microsoft.KeyVault/vaults/*/read",
          "Microsoft.Management/managementGroups/read",
          "Microsoft.Resources/deployments/*",
          "Microsoft.Resources/subscriptions/read",
          "Microsoft.Resources/subscriptions/resourceGroups/read",
          "Microsoft.Support/*"
        ],
        "notActions": [],
        "dataActions": [],
        "notDataActions": [],
        "conditionVersion": "2.0",
        "condition": "
          (
            (
              !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})
            )
            OR
            (
              @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId]
              ForAnyOfAnyValues:GuidEquals{
                00482a5a-887f-4fb3-b363-3b7fe8e74483,
                a4417e6f-fecd-4de8-b567-7b0420556985,
                ...
              }
            )
          )
          AND
          (
            (
              !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})
            )
            OR
            (
              @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals{
                00482a5a-887f-4fb3-b363-3b7fe8e74483,
                a4417e6f-fecd-4de8-b567-7b0420556985,
                ...
              }
            )
          )
        "
      }
    ]
  }
}
```


## Azure RBAC roles vs. Azure AD roles

Three different types of roles in Azure:

- **Azure AD roles**
- **RBAC roles**

  The new Authorization system, find them in the **"Access Control (IAM)" menu** under management groups, subscriptions, resource groups or resources

- **Classic subscription administrator roles (Legacy)**

  The three administrator roles when Azure was initially released: Account Administrator, Service Administrator and Co-Administrator


|                             | Azure RBAC roles                                                                                                  | Azure AD roles                                                                      |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| For                         | Azure resources                                                                                                   | Azure Active Directory                                                              |
| Scope                       | management group, subscription, resource group, resource                                                          | tenant level                                                                        |
| How to get role information | Azure portal, Azure CLI (`az role definition list`), Azure PowerShell, Azure Resource Manager templates, REST API | Azure admin portal, Microsoft 365 admin center, Microsoft Graph, AzureAD PowerShell |

![RBAC vs. AAD roles](images/azure_rbac-vs-aad-roles.png)

- Azure AD roles and Azure RBAC roles are independent from one another, AD role assignment does not grant access to Azure resources and vice versa
- As an **Azure AD Global Administrator**, you might not have access to all subscriptions and management groups, but you could elevate your access:
  - This will give yourself the "**User Access Administrator**" role in Azure at root scope(`/`, this seems to be a level higher than root MG, but effectively equal to it)
  - View and assign access in any management group or subscription (e.g. assign yourself the **Owner** role of the root MG)
  - You should remove this elevated access once you have made the changes needed
- Each directory is given a single top-level management group called **Tenant Root Group**
  - has the same id as the tenant
  - allows for global policies and role assignments

To enable the elevated access:

  -  In Azure Portal ("AAD" -> "Properties" -> "Access management for Azure resources")
  -  CLI

      ```sh
      az rest --method post --url "/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01"

      # you need to login again to see the new role assignment
      az logout
      az login
      az role assignment list --role "User Access Administrator" --scope "/"

      # remove the elevated access
      az role assignment delete --role "User Access Administrator" --scope "/"
      ```


## PIM for Azure resource roles

- This uses `Az.Resources` module, which connects to `https://management.azure.com`, NOT the Microsoft Graph API
- If you use a service principal to assign PIM roles for Azure resources, the SP needs to have the "**User Access Administrator**" or "Owner" role over the Azure scope.

### Get eligible assignments or active assignments

```powershell
$scope='<full-resource-id>' // FULL id required
$principal='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# get eligible ones
# - shows inherited permissions from upper scopes
# - shows assignment in sub scopes,
#   - if the scope is a subscription, like `/subscriptions/xxxx`, it shows assignment on children resource groups
#   - but if the scope is a management group like `/providers/Microsoft.Management/managementGroups/xxx`, it doesn't show assignements in children subscriptions
Get-AzRoleEligibilitySchedule -Scope $scope -Filter "principalId eq $principal" `
| Select-Object ScopeDisplayName,ScopeType,PrincipalDisplayName,PrincipalType,RoleDefinitionDisplayName,RoleDefinitionType,EndDateTime,Status `
| Format-Table

# Get active role assignments and who it's been eligible to (could be current user or a containing group):
Get-AzRoleAssignmentSchedule -Scope $scope -Filter "principalId eq $principal" `
| Select-Object ScopeDisplayName,ScopeType,PrincipalDisplayName,RoleDefinitionDisplayName,RoleDefinitionType,EndDateTime,AssignmentType,@{
    n='PIMRoleAssignedTo';
    e={(Get-AzRoleEligibilitySchedule -Scope $_.ScopeId -Name ($_.LinkedRoleEligibilityScheduleId -Split '/' | Select -Last 1)).PrincipalDisplayName}
}`
| Format-Table
```

Usable filters:

- `-Filter "principalId eq $principal"`
  - works for active assignments
  - **DOES NOT** work for a user if the eligible role assignments are on a group, not directly on the user
- `-Filter "asTarget()"` limit to current user/service principal, works even if the eligible assignment is via a group
- `-Filter "atScope()"` limit to specified scope, including inherited roles from ancestor scopes, excluding subscopes
- `-Filter "asTarget() and atScope()"` combined

### Self-activate an eligible assignment

<div style="background: #efd9fd; padding: 1em">
  <em>NOTE: </em><br />
    <ol>
      <li>You can specify ticket system/ticket number</li>
      <li>Scope could be
        <ul>
          <li>management group ("/providers/Microsoft.Management/managementGroups/mg-foo")</li>
          <li>subscription ("/subscriptions/xxxx-xxxx-xxxx-xxxx")</li>
          <li>resource group ("/subscriptions/xxxx-xxxx-xxxx-xxxx/resourceGroups/rg-foo")</li>
        </ul>
      </li>
      <li>Seems there is no easy way to "Deactivate" an assignment via script</li>
    </ol>
</div>

```powershell
$durationInHours = 1
$roleName = "Contributor"
$justification = "Discovery"
$ticketNumber = 'FOO-123'

$guid = (New-Guid).guid
$uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id
$startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$roleId = (Get-AzRoleDefinition -Name $roleName).Id
$subscriptionId = ((Get-AzContext).Subscription).Id

$scope = "/subscriptions/${subscriptionId}"
$fullRoleDefId = "$scope/providers/Microsoft.Authorization/roleDefinitions/${roleId}"

New-AzRoleAssignmentScheduleRequest `
  -RequestType SelfActivate `
  -PrincipalId $uid `
  -Name $guid `
  -Scope $scope `
  -RoleDefinitionId $fullRoleDefId `
  -ScheduleInfoStartDateTime $startTime `
  -ExpirationDuration "PT${durationInHours}H" `
  -ExpirationType AfterDuration `
  -Justification $justification `
  -TicketNumber $ticketNumber `
  -TicketSystem JIRA
```

### Azure resource role settings (PIM policies)

- Also called PIM policies
- Is defined **per role** and **per resource**
  - All assignments for the same role on the same resource get the same role settings
- **Not inherited**, eg. role settings on subscriptions are not inherited at resource group or resource level
- Resource type `/providers/Microsoft.Authorization/roleManagementPolicies`, its structure is like:

  ```json
  {
    "name": "xxxxx",
    "id": "xxxxx",
    "type": "Microsoft.Authorization/roleManagementPolicies"
    "properties": {
      "scope": "<scope-id>",
      "isOrganizationDefault": false,
      "lastModifiedDateTime": "<date-time>",
      "lastModifiedBy": {
        "displayName": "<principal-name>"
      },
      "policyProperties": {
        "scope": {
          "id": "<scope-id>",
          "displayName": "<scope-name>",
          "type": "subscription"
        }
      },
      "rules": [
        //...
      ],
      "effectiveRules": [
        //...
      ]
    }
  }
  ```

- Role settings assignment has resource type `/providers/Microsoft.Authorization/roleManagementPolicyAssignments`, its structure is like

  ```json
  {
    "name": "xxxxx",
    "id": "xxxxx",
    "type": "Microsoft.Authorization/RoleManagementPolicyAssignment"
    "properties": {
      "scope": "<scope-id>",
      "roleDefinitionId": "<role-def-id>",
      "policyId": "<role-management-policy-id>",
      "policyAssignmentProperties": {
        "scope": {
          "id": "<scope-id>",
          "displayName": "<scope-name>",
          "type": "subscription"
        },
        "roleDefinition": {
          "id": "<role-def-id>",
          "displayName": "<role-def-name>",
          "type": "BuiltInRole"
        },
        "policy": {
          "id": "<role-management-policy-id>",
          "lastModifiedBy": {
            "displayName": "<principal-name>"
          },
          "lastModifiedDateTime": "<date-time>"
        }
      },
      "effectiveRules": [
        //...
      ],
    }
  }
  ```


## CLI

- List role assignments in a scope

  ```sh
  # on a subscription
  # `--all` only works with `--subscription`
  # to include assignments above (management groups) and below (RG, resource)
  az role assignment list \
      --assignee <SP name or object id> \
      --subscription sub-test \
      --all \
      -otable

  # on a management group
  # does NOT include assignments on descendant scopes
  # with `--include-inherited`, show inherited assignments if no assignment at current scope
  az role assignment list \
      --assignee '<sp-object-id>' \
      --scope "/providers/Microsoft.Management/managementGroups/mg-test" \
      --include-groups \
      --include-inherited \
      -otable
  ```

  Much easier to use Resource Graph to query assignments for a principal at all scopes all at once:

  ```kusto
  // *********** CAUTION ***********
  // Set authorization scope to "At, above and below"
  authorizationresources
  | where type == "microsoft.authorization/roleassignments"
  | where properties.principalId in (
      "<prinicpal-obj-id-1>",
      "<prinicpal-obj-id-2>"
      )
  | project resourceGroup,
              subscriptionId,
              roleId = tostring(properties.roleDefinitionId),
              principalId = tostring(properties.principalId),
              scope = tostring(properties.scope)
  | extend principalName = case(
      principalId == "<prinicpal-obj-id-1>", "<principal-name-1>",
      principalId == "<prinicpal-obj-id-2>", "<principal-name-2>"
      "Unknown")
  | extend scopeLevel = case(
      scope startswith "/providers", "MG",
      array_length(split(scope, "/")) == 3, "Subscription",
      array_length(split(scope, "/")) == 5, "Resource Group",
      array_length(split(scope, "/")) == 9, "Resource",
      "to-do"
  )
  | join kind = leftouter ( // get MG, subscription name
      resourcecontainers
      | where type in ("microsoft.management/managementgroups", "microsoft.resources/subscriptions")
      | project id, mgName = tostring(properties.displayName), subName = name
  ) on $left.scope == $right.id
  | join kind = leftouter ( // get role name
      authorizationresources
      | where type == "microsoft.authorization/roledefinitions"
      | project id, roleName = tostring(properties.roleName), type = tostring(properties.type)
  ) on $left.roleId == $right.id
  | extend scopeName = case(
      scopeLevel == "MG", mgName,
      scopeLevel == "Subscription", subName,
      scopeLevel == "Resource Group", resourceGroup,
      scopeLevel == "Resource", split(scope, "/")[8],
      "todo"
  )
  | project principalName, type, roleName, scopeLevel, scopeName
  | order by principalName asc, scopeLevel asc
  ```
