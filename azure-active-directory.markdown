# Azure AD

- [Licenses](#licenses)
- [Compare with Active Directory](#compare-with-active-directory)
- [Best practices](#best-practices)
- [Users](#users)
- [Providing identities to services](#providing-identities-to-services)
- [Role-based access control (RBAC)](#role-based-access-control-rbac)
- [Logging and analytics](#logging-and-analytics)


Overview:

- Each Azure subscription is associated with a single Azure AD directory (tenant);
- Users, groups and applications in that directory can manage resources in the subscription;
- Subscriptions use Azure AD for SSO;
- Microsoft 365 uses Azure AD;

## Licenses

- Free
  - user, groups, basic reports
  - on-premises AD sync
  - self-service password reset
  - SSO for Microsoft 365, Azure services, other third-party SaaS applications

- Premium P1
  - dynamic groups
  - on-premises identity management suite
  - conditional access policy

- Premium P2
  - Active Directory Identity Protection: risk-based conditional access
  - Privileged Identity Management: detailed restrictions on administrators

- Pay-as-you-go
  - Azure AD B2C: manage identity and access for consumer users

Features:

- B2B identity services (allow you to invite guest users, *available to all tiers*)

  ![B2B process](images/azure_ad-b2b.svg)

- B2C identity services (customer users, *pay-as-you-go*)

  ![B2B process](images/azure_ad-b2c.svg)

## Compare with Active Directory

- Active Directory manages objects, like devices and users on your on-premises network;
- AAD does not replace Active Directory;
- They can be used together;

## Best practices

- Give at least two accounts the **Global Administrator** role, DON'T use them daily;
- Use regular administrator roles wherever possible;
- Create a list of banned passwords (such as company name);
- Configure conditional-access policies to require users to pass multiple authentication challenges;

## Users

- Two user types: Member and Guest
- Users with User Administrator or Global Administrator role can create new users
- When you delete an account, the account remains in suspended state for 30 days


## Providing identities to services

- Service principals

  - A service principal is an identity used by any service or application
  - You should create a different service principal for each of your application
  - Listed under **App registrations** in Azure Portal

  ```sh
  # create an sp and set its RBAC
  # retrieve its password here (this is the only chance)
  az ad sp create-for-rbac \
    --name http://my-sp-$UNIQUE_ID \
    --role Contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --query password \
    --output tsv

  # get service principal id
  az ad sp show \
    --id http://my-sp-$UNIQUE_ID \
    --query appId \
    --output tsv

  # list all SP created by 'Default Directory'
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
    #  then the functionapp can access the vault
    az keyvault set-policy \
        --name <key vault name> \
        --object-id <principal id> \
        --secret-permissions get list
    ```

## Role-based access control (RBAC)

RBAC allows you to grant access to Azure resources that you control. You do this by creating role assignments, which control how permissions are enforces. There are three elements in a role assignment:

1. Security principal (who)

  ![RBAC principal](images/azure_rbac-principal.png)

2. Role definition (what)

  A collection of permissions, `NotActions` are subtracted from `Actions`

  ![RBAC role definition](images/azure_rbac-role.png)

  Four fundamental built-in roles:

  - Owner - full access, including the right to delegate access to others
  - Contributor - create and manage, but can't grant access to others
  - Reader - view
  - User Access Administrator - can manage user access

3. Scope (where)

  ![role scopes hierarchy](images/azure_rbac-scopes.png)


Role Assignment

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

