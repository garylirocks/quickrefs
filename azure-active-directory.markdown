# Azure AD

- [Editions](#editions)
- [Azure AD vs. AD DS vs. Azure AD DS](#azure-ad-vs-ad-ds-vs-azure-ad-ds)
  - [Azure AD DS](#azure-ad-ds)
- [Azure AD Join](#azure-ad-join)
- [Best practices](#best-practices)
- [Users](#users)
- [Groups](#groups)
- [Administrative Units](#administrative-units)
- [App registrations](#app-registrations)
- [Providing identities to services](#providing-identities-to-services)
- [Role-based access control (RBAC)](#role-based-access-control-rbac)
  - [Azure RBAC roles vs. Azure AD roles](#azure-rbac-roles-vs-azure-ad-roles)
- [Logging and analytics](#logging-and-analytics)


Overview:

- Each Azure subscription is associated with a single Azure AD directory (tenant);
- Users, groups and applications in that directory can manage resources in the subscription;
- Subscriptions use Azure AD for SSO;
- Microsoft 365, Office 365, Azure, and Dynamics CRM Online use Azure AD, a tenant in these services is automatically an Azure AD tenant.

## Editions

| Feature                                             | Free      | Microsoft 365 Apps | Premium P1 | Premium P2 |
| --------------------------------------------------- | --------- | ------------------ | ---------- | ---------- |
| Directory Objects                                   | 500,000   | Unlimited          | Unlimited  | Unlimited  |
| Single Sign-On                                      | Unlimited | Unlimited          | Unlimited  | Unlimited  |
| Core Identity and Access Management                 | X         | X                  | X          | X          |
| Business to Business Collaboration                  | X         | X                  | X          | X          |
| Identity & Access Management for Microsoft 365 apps |           | X                  | X          | X          |
| Premium Features                                    |           |                    | X          | X          |
| Hybrid Identities                                   |           |                    | X          | X          |
| Advanced Group Access Management                    |           |                    | X          | X          |
| Conditional Access                                  |           |                    | X          | X          |
| Identity Protection                                 |           |                    |            | X          |
| Identity Governance                                 |           |                    |            | X          |

- Free
  - user, groups, basic reports
  - on-premises AD sync
  - SSO for Microsoft 365, Azure services, other third-party SaaS applications

- Premium P1
  - self-service password reset
    - Refers to resetting password when not signed in (forgotten or expired password), NOT changing password after signed in (everyone can do this)
    - You could config what authentication tests need to be passed
    - Can be set as 'none', 'selected' or 'all', administrator accounts can always do this no matter what is configured
  - custom Azure AD roles (not Azure RBAC roles)
  - allow hybrid users access both on-prem and cloud resources
  - dynamic groups
  - self-service group management
  - Microsoft Identity Manager (on-premises identity management suite, allows self-service password reset for your on-prem users)
  - conditional access policy (based on user's location, device etc, then allow/block access or require multi-factor authentication)

- Premium P2
  - Active Directory Identity Protection: risk-based conditional access
  - Privileged Identity Management: discover, restrict and monitor administrators

- Pay-as-you-go
  - Azure AD B2C: manage identity and access for consumer users

Features:

- B2B identity services (allow you to invite guest users, *available to all tiers*)

  ![B2B process](images/azure_ad-b2b.svg)

- B2C identity services (customer users, *pay-as-you-go*)

  ![B2B process](images/azure_ad-b2c.svg)

## Azure AD vs. AD DS vs. Azure AD DS

|            | AD DS                                                                      | Azure AD                                                       | Azure AD DS                                |
| ---------- | -------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------ |
| Purpose    | Introduced in Windows 2000, for on-premises identity and access management | Microsoft 365, Azure Portal, SaaS applications                 | A subset of AD DS features, lift-and-shift |
| Deployment | Windows Server (On-prem or IaaS VMs)                                       | Cloud based                                                    | Cloud                                      |
| API        | LDAP                                                                       | REST (HTTPS)                                                   | same as AD DS                              |
| Protocols  | Kerberos authentication                                                    | SAML, WS-Federation, OpenID Connect for authN, OAuth for authZ | same as AD DS                              |
| Structure  | Organization Units (OUs) , Group Policy Objects (GPOs)                     | flat users and groups                                          | same as AD DS                              |

- Azure AD does not replace Active Directory, they can be used together, **Azure AD Connect** is a software you download and run on your on-prem host, it can synchronize changes between on-prem AD and Azure AD:

  ![Azure AD Connect](images/azure_azure-ad-connect.png)

### Azure AD DS

![AADDS Syncing](images/azure_aadds-sync.png)
_On prem AD is optional here_

- Intended to lift and shift your legacy applications from your on-prem to a managed domain.
- You define the domain name, two Windows Server DCs are then deployed into your selected Azure region as a replica set.
- Replica sets can be added to any peered virtual network in other regions.
- You don't need to deploy, manage and patch Domain Controllers (DCs).
- A one-way sync is configured from Azure AD to the managed domain, so you could login to a Windows VM using your Azure AD credentials.

## Azure AD Join

- Provide access to organizational resources of work-related devices
- Intended for organizations that do not have on-prem AD
- Connection options:
  - Registering a device to Azure AD enables you to manage a device's identity, which can be used to enable or disable a device
  - Joining: an extension to registering, changes local state to a device, which enables your users to sign-in to a device using a work or school account instead of personal account (e.g. you add your work M365 email to your own laptop)
- Combined with a mobile device management (MDM) solution such as Microsoft Intune, provides additional attributes in Azure AD


## Best practices

- Give at least two accounts the **Global Administrator** role, DON'T use them daily;
- Use regular administrator roles wherever possible;
- Create a list of banned passwords (such as company name);
- Configure conditional-access policies to require users to pass multiple authentication challenges;

## Users

- User types:
  - Member (could be defined in this AAD, another ADD, or synced from on-prem AD)
  - Guest (accounts from other cloud providers)
- Users with Global Administrator or User Administrator role can create new users
- When you delete an account, the account remains in suspended state for 30 days
- Users can also be added to Azure AD through Microsoft 365 Admin Center, Microsoft Intune admin console, and the CLI

## Groups

- Group types
  - Security groups: for RBAC
  - Microsoft 365: giving members access to shared mailbox, calendar, files, teams(not channels) in MS Teams, etc
  - Distribution: seems from Exchange

- Membership types
  - Assigned: assigned manually
  - Dynamic User: based on users' attributes
  - Dynamic Device: based on devices' attributes

Note:

- In the Azure portal, you can see all the groups, but you can't edit some of them:

  - Groups **synced from on-premises Active Directory** can be managed only in on-premises Active Directory.
  - Other group types such as **distribution lists** and **mail-enabled security groups** are managed only in Exchange admin center or Microsoft 365 admin center.

- There is a flag determining whether a group can be assigned Azure AD Roles

## Administrative Units

- To restrict administrative scope in organizations that are made up of independent divisions, such as School of Business and School of Engineering in a University
- Apply scope only to management permissions

## App registrations

|     | App registrations | Enterprise Applications                                                                            |
| --- | ----------------- | -------------------------------------------------------------------------------------------------- |
|     |                   | <ul><li>service principals (application)</li><li>service principals (managed identities)</li></ul> |


App registrations vs. Service principals

- If you register an application in the portal, an application object as well as a service principal object are automatically created in your home tenant. If you register/create an application using the Microsoft Graph APIs, creating the service principal object is a **separate step**.

## Providing identities to services

There are three types of service principals:

- Service principals

  - A service principal is an identity used by any service or application
  - You should create a different service principal for each of your application
  - Listed under **Enterprise applications** in Azure Portal


  ```sh
  SP_NAME='My-Service-Principal'
  RESOURCE_ID='resource/id'
  ANOTHER_RESOURCE_ID='another/resource/id'

  # create an SP and assign a role on multiple scopes
  SP_PASS=$(az ad sp create-for-rbac \
    --name $SP_NAME \
    --role "Contributor" \
    --scopes $RESOURCE_ID $ANOTHER_RESOURCE_ID \
    --query password \
    --output tsv)

  # get appId, which is used in your client app
  SP_APP_ID=$(az ad sp list \
    --display-name $SP_NAME \
    --query "[].appId" \
    --output tsv)

  # get objectId here, needed for role assignment
  SP_OBJECT_ID=$(az ad sp list \
    --display-name $SP_NAME \
    --query "[].objectId" \
    --output tsv)

  # if you need to create another role assignment
  az role assignment create \
    --assignee $SP_OBJECT_ID \
    --role "ROLE_A" \
    --scope "SUB_or_GROUP_or_RESOURCE_ID"

  # show SPs you created in your Default Directory
  az ad sp list \
    --filter "PublisherName eq 'Default Directory'" \
    -otable
  ```

- Managed identities for Azure services

  - For Azure resources only
  - Listed under **Enterprise applications -> Managed Identities** in Azure Portal

  Two types:

  - System-assigned

    A resource can have only one system-assigned managed identity, if the resource is deleted, so is the managed identity

    ```sh
    # assign a system-assigned managed identity to a VM
    az vm identity assign \
        --name <vm name> \
        --resource-group <resource group>
    ```

  - User-assigned

    A user-assigned managed identity is independent of any resources, so if your app is running on multiple VMs, it can use the same identity

    ```sh
    az identity create \
        --name <identity name> \
        --resource-group <resource group>

    # view identities, including system-assigned
    az identity list \
        --resource-group <resource group>

    # assign an identity to a function app
    az functionapp identity assign \
        --name <function app name> \
        --resource-group <resource group> \
        --role <principal id>

    # grant key vault permissions to an identity
    #  ! this is policy based keyvault access, not RBAC based
    az keyvault set-policy \
        --name <key vault name> \
        --object-id <principal id> \
        --secret-permissions get list
    ```

## Role-based access control (RBAC)

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

### Azure RBAC roles vs. Azure AD roles

Different roles in Azure:

- Azure AD administrator roles

  To manage Azure AD resources, such as users, groups and domains, find them in **"Roles and administrators" menu under Azure AD**

- RBAC roles

  The new Authorization system, find them in the **"Access Control (IAM)" menu under management groups, subscriptions, resource groups or resources**

- Classic subscription administrator roles (Legacy)

  The three administrator roles when Azure was initially released: Account Administrator, Service Administrator and Co-Administrator


|                             | Azure RBAC roles                                                                                                  | Azure AD roles                                                                     |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| For                         | Azure resources                                                                                                   | Azure Active Directory                                                             |
| Scope                       | management group, subscription, resource group, resource                                                          | tenant level                                                                       |
| How to get role information | Azure portal, Azure CLI (`az role definition list`), Azure PowerShell, Azure Resource Manager templates, REST API | Azure admin portal, Microsoft 365 admin portal, Microsoft Graph AzureAD PowerShell |

![RBAC vs. AAD roles](images/azure_rbac-vs-aad-roles.png)

- Azure AD roles and Azure RBAC roles are independent from one another, AD role assignment does not grant access to Azure resources and vice versa
- As an Azure AD Global Administrator, you might not have access to all subscriptions and management groups, but you could elevate your access:
  - Assign yourself "**User Access Administrator**" role in Azure at root scope(`/`)
  - View and assign access in any subscription or management group (e.g. assign yourself the Owner role of a management group)
  - You should remove this elevated access once you have made the changes needed
- Each directory is given a single top-level management group called "Tenant Root Group", it has the same id as the tenant, allows for global policies and Azure role assignments to be applied at this directory/tenant level.

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

## Logging and analytics

There are many different categories of logs:

- Sign-in logs (for human interactive sign-ins)
- Audit logs
- NonInteractiveUserSignInLogs
- ServicePrincipalSignInLogs
- ManagedIdentitySignInLogs
- RiskyUsers
- ...

You could download and analyze them manually, or you could send the logs to a Log Analytics Workspace, then use Azure Monitor to query the logs, create alerts, dashboards, etc

Example Kusto queries:

```sh
# most used apps requested and signed in to over the last week
SigninLogs
| where CreatedDateTime >= ago(7d)
| summarize signInCount = count() by AppDisplayName
| sort by signInCount desc

# risky sign-ins in the last 14 days
SigninLogs
| where CreatedDateTime >= ago(14d)
| where isRisky == true

# most common user events
AuditLogs
| where TimeGenerated >= ago(7d)
| summarize auditCount = count() by OperationName
| sort by auditCount desc
```
