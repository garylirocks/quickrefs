# Microsoft Entra workload identities

- [Overview](#overview)
- [App registrations vs. Service principals](#app-registrations-vs-service-principals)
- [Service principals](#service-principals)
- [Service principals (application)](#service-principals-application)
- [Managed identities](#managed-identities)
  - [System-assigned (SAMI)](#system-assigned-sami)
  - [User-assigned (UAMI)](#user-assigned-uami)
  - [Considerations](#considerations)
- [Workload identity federation](#workload-identity-federation)
  - [How it works](#how-it-works)
  - [CLI](#cli)
- [Application](#application)
  - [Application management](#application-management)
  - [My Apps portal](#my-apps-portal)
  - [API Permissions](#api-permissions)
  - [Consent](#consent)
  - [Consent settings](#consent-settings)
  - [App roles](#app-roles)
  - [Expose API](#expose-api)
- [Application Proxy](#application-proxy)
- [Workload Identity Premium](#workload-identity-premium)
  - [Conditional Access for workload identities](#conditional-access-for-workload-identities)
- [CLI](#cli-1)
  - [Application registration and service principal(Enterprise app) owners](#application-registration-and-service-principalenterprise-app-owners)
  - [Applications](#applications)
  - [Service principals](#service-principals-1)
- [Monitoring](#monitoring)


## Overview

<img src="images/azure_identity-types.svg" width="600" alt="Identity types" />

A workload identity is an identity that allows an application or service principal access to resources, sometimes in the context of a user. These workload identities differ from traditional user accounts as they:

- Can’t perform multifactor authentication (MFA)
- Often have no formal lifecycle process
- Need to store their credentials or secrets somewhere


## App registrations vs. Service principals

There are two representations of applications in Entra: application objects and service principals.

|                 | App registrations                                                                                                                                            | Service principals                                                                                                                                                                                                   |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Where           | home tenant                                                                                                                                                  | in every tenant where the application is used                                                                                                                                                                        |
| What            | a template or blueprint to create one or more service principal objects, has some *static properties* that are applied to all the created service principals | an instance of the application object in a single tenant                                                                                                                                                             |
| How to create   | Create an App in the Portal, an admin adds an App from the app gallery, MS Graph API / PowerShell, etc                                                       | when an application is given permission to access resources in a tenant (upon registration or consent)                                                                                                               |
| Defines         | <ul><li>how tokens are issued</li> <li>the resources the application needs to access</li> <li>actions the application can take</li></ul>                     | <ul><li>local user/admin permissions granted</li><li>local user/group app role assignments</li><li>attribute mappings for user provisioning</li><li>directory specific app roles, name or logo</li><li>etc</li></ul> |
| ID              | App/Client ID (globally unique)                                                                                                                              | Object ID                                                                                                                                                                                                            |
| In the Portal   | App Registrations                                                                                                                                            | Enterprise Applications                                                                                                                                                                                              |
| Microsoft Graph | `application`                                                                                                                                                | `servicePrincipal`                                                                                                                                                                                                   |

- If you register an application in the portal, an application object as well as a service principal object are automatically created in your home tenant.
  - Legacy service principals are closer to an AD service account, they could be created without an application object
- If you register/create an application using the Microsoft Graph APIs, creating the service principal object is a **separate step**.
- By default, all users in your directory have rights to register application objects and discretion over which applications they give access to their organizational data through consent (limited to their own data).
- When the **first** user sign in to an application and grant consent, that will **create a service principal** in your tenant, any following consent grant info will be stored on the same service principal.
- When you update the name of an application, the name of the service principal gets updated automatically

Example (for OIDC based apps)

![Application objects relationship](images/azure_application-objects-relationship.png)

- The application object only exists in its own tenant
- The service principals reference the application object
- Service principals are granted RBAC roles in each tenant

Microsoft maintains some directories internally to publish applications:

![Microsoft directories for applications](images/azure_ad-application-vs-service-principal.png)

- Microsoft services directory (tenant ID: `f8cdef31-a31e-4b4a-93e4-5f571e91255a`) - for first-party Microsoft applications
  - Could not be deleted
  - Examples:
    - Azure Portal
    - Microsoft Azure CLI (`04b07795-8ddb-461a-bbee-02f9e1bf7b46`)
    - Microsoft Graph (`00000003-0000-0000-c000-000000000000`)
    - Office 365 SharePoint Online (`00000003-0000-0ff1-ce00-000000000000`)
    - Windows Azure Active Directory (`00000002-0000-0000-c000-000000000000`)
    - Meru19 First Party App (`93efed00-6552-4119-833a-422b297199f9`), for "Azure Database for PostgreSQL Flexible Server Private Network Integration", this adds DNS record for PostgreSQL server to specified private DNS zone
- App gallery directory - for pre-integrated third party apps
- Microsoft tenant (ID: `72f988bf-86f1-41af-91ab-2d7cd011db47`)
  - Graph Explorer (`de8bc8b5-d9f9-48b1-a8ad-b748da725064`)
  - Microsoft Graph Command Line Tools (`14d82eec-204b-4c2f-b7e8-296a70dab67e`)


## Service principals

In general, there are three types of service principals:

- **Legacy**
- **Application**
- **Managed Identity**

## Service principals (application)

- You should create a different service principal for each of your applications
- For history reason, it's possible to create service principals without first creating an application object. The Microsoft Graph API requires an application object before creating a service principal.
- Seems there is no easy way to find what Entra roles have been assigned to an SP, see [Terraform note](./terraform.markdown) for details on how to assign Entra roles/permissions to an SP
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

- Use `appId` for login, NOT `objectId`
- To login, the service principal **requires** RBAC role assignment, otherwise it can't login.

## Managed identities

- For Azure resources only
- Two types: System-assigned Managed Identity (SAMI), and User-assigned Managed Identity (UAMI)
- Eliminate the need for developers to manage credentials
- When a managed identity is enabled, a **service principal** representing that managed identity is created in your tenant
  - The service principal is listed under **Enterprise applications -> Managed Identities** in Azure Portal
  - There is **NO** corresponding app registration in your tenant
- **Which MI is used**:
  - If SAMI is enabled and no identity is specified in the request, Azure Instance Metadata Service (IMDS) defaults to the SAMI
  - If SAMI isn't enabled, and only one UAMI exists, IMDS defaults to that UAMI
  - If SAMI isn't enabled, and multiple UAMIs exist, then you are required to specify a managed identity in the request

### System-assigned (SAMI)

A resource can have only one system-assigned managed identity, if the resource is deleted, so is the managed identity

```sh
# assign a system-assigned managed identity to a VM
az vm identity assign \
    --name <vm name> \
    --resource-group <resource group>
```

### User-assigned (UAMI)

- A UAMI is independent of any resources, so if your app is running on multiple VMs, it can use the same identity. This helps when you have hundreds of VMs, using a UAMI instead of SAMI reduces identity churn in Entra.
- If you delete a UAMI, resources using the identity can not get a new token when its current token expires
- A UAMI as a resource would reside in a region, but the associated service principal **is global**, its availability is only dependent on Entra
  - When the region is unavailable, the control plane won't work, but the SP still works
- Related built-in roles:
  - "Managed Identity Contributor": Create UAMI and federated identity credentails
  - "Managed Identity Operator": Assign UAMI to a resource (also needs write permission on the target resource)

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

To login to Azure using a managed identity:

```sh
# login to Azure in a VM with managed identity
# this uses system-assigned MI by default
az login --identity

# if you want to use a specific user-assigned MI
# specify it with `--username`
az login --identity --username <client_id|object_id|resource_id>
```

**UAMI advantages over SAMI**:

- UAMI and its role assignments could be configured in advance
- Users who create the resources only require the permission to assign a UAMI (`Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action` or the built-in "Managed Identity Operator" role), no need for the privileged role assignment permission
- If multiple resources need the same permissions, UAMI is better
- If you create lots of SAMI simultaneously, you may exceed Microsoft Entra rate limit

### Considerations

- If a resource (eg. app, VM) has been assigned a SAMI/UAMI, and a user can run code in the resource, the user gets all the permission granted to the SAMI/UAMI
- When you delete a SAMI/UAMI, it is only fully purged after 30 days
- When you delete a SAMI/UAMI, the associated role assignments AREN'T automatically deleted. These role assignments should be manually deleted so the limit of role assignments per subscription isn't exceeded. Can be done with command `Get-AzRoleAssignment | Where-Object {$_.ObjectType -eq "Unknown"} | Remove-AzRoleAssignment`
- A managed identity can also get permissions via being added to an Entra group, or being assigned an App Role
  - But there is a drawback, the identity's groups and roles are claims in the access token, any authorization changes do not take effect until the token is refreshed. The token is usually cached for **24 hours** by Azure (A user's access token is only valid for 1 hour by default). And it is **not possible** to force a managed identity's token to be refreshed before its expiry. So you may need to wait several hours for your change to take effect.
  - A UAMI can be used like a group because it can be assigned to one or more Azure resources to use it.
  - See [details here](https://learn.microsoft.com/en-gb/entra/identity/managed-identities-azure-resources/managed-identity-best-practice-recommendations#limitation-of-using-managed-identities-for-authorization)

**Compare Service principal (application) to managed identity**:

| Type              | App Registrations | Enterprise applications |
| ----------------- | ----------------- | ----------------------- |
| Service Principal | Yes               | Yes                     |
| Managed Identity  | No                | Yes                     |

## Workload identity federation

- Intended for workloads running ourside of Azure, supported scenarios:
  - GitHub Actions
  - Kubernetes clusters (AKS, EKS, GKE, on-prem)
  - Google Cloud, AWS workloads
  - External IdP
  - SPIFFE
- Like managed identities, you don't need to manage secrets
- Supported for both
  - user-assigned managed identity
  - app registration

### How it works

It creates a trust relationship between external IdP and a UAMI or app reg in Microsoft Entra.

![Workload identity federation](images/azure_workload-identity-federatjion-workflow.svg)

### CLI

```sh
# for GitHub Actions workflow
az ad app federated-credential create --id <APPLICATION-OBJECT-ID> --parameters credential.json
```

`credential.json` contains the following content

```json
{
    "name": "<CREDENTIAL-NAME>",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:my-org/my-repo:environment:Production",
    "description": "Testing",
    "audiences": [
        "api://AzureADTokenExchange"
    ]
}
```

Subject format could be:

- `repo:my-org/my-repo:environment:<env-name>`: tied to an env
- `repo:my-org/my-repo:ref:refs/heads/<branch-name>`: tied to a branch
- `repo:my-org/my-repo:ref:refs/tags/<tag-name>`: tied to a tag
- `repo:my-org/my-repo:ref:pull_request`: for pull requests

*You must use the exact name of the branch, tag and environment, there is **NO support for pattern matching** at the moment*
*It's commmon to use this in multiple branches/tags, you'd better use the environment subject, which takes precedence*

Then in your GitHub workflow, use the `azure/login` action, providing the `client-id`, `tenant-id` and `subscription-id`, it will try to use OIDC to login by default.

```yaml
jobs:
  az-login-testing:
    runs-on: ubuntu-latest
    # specify the environment here if your workflow identity federation subject is like
    # `repo:my-org/my-repo:environment:prod`
    environment: prod
    steps:
    - name: 'Az CLI login'
      uses: azure/login@v1
      with:
          client-id: ${{ vars.AZURE_CLIENT_ID_WITH_WORKLOAD_IDENTITY_FEDERATION }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

    - name: 'Run Azure CLI commands'
      run: |
          az account show
          az group list
```


## Application

Three types of applications:

| Type                             | App Registrations | Enterprise applications | How                                                               |
| -------------------------------- | ----------------- | ----------------------- | ----------------------------------------------------------------- |
| Gallery (SAML, Password, Linked) | Yes               | Yes                     | Add from the gallery, an app instance added to your tenant        |
| Gallery (OpenID Connect)         | **No**            | Yes                     | Sign-in/sign-up, the app will be added to Enterprise applications |
| Your own                         | Yes               | Yes                     | Add in App registrations                                          |
| On-prem                          | Yes               | Yes                     | Entra App Proxy                                                   |

- Gallery applications (Microsoft has worked with third-party for basic integration, and the app added into the app gallery)
- Your own applications (register it in App Registrations)
- On-premises applications (can be published externally via Entra Application Proxy)

### Application management

Delegate application creation and management permissions by using one of the following methods:

- **Restrict who can create applications**
  - Set these tenant-wide settings to "No":
    - "User settings" -> "Users can register applications"
    - "Enterprise applications" -> "User settings" -> "Users can add gallery apps to My Apps"
    - "Enterprise applications" -> "Consent and Permissions" -> "Users can consent to applications accessing company data on their behalf"
  - Then assign "Application Developer" role to users who need to create application registrations, (*when a user creates a new application registration, they're automatically added as the first owner, this allows the user to manage all aspects of the app reg*)
- **Assign application owners**
  - You can assign the owners to both application registrations and enterprise applications
  - User and service principals can be owners of application registrations, only users can be owners of enterprise applications. Groups cannot be owners.
  - If adding a gallery app creates both an application registration and an enterprise application, the user who added the app is automatically assigned as the owner of both.
- **Use built-in roles**
  - Application Administrator
    - all aspects of application registration, enterprise applications, and application proxy
    - consents to delegated permissions and application permissions, excluding Microsoft Graph
  - Cloud Application Administrator
    - can not manage application proxy
  - *When a user with these either of these roles creates a new application registration, they're not automatically added as the owner*
- **Create and assign a custom role**
  - A custom role can be assigned at tenant scope or at the scope of a single Entra object (eg. a user/group/device/application)

### My Apps portal

For users to access their applications.

- URL `https://myapplications.microsoft.com`
- There are user settings controlling what apps are visible here

App collections:

- You can create tenant-wide App Collections in Azure portal, which can only be managed in Azure portal
- A user can create and manage personal app collections as well

### API Permissions

Entra implements the OAuth 2.0. Web-hosted resources can define a set of permissions that you use to implement functionality in smaller chunks, eg. Microsoft Graph has defined permissions like `User.ReadWrite.All`, `Mail.Read`

Permissions of all Microsoft IdP integrated API apps in your tenant can be requested here, it could be a Microsoft API, or your own app that exposes API scopes, each app would have a unique Application ID URI, for example:

- Microsoft Graph: `https://graph.microsoft.com`
- Microsoft 365 Mail API: `https://outlook.office.com`
- Azure Key Vault: `https://vault.azure.net`
- My Demo API: `api://dev.guisheng.li/demo/api1`

Two types of permissions:

- **Deletegated permissions**: used by apps that have a signed-in user present, the user is simply allowing the app to act on their behalf using their permissions
  - Some delegated permissions can be consented to by non-administrative users, but some higher-privileged permissions require administrator consent.
  - The *effective permissions* are the **intersection** of the delegated permissions granted to the app (via consent) and the privileges of the currently signed-in user
    - An app can never have more privileges than the signed-in user, if the app has been granted `User.ReadWrite.All`, but the user doesn't have proper admin role, then the app can only update the profile of the signed-in user, not other users
- **Application permissions**: used by apps that run without a signed-in user, such as background services or daemons
  - Only administrators can consent to application permissions
  - The *effective permissions* are exactly the permissions granted to the app
  - An app can also by assigned an Entra RBAC role

The definition schema looks like:

```json
"requiredResourceAccess": [
  {
    "resourceAppId": "00000003-0000-0000-c000-000000000000",  // Microsoft Graph
    "resourceAccess": [
      {
        "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d", // the `User.Read` scope
        "type": "Scope"                               // For Delegated permissions
      },
      {
        "id": "ef5f7d5c-338f-44b0-86c3-351f46c8bb5f",
        "type": "Role"                                // For Application permissions
      },
      // ...
    ]
  }
]
```

Supported OpenID Connect scopes:

- `Openid`:
  - Shows up as "sign you in" permission for work and school accounts on the consent prompt
  - Shows up as "View your profile and connect to apps and services using your Microsoft account" permission for personal account
  - Returns an user ID in the `sub` claim
  - Gives the app access to the UserInfo endpoint
  - Required for signing in the user with OIDC
- `email`: returns the user's primary email address in the `email` claim (not exist if the user doesn't have an email address)
- `profile`: given name, surname, preferred username, object ID, etc
- `offline_access`:
  - Shows up as "Maintain access to data you have given it access to" permission
  - Your app must explicitly requests this to receive a **refresh token**, which is long-lived, otherwise your app only get a short-lived access token
  - When using a Single Page Application (SPA), refresh token is always provided

*At this time, the `offline_access` and `user.read` permissions are automatically included in the initial consent to an application. These permissions are generally required for proper app functionality; `offline_access` gives the app access to refresh tokens, critical for native and web apps, while `user.read` gives access to the `sub` claim, allowing the client or app to correctly identify the user over time and access rudimentary user information.*

Best practices:

- There are settings for
  - "User consent for applications"
  - "Group owner consent for apps accessing data"
  - "Admin consent request" - whether user can request admin consent to apps they are unable to consent to
- Restricting user consent to "Allow user consent for apps from verified publishers, for selected permissions (Recommended)"

### Consent

Some high-privilege permissions are admin-restricted, only an admin can consent, like:

- `User.Read.All`
- `Groups.Read.All`
- `Directory.ReadWrite.All`

The requested permissions in "App registration" should be all the permissions this app could possibly require, should be a **superset** of the permissions that it will request dynamically/incrementally.

Admins could grant **tenant-wide admin consent**:

- In the Portal, you could do it in either
  - "Enterprise applications" -> "Permissions"
  - or "App registrations" -> "API permissions", if the app has an app registration
- It opens a popup, with the admin consent endpoint URL like: `https://login.microsoftonline.com/{tenant-id}/adminconsent?client_id={client-id}`
- Whether a permission is "Admin consent required" could be different in different organizations.
- An admin could consent to both delegated permissions and application permissions

How admins consent to an app:

- When an admin logs in to the app for the first time (in the `/authorize` endpoint), they would be asked if they would consent on behalf of the entire tenant
- In the Portal, click button in either "Enterprise applications" -> "Permissions" or "App registrations" -> "API permissions"
- Use the admin consent endpoint
  - During sign-up or the first sign-in, you can redirect the user to the admin consent endpoint, `https://login.microsoftonline.com/\{tenant\}/v2.0/adminconsent?client_id={client-id}&state=12345&redirect_uri=http://localhost/myapp/permissions&scope=https://graph.microsoft.com/calendars.read https://graph.microsoft.com/mail.send`

### Consent settings

You could configure tenant-wide consent settings in "Enterprise applications" -> "Consent and permissions"



### App roles

This allows you to adopt RBAC for authorization in your application code.

1. Define your custom roles in "Application registrations" -> "App roles"

    ![App roles](./images/azure_ad-app-roles.png)

2. Add users/groups to a role in "Enterprise Application" -> "User and Groups".

    To assign the App Role to an app, use PowerShell, see https://learn.microsoft.com/en-gb/entra/identity/managed-identities-azure-resources/how-to-assign-app-role-managed-identity

    ![App role assignment](images/azure_ad-app-role-assignment.png)

1. Now, when user login to your app, Entra adds `roles` claim to tokens it issues.

See: https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-add-app-roles-in-azure-ad-apps

### Expose API

- The "Expose an API" menu in the Portal allows you to define scopes for an API application.
  - This creates only "deletegated permissions".
  - You could specify who can consent for this scope: "Admins and users" or "**Admins only**"
  - For application-only scopes, use "App roles" and define app roles assignable to applications.
- Application ID URI need to be globally unique, usually has the form `api://<app-id>`, eg. `api://dev.guisheng.li/demo/api1`
- You could add another application as an authorized client application to the scopes, then user won't be prompted to consent when login to the client application.
- When a client app requests the scope in its OAuth request, and the user consents (or pre-approved), Entra sends back an access token which contains the required scopes

**Example**

Two app registrations:

- Demo API: defines the scopes (a service provider in this scenario)
- Demo client app: will call the API, defines the scopes it needs

![Expose an API UI](images/azure_ad-app-expose-an-api.png)

Demo API manifest excerpt:

```json
"displayName": "Demo API",
"id": "c487a3af-67fb-40ab-b2af-9001be29c117",
"identifierUris": [
  "api://dev.guisheng.li/demo/api1"
]
"api": {
  "acceptMappedClaims": null,
  "knownClientApplications": [],
  "oauth2PermissionScopes": [
    {
      "adminConsentDescription": "Allow the application to have write access to all employee data.",
      "adminConsentDisplayName": "Write access to employee records",
      "id": "98040718-37cc-4dbe-9ae4-4dd2b5ef4888",
      "isEnabled": true,
      "type": "Admin",
      "userConsentDescription": null,
      "userConsentDisplayName": null,
      "value": "Employees.Write.All"
    },
    {
      "adminConsentDescription": "Allow the application to have read-only access to all employee data.",
      "adminConsentDisplayName": "Read-only access to employee records",
      "id": "f34526c1-6970-4d78-8d3e-89a7abcedc54",
      "isEnabled": true,
      "type": "User",
      "userConsentDescription": "Allow the application to have read-only access to your employee data.",
      "userConsentDisplayName": "Read-only access to your employee records",
      "value": "Employees.Read.All"
    }
  ],
  "preAuthorizedApplications": [
    {
      "appId": "6741fadc-82c4-499a-9615-bd7b371d97f0",
      "delegatedPermissionIds": [
        "98040718-37cc-4dbe-9ae4-4dd2b5ef4888",
        "f34526c1-6970-4d78-8d3e-89a7abcedc54"
      ]
    }
  ],
  "requestedAccessTokenVersion": null
}
//...
```

Then the Demo client app defines it's required permissions:

![Client app required permissions](images/azure_ad-app-expose-an-api-client-app.png)

Demo client app manifest excerpt:

```json
//...
"requiredResourceAccess": [
  {
    "resourceAccess": [
      {
        "id": "f34526c1-6970-4d78-8d3e-89a7abcedc54",       // the `Employees.Read.All` scope
        "type": "Scope"
      }
    ],
    "resourceAppId": "fd1903c1-667d-4cab-8967-5d83ca330f3c" // the API app
  },
  {
    "resourceAccess": [
      {
        "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",       // the `User.Read` scope
        "type": "Scope"
      }
    ],
    "resourceAppId": "00000003-0000-0000-c000-000000000000" // Microsoft Graph
  }
]
//...
```

## Application Proxy

Allow remote users to access on-prem applications, benefits:

- Publish on-prem web apps externally without a DMZ
- SSO across cloud and on-prem
- MFA
- Centralize account management

It's intended to be a replace for the legacy **VPN and reverse proxy solution** for remote users, not for users on the corporate network.

![Entra application proxy architecture](images/azure_ad-application-proxy-architecture.png)

- It publishes a public URL for your app
- Application Proxy Service runs in the cloud
- Application Proxy connector is a lightweight agent that runs on-prem

Networking

- Only outbound connection over port 80 and 443 to the Application Proxy Service
- No inbound traffic to on-prem apps, so no need to open any port

High availability
- create a connector group

Authentication

![Entra application proxy authentication](images/azure_ad-application-proxy-authentication-flow.png)

Kerberos auth flow

![Entra application proxy kerberos auth](images/azure_ad-app-proxy-kerberos-auth.png)

- The on-prem app is using Integrated Windows Authentication (IWA), which requires a Kerberos token
- In this case, the Proxy connector will impersonate to get the Kerberos token and present it to the on-prem app
- *The yellow is an Entra token, the red an Kerberos token*


## Workload Identity Premium

- It's a standalone product, you need a license for it
  - Not included in other product plans, like Entra ID P1/P2, E5
  - Charges you $3 per workload ID per month
- One license in the tenant unlocks all the features for all the workload IDs, NO need to assign licenses to individual workload IDs
- Provides more security features for workload identities:

| Feature            | Service principal                                  | Managed identity | Note                                                |
| ------------------ | -------------------------------------------------- | ---------------- | --------------------------------------------------- |
| Conditional Access | Y (single-tenant app only)                         | N                | eg. IP range                                        |
| ID Protection      | Y (single and multi-tenant apps, third-party SaaS) | N                | Detect suspicious sign-ins, leaked credentials, etc |
| Access Review      | Y                                                  | Y                | Review PIM role assignments                         |

### Conditional Access for workload identities

- Only for **single-tenant** service principals owned by the organization
  - SaaS and multi-tenant apps not supported
  - Managed identities not supported
- Policy example:
  - Location: Block from any, except the allowed ones
  - Based on Id Protection risk
- Use "Service principal sign-ins" log to view "Conditional Access" evaluation info
- If you use "Report-only" mode, view results in "Report-only" tab of "Sign-in report"


## CLI

### Application registration and service principal(Enterprise app) owners

- A user is automatically added as an application owner when they register an application
  - Ownership for an enterprise application is assigned by default only when a user with no administrator roles (Global Administrator, Application Administrator etc) creates a new application registration.
- A good practice is to have at least two owners for an application.
- Groups can't be owners
- An service principal can be owner of an app registration, but not another SP (enterprise app).
- In the Portal, you could only add users as app registration or enterprise app owners
- To add a service principal as owner of an app registration, you could use CLI or API, see https://github.com/Azure/azure-cli/issues/9250#issuecomment-603621148.

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
# get app ID by display name (display name is not unique)
# single quotes are required
appName="<app-name>"
az ad app list --filter "displayName eq '$appName'" --query "[].appId" -otsv
# xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# --display-name param matches $appName as a prefix of the whole name
az ad app list --display-name "$appName" --query "[].appId" -o tsv
# same as
az ad app list --filter "startswith(displayName, '$appName')" --query "[].appId" -o tsv

# app regs created by me
az ad app list \
  --filter "publisherDomain eq 'garyli.onmicrosoft.com'" -otable

# list secrets
az ad app credential list --id <app-id> \
  --query "[].{Name:displayName, keyId:keyId, EndDate:endDateTime}" -o table
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
    --filter "startswith(displayName, 'sp_name_')" \
    -otable
  ```

- List role assignments in a scope

  See [azure-rbac note](./azure-rbac.markdown#cli)

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


## Monitoring

```
// query service principal sign-in logs
AADServicePrincipalSignInLogs
| where ServicePrincipalName startswith "<service-principal-name>"
| where TimeGenerated > ago(90d)

// query audit logs (updates to the service principal)
AuditLogs
| where TargetResources[0].displayName == '<service-principal-name>'
| where TimeGenerated > ago(90d)
```
