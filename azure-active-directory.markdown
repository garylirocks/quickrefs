# Azure AD

- [Overview](#overview)
- [SKUs/Licenses](#skuslicenses)
- [B2B](#b2b)
  - [Best practices](#best-practices)
  - [Cross-tenant access settings](#cross-tenant-access-settings)
- [B2C](#b2c)
  - [Best practices](#best-practices-1)
- [Azure AD vs. AD DS vs. Azure AD DS](#azure-ad-vs-ad-ds-vs-azure-ad-ds)
  - [Azure AD Connect](#azure-ad-connect)
  - [Hybrid authentication](#hybrid-authentication)
  - [Azure AD DS](#azure-ad-ds)
- [Devices](#devices)
  - [Registration](#registration)
  - [Join](#join)
  - [Hybrid](#hybrid)
  - [Debugging](#debugging)
- [Users](#users)
- [Groups](#groups)
- [Workload identities](#workload-identities)
  - [App registrations vs. Service principals](#app-registrations-vs-service-principals)
  - [Example (for OIDC based apps)](#example-for-oidc-based-apps)
  - [Service Principals](#service-principals)
- [Application](#application)
  - [API Permissions](#api-permissions)
  - [App roles](#app-roles)
  - [Expose API](#expose-api)
- [SSO](#sso)
  - [SAML](#saml)
- [Role-based access control (RBAC)](#role-based-access-control-rbac)
  - [Considerations](#considerations)
  - [Evaluation](#evaluation)
  - [Azure subscriptions](#azure-subscriptions)
  - [Azure RBAC roles vs. Azure AD roles](#azure-rbac-roles-vs-azure-ad-roles)
  - [Custom Azure RBAC roles](#custom-azure-rbac-roles)
- [Conditional access](#conditional-access)
- [Privileged Identity Management (PIM)](#privileged-identity-management-pim)
- [Entra permissions management](#entra-permissions-management)
- [Identity protection](#identity-protection)
- [Access reviews](#access-reviews)
- [Administrative Units](#administrative-units)
- [Logging and analytics](#logging-and-analytics)
- [Application Proxy](#application-proxy)
- [Best practices](#best-practices-2)
- [CLI](#cli)
  - [`--filter` parameter](#--filter-parameter)
  - [Application and service principal owners](#application-and-service-principal-owners)
  - [Applications](#applications)
  - [Service principals](#service-principals-1)


## Overview

Microsoft's identity and access management solution.

- Azure, Microsoft 365, and Dynamics 365 all use Azure AD, a tenant in these services is automatically an Azure AD tenant.
- Could be managed in either Azure Portal or Entra admin portal
  - Some aspects could be managed in Office admin portal
- Default domain names are like `*.onmicrosoft.com`, you could bring your own domain name
- "Entra" is the new name for all of Microsoft's identity management service

Objects in AAD

- Users
- Groups
- Applications
- Service principals (including managed identities)
- Devices


## SKUs/Licenses

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
| Identity Protection (risk users)                    |           |                    |            | X          |
| Identity Governance (PIM)                           |           |                    |            | X          |
| Access Reviews                                      |           |                    |            | X          |

Licenses are per user, so one user can have P1, another have P2

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
  - Active Directory Identity Protection: identify risky users and risky sign-ins
  - Privileged Identity Management: just-in-time (JIT) privileged access control

- Pay-as-you-go
  - Azure AD B2C: manage identity and access for consumer users

Features:

- B2B identity services (*available to all tiers*)
- B2C identity services (for customer users of your service, *pay-as-you-go*)


## B2B

- For collaborating with business partners from external organizations like suppliers, partners and vendors
- Users appear as guests
- Guest user won't have credentials saved in your tenant, they will login via another AAD, an email code, SMS code, Google/Facebook account, etc

<img src="images/azure_ad-external-identities.png" width="600" alt="Guest users" />

Your could invite people from other external identity providers as guest users, you control what they can access to, and for how long, the process is like this:

<img src="images/azure_ad-b2b.svg" width="600" alt="B2B process" />

### Best practices

- **Designate an application owner to manage guest users**. Application owners are in the best position to decide who should be given access to a particular application.
- Use **conditional access** policies to grant or deny access
- Enable MFA, this happens **in your tenant**
- **Integrate with identity providers**, you can setup federation
- **Create as self-service sign-up user flow**, you could customize the experience

### Cross-tenant access settings

Controls trust between tenants, such as

- Trust MFA in a guest's tenant, so they don't need to do MFA again in your tenant
- Config which tenants can invite users from your tenant


## B2C

<img src="images/azure_ad-b2c-tenant.png" width="600" alt="B2C process" />

B2C tenant is for your application's customers, it's different from your organization's tenant

<img src="images/azure_ad-b2c.svg" width="600" alt="B2C process" />

### Best practices

- Configure user flows
- Customize user interface
- Integrate with external user stores: you could save up to 100 custom attributes per user in AAD B2C. You could also use AAD B2C for authentication, but delegate to an external CRM or customer loyalty database for customer data.


## Azure AD vs. AD DS vs. Azure AD DS

|            | AD DS                                                                      | Azure AD                                                       | Azure AD DS                                |
| ---------- | -------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------ |
| Purpose    | Introduced in Windows 2000, for on-premises identity and access management | Microsoft 365, Azure Portal, SaaS applications                 | A subset of AD DS features, lift-and-shift |
| Deployment | Windows Server (On-prem or IaaS VMs)                                       | Cloud based                                                    | Cloud                                      |
| API        | LDAP                                                                       | REST (HTTPS)                                                   | same as AD DS                              |
| Protocols  | Kerberos authentication                                                    | SAML, WS-Federation, OpenID Connect for authN, OAuth for authZ | same as AD DS                              |
| Structure  | Organization Units (OUs) , Group Policy Objects (GPOs)                     | flat users and groups, no OU hierarchy                         | same as AD DS                              |

### Azure AD Connect

Azure AD does not replace Active Directory, they can be used together, **Azure AD Connect** is a software you download and run on your on-prem host, it can synchronize identities between on-prem AD and Azure AD:

![Azure AD Connect](images/azure_azure-ad-connect.png)

- AD is the source of truth (most of the time)
- An AAD instance can only sync from one AAD Connect
- But one AD can be linked to multiple AAD Connect, so sync to multiple AAD instances
  - eg. sync one AD to both Azure commercial cloud and Azure US Gov cloud
- Use **Azure AD Connect Cloud Sync** to run the syncing in cloud instead of on-prem

### Hybrid authentication

- Password hash synchronization (recommended)

  - Most basic and least-effort solution in hybrid scenario
  - On-prem AD stores user password as a hash
  - AD Connect retrieves the hash and hashes that hash, sends the second hash to Azure AD
  - Allows on-prem user to auth against Azure AD for cloud applications
  - Allows AAD to check if the password is leaked

- Pass-through authentication

  - Passwords only in on-prem AD, not in the cloud (Azure AD)
  - Only on-prem AD is used to authenticate
  - A light weight agent is used on-prem to communicate with Azure AD

- Federated authentication

  - Allows an external, third-party system to authenticate users, including biometrics, smart-cards, etc
  - Does not authenticate against on-prem AD
  - You authenticate against a third party federation service, which gives you a SAML token, you then exchange this SAML token for AAD tokens (refresh & access tokens)

- Password writeback

  - Changes made in Azure AD are written back to on-prem AD

### Azure AD DS

<img src="images/azure_aadds-sync.png" width="800" alt="AADDS Syncing" />

_On prem AD is optional here_

- Intended to lift and shift your legacy applications from your on-prem to a managed domain.
- You define the domain name, two Windows Server DCs are then deployed into your selected Azure region as a replica set.
- Replica sets can be added to any peered virtual network in other regions.
- You don't need to deploy, manage and patch Domain Controllers (DCs).
- A one-way sync is configured from Azure AD to the managed domain, so you could login to a Windows VM using your Azure AD credentials.


## Devices

Three ways to add a device identity in Azure AD:

- Azure AD registration  (for BYOD)
- Azure AD join (for work devices)
- Hybrid Azure AD join (interim step to Azure AD join)

Usage:

- Device-based Conditional Access policies
- Enable users SSO to cloud-based resources
- Mobile device management (MDM) solution such as Microsoft Intune, provides additional attributes in Azure AD

### Registration

- Bring your own device (BYOD), such as cell phones and tablets
- Works on Windows, iOS, Android, Ubuntu etc.
- You login with your own account

### Join

- Usually a work/school device, you login with your work/school account
- An extension to registering, changes local state to a device
- Works on Windows 10 (and above)
- You can still login to an AAD-joined machine using a non-AAD account
- If you want to RDP an AAD joined machine using an AAD account
  - you use username in the form like `MyAAD\gary@example.com`
  - your local machine needs to be AAD joined/registered or hybrid joined
  - you can't use MFA during RDP login, but you could assign conditional access policy
- Requirements for Azure Windows VMs:
  - Windows Server 2019 and later
  - Windows 10 and later
  - With `AADLoginForWindows` extensions installed
  - the user needs either "Virtual Machine User Login" or "Virtual Machine Administrator Login" RBAC role, to login to the VM using AAD authentication

### Hybrid

- The device is joined to AD and registered with Azure AD
- You set a Service Connection Point (SCP) in AAD Connect, then AAD Connect will sync your on-prem device objects to AAD
- Your AD-joined device also registers itself with Azure AD, the device would get an AAD primary refresh token

### Debugging

```sh
# check status
dsregcmd /status

# +----------------------------------------------------------------------+
# | Device State                                                         |
# +----------------------------------------------------------------------+

#              AzureAdJoined : YES
#           EnterpriseJoined : NO
#               DomainJoined : YES
#                 DomainName : MyAAD
#                Device Name : hostname.MyAAD.example.com

# +----------------------------------------------------------------------+
# | Tenant Details                                                       |
# +----------------------------------------------------------------------+

#                 TenantName : My Tenant
#                   TenantId : xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#                        Idp : login.windows.net

# ...

# +----------------------------------------------------------------------+
# | Ngc Prerequisite Check                                               |
# +----------------------------------------------------------------------+

#             IsDeviceJoined : YES
#              IsUserAzureAD : YES
#              PolicyEnabled : NO
#           PostLogonEnabled : YES
#             DeviceEligible : YES
#         SessionIsNotRemote : YES
#             CertEnrollment : none
#               PreReqResult : WillNotProvision
```


## Users

- User types:
  - Member (could be defined in this AAD, another AAD, or synced from on-prem AD)
  - Guest (accounts from other cloud providers)
- Users with Global Administrator or User Administrator role can create new users
- When you delete an account, the account remains in suspended state for 30 days
- Users can also be added to Azure AD through Microsoft 365 Admin Center, Microsoft Intune admin console, and the CLI


## Groups

- Group types
  - Security groups
    - Members can be users, devices, service principals, and other groups
    - For access control(RBAC), assigning licenses, etc
  - Microsoft 365
    - Members can only be users
    - For sharing/collaboration over M365 apps: giving members access to shared mailbox, calendar, files, teams(not channels) in MS Teams, etc
  - Distribution: seems for Exchange

- Membership types
  - Assigned: assigned manually
  - Dynamic User: based on users' attributes
  - Dynamic Device: based on devices' attributes

Note:

- In the Azure portal, you can see all the groups, but you can't edit some of them:

  - Groups **synced from on-premises Active Directory** can be managed only in on-premises Active Directory.
  - Other group types such as **distribution lists** and **mail-enabled security groups** are managed only in Exchange admin center or Microsoft 365 admin center.

- There is a flag determining whether a group can be assigned "Azure AD Roles"


## Workload identities

<img src="images/azure_identity-types.svg" width="600" alt="Identity types" />

### App registrations vs. Service principals

|                 | App registrations                                                                                                                                            | Service principals                                                                                                                               |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Where           | home tenant                                                                                                                                                  | in every tenant where the application is used                                                                                                    |
| What            | a template or blueprint to create one or more service principal objects, has some *static properties* that are applied to all the created service principals | an instance of the application object in a single tenant                                                                                         |
| How to create   | Create an App in the Portal, an admin adds an App from the app gallery, MS Graph API / PowerShell, etc                                                       | when an application is given permission to access resources in a tenant (upon registration or consent)                                           |
| Defines         | <ul><li>how tokens are issued</li> <li>the resources the application needs to access</li> <li>actions the application can take</li></ul>                     | <ul><li>what the app can actually do in a specific tenant</li><li>who can access the app</li><li>and what resources the app can access</li></ul> |
| ID              | App/Client ID (globally unique)                                                                                                                              | Object ID                                                                                                                                        |
| In the Portal   | App Registrations                                                                                                                                            | Enterprise Applications                                                                                                                          |
| Microsoft Graph | `application`                                                                                                                                                | `servicePrincipal`                                                                                                                               |

- If you register an application in the portal, an application object as well as a service principal object are automatically created in your home tenant.
- If you register/create an application using the Microsoft Graph APIs, creating the service principal object is a **separate step**.
- By default, all users in your directory have rights to register application objects and discretion over which applications they give access to their organizational data through consent (limited to their own data).
- When the **first** user sign in to an application and grant consent, that will **create a service principal** in your tenant, any following consent grant info will be stored on the same service principal.
- When you update the name of an application, the name of the service principal gets updated automatically

### Example (for OIDC based apps)

![Application objects relationship](images/azure_application-objects-relationship.png)

- The application object only exists in its own tenant
- The service principals reference the application object
- Service principals are granted RBAC roles in each tenant


### Service Principals

There are three types of service principals:

- **Legacy**
- **Application**

  - You should create a different service principal for each of your application
  - For history reason, it's possible to create service principals without first creating an application object. The Microsoft Graph API requires an application object before creating a service principal.
  - Seems there is no easy way to find what AAD roles have been assigned to an SP, see [Terraform note](./terraform.markdown) for details on how to assign AAD roles/permissions to an SP
  - See [below](#service-principals-1) for CLI examples

  A service principal object looks like this:

  ```sh
  [
    {
      "appDisplayName": "MY-SP",
      "appId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "objectId": "oooooooo-oooo-oooo-oooo-oooooooooooo",
      "objectType": "ServicePrincipal",
      "odata.type": "Microsoft.DirectoryServices.ServicePrincipal",
      "servicePrincipalNames": [
        "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
      ],
      "servicePrincipalType": "Application",
      ...
    }
  ]
  ```

  Login to a service principal:

    ```sh
    # use a password
    az login --service-principal --username appID --tenant tenantID --password PASSWORD

    # use a cert
    # the cert must be a PEM or DER file, in ASCII format
    # when using a PEM file, CERTIFICATE must be appended to the PRIVATE KEY section
    az login --service-principal --username appID --tenant tenantID --password /path/to/cert
    ```

    - Use **`appId`** (the same in `servicePrincipalNames`) as the username for CLI login `az login --service-principal -u <appId> -p <pass> --tenant <tenantId>`
    - To login, the service principal **requires** RBAC role assignment, otherwise it can't login.

- **Managed identities**

  - For Azure resources only
  - Eliminate the need for developers to manage credentials
  - When a managed identity is enabled, a service principal representing that managed identity is created in your tenant
    - The service principal is listed under **Enterprise applications -> Managed Identities** in Azure Portal
    - There is **NO** corresponding app registration in your tenant

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

    A user-assigned managed identity is independent of any resources, so if your app is running on multiple VMs, it can use the same identity.

    A resource can have multiple user-assigned managed identities.

    ```sh
    az identity create \
        --name <identity name> \
        --resource-group <resource group>

    # view identities, including system-assigned
    az identity list \
        --resource-group <resource group>

    # assign identities to a function app
    az functionapp identity assign \
        --name <function app name> \
        --resource-group <resource group> \
        --identities <id1 id2 ...>

    # grant key vault permissions to an identity
    #  ! this is policy based keyvault access, not RBAC based
    az keyvault set-policy \
        --name <key vault name> \
        --object-id <principal id> \
        --secret-permissions get list
    ```

| Type              | App Registrations | Enterprise applications |
| ----------------- | ----------------- | ----------------------- |
| Service Principal | Yes               | Yes                     |
| Managed Identity  | No                | Yes                     |


## Application

Three types of applications:

| Type                             | App Registrations | Enterprise applications | How                                                               |
| -------------------------------- | ----------------- | ----------------------- | ----------------------------------------------------------------- |
| Gallery (SAML, Password, Linked) | Yes               | Yes                     | Add from the gallery, an app instance added to your tenant        |
| Gallery (OpenID Connect)         | **No**            | Yes                     | Sign-in/sign-up, the app will be added to Enterprise applications |
| Your own                         | Yes               | Yes                     | Add in App registrations                                          |
| On-prem                          | Yes               | Yes                     | AAD App Proxy                                                     |

- Pre-integrated applications (can be added from the gallery)
- Your own applications (register it in App Registrations)
- On-premises applications (can be published externally via AAD Application Proxy)

### API Permissions

Microsoft identity platform implements the OAuth 2.0 authorization protocol. Web-hosted resources can define a set of permissions that you use to implement functionality in smaller chunks, eg. Microsoft Graph has defined permissions like `User.ReadWrite.All`, `Mail.Read`

Two types of permissions:

- **Application permissions**: used by apps that run without a signed-in user
- **Deletegated permissions**: used by apps that have a signed-in user present, the user is simply allowing the app to act on their behalf using their permissions
  - The effective permissions are the **intersection** of the delegated permissions granted to the app and the privileges of the currently signed-in user

Best practices:

- Restricting user consent to allow users to consent only for app from verified publishers, and only for permissions you select.

### App roles

This allows you to adopt RBAC for authorization in your application code.

1. Define your custom roles in "Application registrations" -> "App roles"
  ![App roles](./images/azure_ad-app-roles.png)
2. Add users/groups/applications to a role in "Enterprise Application" -> "User and Groups"
  ![App role assignment](images/azure_ad-app-role-assignment.png)
3. Now, when user login to your app, AAD adds `roles` claim to tokens it issues.

See: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-add-app-roles-in-azure-ad-apps

### Expose API

- The "Expose an API" menu in the Portal allows you to define scopes for an API. This creates only "deletegated permissions". Use "App roles" assignable to application type for "application-only" scopes.
- You could add another application as an authorized client application to the scopes.


## SSO

Modes:

- Federation
  - Methods:
    - SAML 2.0
    - WS-Federation
    - OpenID Connect
  - The SSO option won't appear for an enterprise application if
    - The app was registered using App registrations, then OpenID is the default option
    - The app is hosted in another tenant
    - You don't have the permissions
- Password-based (aka. password vaulting)
  - Scenarios:
    - The app only has an HTML sign-in page with username/password fields, no SAML and OAuth
    - Several users need to share a single account, such as your organization's social media accounts (eg. Facebook)
  - How does it work
    - User installs a browser extension (in Chrome or Edge) - "My Apps Secure Sign-in"
    - User launches the app from My Apps or Microsoft 365 portal or the browser extension
    - User logins to AAD
    - AAD redirects to the application's login page
    - The browser extension fill in username, password and log in
  - The username and password, could be either:
    - Configured for user/group in AAD "Enterprise applications"
    - Or typed in by the user when accessing the app for the first time
- Linked
  - Scenarios:
    - The app already has another SSO configured, eg. AD FS
    - Deep links to specific web pages
    - An app that doesn't require authentication
  - Seems the main benefit is you get the app showing up in My Apps/Microsoft 365 portal
  - You just add a link, where the users first land on when accessing the application
- Disabled
  - User won't be able to launch the app from My Apps

![Azure AD SSO options](./images/azure_ad-single-sign-on-options.png)

### SAML

The configuration process varies depending on the application.

*You can use **[Azure AD SAML Toolkit](https://samltoolkit.azurewebsites.net/)** application for testing*

Usual steps:

- Basic configs (the URLs will be updated later, so doesn't matter in this step)
  - Identifier (Entity ID) - must be unique across all applications in your tenant
  - Reply URL (Assertion Consumer Service URL) - where the application expects to receive the SAML response (token)
  - Sign on URL - the sign-in page URL of the app

- Configs in the app
  - AAD login URL
  - AAD identifier
  - AAD logout URL
  - Signing certificate (downloaded from AAD)

- Update URLs in AAD (get them from the app)
  - Reply URL (Assertion Consumer Service URL)
  - Sign on URL

A SAML response XML has fields like:

```XML
<AttributeStatement>
  <!-- ... -->
  <Attribute Name="http://schemas.microsoft.com/identity/claims/displayname">
    <AttributeValue>Gary Li</AttributeValue>
  </Attribute>
  <Attribute Name="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress">
    <AttributeValue>gary@xxx.onmicrosoft.com</AttributeValue>
  </Attribute>
  <!-- ... -->
</AttributeStatement>
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

### Considerations

- Better to assign roles to groups rather than individual users to minimize role assignments
- Use custom roles to control permissions more precisely
- RBAC is an additive model
- Azure policies always apply, no matter who created/updated a resource


### Evaluation

![RBAC evaluation flowchart](images/azure_role-based-access-control-flowchart.png)

*Deny assignments take priority !!*

### Azure subscriptions

- Each Azure subscription is associated with a single Azure AD directory (tenant);
- Users, groups and applications in that directory can manage resources in the subscription;
- Subscriptions use Azure AD for SSO;

### Azure RBAC roles vs. Azure AD roles

Different roles in Azure:

- Azure AD administrator roles

  To manage Azure AD resources, such as users, groups and domains, find them in **"Roles and administrators" menu under Azure AD**

  - Usually can only be assigned to users/applications, not groups (unless the groups has enabled "AD Role assignment" toggle)
  - The assignment scope is either the whole directory or an "Administrative Unit"
  - Custom roles can only have permissions for Application registrations and Enterprise applications

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
- As an **Azure AD Global Administrator**, you might not have access to all subscriptions and management groups, but you could elevate your access:
  - Assign yourself "**User Access Administrator**" role in Azure at root scope(`/`)
  - View and assign access in any subscription or management group (e.g. assign yourself the **Owner** role of a management group)
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

- You could specify the assignable scopes: either management group, subscription or resource group
- **The definition is actually tenant-scoped, the role name must be unique within a tenant**


## Conditional access

![Conditional access](images/azure_ad-conditions-access.png)

P1 feature

Best practices:

- **More granular MFA experience**: eg. only trigger MFA from an unexpected location (Free license user only have a default MFA option, can't customize conditions)
- **Test with report-only mode**: evaluate access policy effect before enabling them
- **Block geographic areas**: you could define named locations, and block sign-in from them
- **Require manged devices**
- **Require approved client applications**
- **Block legacy authentication protocols**
- You can opt for **Passwordless MFA** or **Phishing-resistant MFA**


## Privileged Identity Management (PIM)

- P2 feature
- Just-in-time elevate role assignment
- Could be
  - AAD Role
  - RBAC Role
  - A privileged group membership
- Most common use case: create "Eligible Assignment" of roles/memberships to some users/groups, who need to active them when needed


## Entra permissions management

- Ad-hoc, on-demand elevation
- At very granular permission level
- Works across clouds (Azure, AWS, GCP)
- Can analyze permissions used and optionally right size
- Separate license based on resources scanned


## Identity protection

Allow or deny user access based on user risk and sign-in risk

![User risk level evaluation](images/azure_ad-user-risk-level-evaluation.png)

- **User risk** represents the probability that a given identity or account is compromised, calculated offline
  - Leaked credentials
  - Threat intelligence: unusual user activity
- **Sign-in risk** calculated real-time or offline
  - Anonymous IP
  - Atypical travel: sign-ins originating from distant locations
  - Malware linked IP
  - Password spray: brute force attach, using same password against multiple users


## Access reviews

P2 feature

Help ensure that the right people have the right access to the right resources, you could set up a schedule to review:

- Access to applications
- Group memberships
- Access packages that group resources (groups, apps, and sites) into a single package
- Azure AD roles and Azure Resource roles in Privileged Identity Management (PIM)


## Administrative Units

- To restrict administrative scope in organizations that are made up of independent divisions, such as School of Business and School of Engineering in a University
- You could put users/groups/devices in a unit
- Support dynamic membership rules
- Doesn't support nesting
- A unit is a scope for Azure AD role assignment
  - You only get permissions over direct members in the unit, not users in a group, you need to add them explicitly to the unit
  - Only a subset AAD roles can be assigned
- You need a P1 license to manage an administrative unit


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

## Application Proxy

Allow remote users to access on-prem applications, benefits:

- Publish on-prem web apps externally without a DMZ
- SSO across cloud and on-prem
- MFA
- Centralize account management

It's intended to be a replace for the legacy **VPN and reverse proxy solution** for remote users, not for users on the corporate network.

![AAD application proxy architecture](images/azure_ad-application-proxy-architecture.png)

- It publishes a public URL for your app
- Application Proxy Service runs in the cloud
- Application Proxy connector is a lightweight agent that runs on-prem

Networking

- Only outbound connection over port 80 and 443 to the Application Proxy Service
- No inbound traffic to on-prem apps, so no need to open any port

Authentication

![AAD application proxy authentication](images/azure_ad-application-proxy-authentication-flow.png)

- Put connecters in a group for high availability


## Best practices

- Give at least two accounts the **Global Administrator** role, DON'T use them daily;
- Use regular administrator roles wherever possible;
- Create a list of banned passwords (such as company name);
- Configure conditional access policies to require users to pass multiple authentication challenges;


## CLI

### `--filter` parameter

The `--filter` parameter in many `az ad` commands uses the OData filter syntax, check available expressions here: https://learn.microsoft.com/en-us/graph/filter-query-parameter

*Seems you could use `startswith`, `endswith`, but not `contains`*

- `startswith`

  ```sh
  # "startswith" needs to be all lowercase
  az ad group list --filter "startswith(displayName, 'gary')"
  ```

- `in`

  ```sh
  --filter 'id in ("xxx-xxx", "xxx-xxx")'
  ```

### Application and service principal owners

- A user is automatically added as an application owner when they register an application
  - Ownership for an enterprise application is assigned by default only when a user with no administrator roles (Global Administrator, Application Administrator etc) creates a new application registration.
- A good practice is to have at least two owners for an application.
- In the Portal, you could only add users as app and SP owners
- Groups can't be owners.
- To add an SP as owner, use CLI or API, see https://github.com/Azure/azure-cli/issues/9250#issuecomment-603621148.

```sh
# the target app and SP
appId="00000000-0000-0000-0000-000000000000"
spObjectId=$(az ad sp show --id $appId --query id --output tsv)

# this could be object id of a user or another SP
ownerObjectId="00000000-0000-0000-0000-000000000000"

# add as app owner
az ad app owner add --id $appId --owner-object-id "$ownerObjectId"

# as SP owner (need `az rest`, no CLI support yet)
az rest -m POST -u https://graph.microsoft.com/beta/servicePrincipals/$spObjectId/owners/\$ref -b "{\"@odata.id\": \"https://graph.microsoft.com/beta/servicePrincipals/$ownerObjectId\"}"
```

### Applications

```sh
# app regs created by me
az ad app list \
  --filter "publisherDomain eq 'garyli.onmicrosoft.com'" -otable
```

### Service principals

- Create and assign roles

  ```sh
  SP_NAME='My-Service-Principal'
  RESOURCE_ID='resource/id'
  ANOTHER_RESOURCE_ID='another/resource/id'

  # create an SP and assign a role on multiple scopes
  SP_PASS=$(az ad sp create-for-rbac \                # 1
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

  SP_OBJECT_ID=$(az ad sp list \
    --display-name $SP_NAME \
    --query "[].objectId" \
    --output tsv)

  # assign another role
  az role assignment create \
    --assignee $SP_OBJECT_ID \                        # 2
    --role "ROLE_A" \
    --scope "SUB_or_GROUP_or_RESOURCE_ID"
  ```

  - *#1* This creates both an app registration and a service principal, and does the RBAC assignment
  - *#2* Must use `objectId` in role assignment

- List

  ```sh
  # NOTE: seems you can only use "displayName" field for filtering
  az ad sp list \
    --filter "startswith(displayName, 'sp_name_')"
    -otable

  # list all role assignments for an SP in current subscription
  az role assignment list \
      --all \
      --assignee <SP name or object id>
  ```

- Use certificate-based authentication

  - Use an existing local cert

    ```sh
    # CERTIFICATE must be appended to the PRIVATE KEY within the `.pem` file
    az ad sp create-for-rbac --name myServicePrincipalName \
                          --role roleName \
                          --scopes /subscriptions/mySubscriptionID/resourceGroups/rg-temp-001 \
                          --cert @/path/to/cert.pem
    ```

  - Use existing cert in a key vault

    ```sh
    az ad sp create-for-rbac --name myServicePrincipalName \
                          --role roleName \
                          --scopes /subscriptions/mySubscriptionID/resourceGroups/rg-temp-001 \
                          --keyvault vaultName \
                          --cert certificateName
    ```

  - Use a newly generated self-signed cert

    ```sh
    az ad sp create-for-rbac --name myServicePrincipalName \
                          --role roleName \
                          --scopes /subscriptions/mySubscriptionID/resourceGroups/rg-temp-001 \
                          --create-cert
    ```

    This creates a `.pem` file, which looks like

    ```
    -----BEGIN PRIVATE KEY-----
    myPrivateKeyValue
    -----END PRIVATE KEY-----
    -----BEGIN CERTIFICATE-----
    myCertificateValue
    -----END CERTIFICATE-----
    ```

  - Use a newly generated self-signed cert and put it in a key vault

    ```sh
    # generate a cert and save it to a key vault
    az ad sp create-for-rbac --name myServicePrincipalName \
                        --role roleName \
                        --scopes /subscriptions/mySubscriptionID/resourceGroups/rg-temp-001 \
                        --create-cert \
                        --cert certificateName \
                        --keyvault vaultName
    ```

    To retrieve the cert and convert it to a PEM file:

    ```sh
    az keyvault secret download \
        --file /path/to/cert.pfx \
        --vault-name VaultName \
        --name CertName \
        --encoding base64
    openssl pkcs12 -in cert.pfx -passin pass: -out cert.pem -nodes
    ```

    **You need `az keyvault secret download` here to retrieve the private key and the cert, `az keyvault certificate download` only downloads the public potion of a certificate**
