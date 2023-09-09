# Azure Role Based Access Control

- [Overview](#overview)
- [Evaluation](#evaluation)
- [Considerations](#considerations)
  - [Custom roles](#custom-roles)
- [Azure RBAC roles vs. Azure AD roles](#azure-rbac-roles-vs-azure-ad-roles)
  - [Custom Azure RBAC roles](#custom-azure-rbac-roles)
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

*Custom roles can't be assigned at resource level*

| Scope level      | Built-in role | Custom role |
| ---------------- | ------------- | ----------- |
| Management group | Yes           | Yes         |
| Subscription     | Yes           | Yes         |
| Resource group   | Yes           | Yes         |
| Resource         | Yes           | **No**      |

Example:

```json
{
  "properties": {
    "roleName": "Billing Reader Plus",
    "description": "Read billing data and download invoices",
    "assignableScopes": [
      "/subscriptions/your-subscription-number"
    ],
    "permissions": [
      {
        "actions": [
          "Microsoft.Authorization/*/read",
          "Microsoft.Billing/*/read",
          "Microsoft.Commerce/*/read",
          "Microsoft.Consumption/*/read",
          "Microsoft.Management/managementGroups/read",
          "Microsoft.CostManagement/*/read",
          "Microsoft.Support/*"
        ],
        "notActions": [],
        "dataActions": [],
        "notDataActions": []
      }
    ]
  }
}
```

*The `assignableScopes` are just the scopes where this custom role could be assigned to, not where it is stored, all custom roles are stored in AAD.*


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
  - Assign yourself "**User Access Administrator**" role in Azure at root scope(`/`)
  - View and assign access in any subscription or management group (e.g. assign yourself the **Owner** role of a management group)
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

### Custom Azure RBAC roles

A custom role definition is like:

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

- You could specify the assignable scopes: either management group, subscription or resource group, CAN'T be a resource
- **The definition is actually tenant-scoped, the role name must be unique within a tenant**

## CLI