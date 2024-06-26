# Microsoft Entra ID (formerly Entra)

- [Overview](#overview)
- [SKUs/Licenses](#skuslicenses)
- [B2B](#b2b)
  - [Identity providers](#identity-providers)
  - [Cross-tenant access settings](#cross-tenant-access-settings)
  - [Best practices](#best-practices)
- [B2C](#b2c)
  - [Best practices](#best-practices-1)
- [AD DS vs. Entra ID vs. Entra DS](#ad-ds-vs-entra-id-vs-entra-ds)
  - [Entra DS](#entra-ds)
  - [Entra Connect](#entra-connect)
  - [Hybrid authentication](#hybrid-authentication)
  - [Entra Connect Health service](#entra-connect-health-service)
- [Devices](#devices)
  - [Entra registered](#entra-registered)
  - [Entra joined](#entra-joined)
  - [Hybrid joined](#hybrid-joined)
    - [Device writeback](#device-writeback)
  - [Debugging](#debugging)
- [Users](#users)
  - [Emergence accounts (break-glass accounts)](#emergence-accounts-break-glass-accounts)
- [Groups](#groups)
  - [Group writeback](#group-writeback)
- [Workload identities](#workload-identities)
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
  - [Workload Identity Premium](#workload-identity-premium)
- [Application](#application)
  - [Application management](#application-management)
  - [My Apps portal](#my-apps-portal)
  - [API Permissions](#api-permissions)
  - [Consent](#consent)
  - [App roles](#app-roles)
  - [Expose API](#expose-api)
    - [Example:](#example)
- [SSO](#sso)
  - [SAML](#saml)
- [Azure subscriptions](#azure-subscriptions)
- [Conditional access](#conditional-access)
  - [MFA](#mfa)
  - [Session controls](#session-controls)
  - [App protection policies (APP) on devices](#app-protection-policies-app-on-devices)
  - [Security defaults](#security-defaults)
- [Authentication methods](#authentication-methods)
  - [Methods](#methods)
  - [Management](#management)
  - [Monitoring](#monitoring)
- [Entra roles](#entra-roles)
- [License management](#license-management)
- [Custom security attribute](#custom-security-attribute)
- [SCIM](#scim)
- [Identity protection](#identity-protection)
  - [Policies](#policies)
  - [Investigate and remediate](#investigate-and-remediate)
- [Identity Governance](#identity-governance)
  - [Identity lifecycle](#identity-lifecycle)
- [Entitlement management](#entitlement-management)
  - [Concepts](#concepts)
  - [Scenarios](#scenarios)
  - [Features](#features)
- [Access reviews](#access-reviews)
  - [Licenses](#licenses)
- [Administrative Units (AU)](#administrative-units-au)
- [Logging and analytics](#logging-and-analytics)
- [Application Proxy](#application-proxy)
- [Best practices](#best-practices-2)
- [CLI](#cli-1)
  - [`--filter` parameter](#--filter-parameter)
  - [Group owners](#group-owners)
  - [Application registration and service principal(Enterprise app) owners](#application-registration-and-service-principalenterprise-app-owners)
  - [Applications](#applications)
  - [Service principals](#service-principals-1)


## Overview

Microsoft's identity and access management solution.

- Azure, Microsoft 365, and Dynamics 365 all use Entra, a tenant in these services is automatically an Entra tenant.
- Could be managed in either Azure Portal or Entra admin portal
  - Some aspects could be managed in Office admin portal
- Default domain names are like `*.onmicrosoft.com`, you could bring your own domain name
- "Entra" is the new name for all of Microsoft's identity management service

Objects in Entra

- Users
- Groups
- Applications
- Service principals (including managed identities)
- Devices


## SKUs/Licenses

| Feature                                                           | Free      | Microsoft 365 | Entra ID P1 | Entra ID P2 |
| ----------------------------------------------------------------- | --------- | ------------- | ----------- | ----------- |
| Directory Objects                                                 | 500,000   | Unlimited     | Unlimited   | Unlimited   |
| Single Sign-On                                                    | Unlimited | Unlimited     | Unlimited   | Unlimited   |
| Core Identity and Access Management                               | X         | X             | X           | X           |
| Business to Business Collaboration                                | X         | X             | X           | X           |
| Identity & Access Management for Microsoft 365 apps               |           | X             | X           | X           |
| Premium Features                                                  |           |               | X           | X           |
| Hybrid Identities                                                 |           |               | X           | X           |
| Advanced Group Access Management                                  |           |               | X           | X           |
| Conditional Access                                                |           |               | X           | X           |
| Identity Protection (risk users)                                  |           |               |             | X           |
| Identity Governance (PIM, access reviews, entitlement management) |           |               |             | X           |

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
  - custom Entra roles (not Azure RBAC roles)
  - allow hybrid users access both on-prem and cloud resources
  - dynamic groups
  - self-service group management
  - Microsoft Identity Manager (on-premises identity management suite, allows self-service password reset for your on-prem users)
  - conditional access policy (based on user's location, device etc, then allow/block access or require multi-factor authentication)

- Premium P2
  - Active Directory Identity Protection: identify risky users and risky sign-ins
  - Privileged Identity Management: just-in-time (JIT) privileged access control

- Pay-as-you-go
  - Entra B2C: manage identity and access for consumer users

Features:

- B2B identity services (*available to all tiers*)
- B2C identity services (for customer users of your service, *pay-as-you-go*)


## B2B

- Allow users from other organizations to use apps and resources in your tenant
- External users can be invited as
  - **guests** (with "**#EXT#**" extension in their user principal name)
  - or **members**
- Who can invite:
  - By default, all users (including guests) can invite guests, if this is turned off, you can assign "Guest Inviter" role explicitly to users
  - You can create either a allow list or a deny list to control what external domains are allowed
- How guest user sign in:
  - Guest user won't have credentials saved in your tenant, they will login via another Entra, an email code, SMS code, Google/Facebook account, etc
  - By default these IdPs are configured: Entra, Microsoft Account, Email one-time passcode
  - If you invite an Gmail account, by default the user would sign-in with one-time passcode, after you add Google as an IdP (you need Client ID and Client Secret), then the user sign in with Google's sign-in experience
  - You can customize the Terms of Use the invited user needs to agree
  - The user is usually redirected to My Apps portal (`https://myapps.microsoft.com/?tenantid=<tenant-id>`)
- Guests can be granted any Entra roles, just like members

<img src="images/azure_ad-external-identities.png" width="600" alt="Guest users" />

Your could invite people from other external identity providers as guest users, you control what they can access to, and for how long, the process is like this:

<img src="images/azure_ad-b2b.svg" width="600" alt="B2B process" />

### Identity providers

- Google
  - *for Gmail account only, use federation for G Suite domains*
- Facebook
  - only for signing up through apps using self-service sign-up user flows
- Any other third party IdP which supports SAML 2.0 or WS-Fed protocol.
  - The target domain must not be DNS-verified on Entra
  - Some attributes/claims are required in SAML response/token from IdP
  - The WS-Fed providers tested: AD FS, Shibboleth

### Cross-tenant access settings

For any other Entra tenant, you could set

- Inbound access
  - B2B collaboration:
    - What users/groups in the other tenant are allowed to be invited as guests
    - What applications are allowed
  - B2B direct connect (whether external users can access your resources without being invited as guests)
  - Cross-tenant Sync: whether allow other tenant to sync users into this tenant
  - Trust settings: whether your Conditional Access policies accept claims (MFA, compliant devices, hybrid Entra joined devices) from other Entra tenant
- Outbound access
  - B2B collaboration
  - B2B direct connect
  - Trust: whether your users need to accept the consent prompt the first time they access the other tenant
- Tenant restrictions // TODO

Notes:

B2B direct connect feature
  - is blocked by default
  - need to be enabled on both sides
  - currently works with Microsoft Teams shared channels
    - user A creates a shared channel in tenant A, invites user B from tenant B
    - user B can access the channel from tenant B Teams instance

### Best practices

- **Designate an application owner to manage guest users**. Application owners are in the best position to decide who should be given access to a particular application. Typical setup:
  - Enable self-service group management
  - Create a group and make the user an owner
  - Configure the app for self-service and assign the group to the app
- Use **conditional access** policies to grant or deny access
- Enable MFA, this happens **in your tenant**
- **Create a self-service sign-up user flow**, you could customize the experience


## B2C

<img src="images/azure_ad-b2c-tenant.png" width="600" alt="B2C process" />

B2C tenant is for your application's customers, it's different from your organization's tenant

<img src="images/azure_ad-b2c.svg" width="600" alt="B2C process" />

### Best practices

- Configure user flows
- Customize user interface
- Integrate with external user stores: you could save up to 100 custom attributes per user in Entra B2C. You could also use Entra B2C for authentication, but delegate to an external CRM or customer loyalty database for customer data.


## AD DS vs. Entra ID vs. Entra DS

|            | AD DS                                                                      | Entra ID                                                       | Entra DS                                   |
| ---------- | -------------------------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------ |
| Purpose    | Introduced in Windows 2000, for on-premises identity and access management | Microsoft 365, Azure Portal, SaaS applications                 | A subset of AD DS features, lift-and-shift |
| Deployment | Windows Server (On-prem or IaaS VMs)                                       | Cloud based                                                    | Cloud                                      |
| API        | LDAP                                                                       | REST (HTTPS)                                                   | same as AD DS                              |
| Protocols  | Kerberos authentication                                                    | SAML, WS-Federation, OpenID Connect for authN, OAuth for authZ | same as AD DS                              |
| Structure  | Organization Units (OUs) , Group Policy Objects (GPOs)                     | flat users and groups, no OU hierarchy                         | same as AD DS                              |

### Entra DS

<img src="images/azure_aadds-sync.png" width="800" alt="AADDS Syncing" />

_On prem AD is optional here_

- Intended to lift and shift your legacy applications from your on-prem to a managed domain.
- Supports
  - Domain join
  - Group policy
  - LDAP
  - Kerberos and NTLM authentication
- You define the domain name, two Windows Server DCs are then deployed into your selected Azure region as a replica set.
- Replica sets can be added to any peered virtual network in other regions.
- You don't need to deploy, manage and patch Domain Controllers (DCs).
- A one-way sync is configured from Entra to the managed domain, so you could login to a Windows VM using your Entra credentials.

### Entra Connect

Entra does not replace Active Directory, they can be used together, **Entra Connect** is a software you download and run on your on-prem host, it can synchronize identities between on-prem AD and Entra:

![Entra Connect](images/azure_azure-ad-connect.png)

- AD is the source of truth (most of the time)
- An Entra instance can only sync from one Entra Connect
- But one AD can be linked to multiple Entra Connect, so sync to multiple Entra instances
  - eg. sync one AD to both Azure commercial cloud and Azure US Gov cloud
- Entra Connect can sync to only a verified domain(eg. `contoso.com`, not just `contoso`) in Entra
- You're able to specify the attribute in AD that should be used as UPN to sign in to Entra
- You can filter what objects are synced based on domain or OU in AD
- Alternatively, you could use **Entra Cloud Sync** to run the syncing in cloud instead of on-prem
  - You still need to download and install a lightweight provisioning agent on-prem
  - All the management is done in Azure Portal

### Hybrid authentication

Cloud authentication (both works with seamless SSO):

- **Password hash synchronization** (recommended)

  ![Password hash synchronization](images/azure_ad-password-hash.png)

  - Most basic and least-effort solution in hybrid scenario
  - Allows on-prem user to auth against Entra for cloud applications
  - On-prem AD stores user password as a hash, AD Connect retrieves the hash and hashes that hash, sends the second hash to Entra
    - Password hash is synced every 2 minutes, more frequent than other AD objects
    - You can set up a selective password hash sync
  - Hight availability: you should deploy a second Entra Connect server in standby mode
  - On-prem account state changes are NOT synced to Entra immediately, you might want to trigger a new synchronization cycle after bulk update on-prem.
  - Even if you are using another auth method, you should still **enable "Password synchronization" feature**, this helps as a back-up for
    - High availability and disaster recovery
    - On-prem outage survival
    - Identity protection: check if the password is leaked

- **Pass-through authentication**

  ![Pass through synchronization](images/azure_ad-pass-through-auth.png)

  - Passwords only stored in on-prem AD, not in the Entra
  - Only on-prem AD is used to authenticate
  - It's a tenant-level feature, turning it on affects the sign-in for users across all the managed domains in your tenant.
  - High availability:
    - One agent is running on the Entra Connect server
    - You should deploy two extra agents on other servers
  - The agents need access to Internet and on-prem AD domain controllers
  - Why choose this: To enforce on-prem user account states, password policies and sign in hours at the time of sign-in

**Federated authentication**:

![Federated synchronization](images/azure_ad-federated-auth.png)

Entra hands off authentication process to a separate trusted authentication system, such as on-prem AD FS, to validate the user's password.

- The authentication system could provide other authentication requirements: smartcards, third-party MFA, etc
- Does not authenticate against on-prem AD
- You authenticate against a third party federation service, which gives you a SAML token, you then exchange this SAML token for Entra tokens (refresh & access tokens)
- Why choose this:
  - Features not supported by Entra: smartcards or certificates
  - On-prem MFA servers or third-party multifactor providers requiring a federated IdP
  - Sign in that requires SAMAccountName(`DOMAIN\username`) instead of UPN(`user@domain.com`)
- High availability: federated systems typically require a load-balanced array of servers, known as a farm.
- More complex to operate and troubleshoot compared to cloud authentication

Related concepts:

- **Seamless SSO**: automatically signs in users from their network-connected corporate desktops, so they can access cloud apps without sign-in again.
  - Works with password hash sync and pass-through authentication
  - The computer is AD-joined, no need to be Entra-joined
  - Works on Windows 7 and above, Mac
  - How it works:
    - During setup, Entra gets an computer account in AD
    - Entra will receive Kerberos tickets
- **Password writeback**: changes made in Entra are written back to on-prem AD, eg. password updated by SSPR
- **Device writeback**: sync Entra registered device to on-prem AD. Used to enable device-based conditional access for ADFS

### Entra Connect Health service

- Entra premium license required to configure this
- Can be used with:
  - Entra Connect Sync, installed automatically with the Sync agent
  - ADFS servers, manual installation
  - AD DS servers, manual installation
- Can send email notifications
- Supports RBAC roles: Owner, Contributor, Reader
- Entra Global Administrator always have full access to all the operations.


## Devices

Three ways to add a device to a domain:

- Entra registration  (for BYOD)
- Entra join (for work devices)
- Entra hybrid join (interim step to Entra join)

Usage:

- Device-based Conditional Access policies
- Enable users SSO to cloud-based resources
- Mobile device management (MDM) solution such as Microsoft Intune, provides additional attributes in Entra

### Entra registered

- Scenarios:
  - Bring your own device (BYOD), eg. home PC, laptop
  - Mobile devices such as phones and tablets
- OS: Windows, iOS, Android, Ubuntu etc.
- Sign in with: end-user local credentials, password, Windows Hello, PIN Biometrics
- Device management: eg. Microsoft Intune, which could enforce:
  - storage to be encrypted
  - password complexity
  - security software being updated
- Capabilities:
  - SSO to cloud resources, using an Entra account attached to the device
  - Conditional Access policies can be applied to the device identity

### Entra joined

- Primarily intended for organizations without on-prem AD
- Usually a work/school device, you login with your work/school account
- OS: Works on Windows 10 & 11 (and above)
- Capabilities:
  - SSO to both cloud and on-prem resources
  - Conditional Access
  - Self-service password reset
  - Windows Hello PIN reset
- Device management: MDM, eg. Microsoft Intune
  - Storage encryption, software being updated, etc
  - Make org applications available to devices using Configuration Manager
- How to join:
  - Out of Box Experience (OOBE)
  - bulk enrollment
  - Windows Autopilot
- You can still login to an Entra joined machine using a non Entra account
- If you want to RDP an Entra joined machine using an Entra account
  - you use username in the form like `MyAAD\gary@example.com`
  - your local machine needs to be Entra joined/registered or hybrid joined
  - you can't use MFA during RDP login, but you could assign conditional access policy
- To Entra join an Azure Windows VMs:
  - Windows Server 2019 and later
  - Windows 10 and later
  - With `AADLoginForWindows` extensions installed
  - the user needs either "Virtual Machine User Login" or "Virtual Machine Administrator Login" RBAC role, to login to the VM using Entra authentication

### Hybrid joined

- The device is AD joined and Entra registered
- OS: Windows 7 and above, Windows Server 2008/R2 and above
- Sing in with: Password or Windows Hello for Business
- Management:
  - Group Policy
  - Configuration Manager standalone
  - or co-management with Microsoft Intune
- Capabilities: same as Entra joined devices
- You set a Service Connection Point (SCP) in Entra Connect, then Entra Connect will sync your on-prem device objects to Entra
- Your AD-joined device also registers itself with Entra, the device would get an Entra primary refresh token

#### Device writeback

- Keep track of Entra registered devices in AD
- You'll have a copy of the device objects in the container "Registered Devices"
  - ADFS issues "is managed" claim based on whether the device object is in the "Registered Devices" container
- Window Hello For Business (WHFB) requires device writeback to function in Hybrid and Federated scenarios

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
  - Member (could be defined in this Entra, another Entra, or synced from on-prem AD)
  - Guest (accounts from other cloud providers, with "#EXT#" in the name)
- If a user is assigned a Entra role, then the user is called an **administrator**
- Users with Global Administrator or User Administrator role can create new users
- When you delete an account, the account remains in suspended state for 30 days
- Users can also be added to Entra through Microsoft 365 Admin Center, Microsoft Intune admin console, and the CLI
- All users are granted a set of default permissions, a user's access consists of:
  - the type of user (member or guest)
  - their role assignments
  - whether they are owner of a object

### Emergence accounts (break-glass accounts)

- Two or more
- Not associated with any individual user
- If password is used, it should be strong and **not expire**
- Use a different strong authentication method than regular accounts
  - Exclude at least one account from phone-based MFA (use **other types of MFA**)
  - Exclude at least one account from all Conditional Access policies
- "Global Administrator" role assigned **permanently** in PIM
- Should be **cloud-only**, uses the `*.onmicrosoft.com` domain
- Not federated or synchronized from on-prem environments
  - Entra prevents the last Global Administrator account from being deleted, but it doesn't prevent the account from being deleted or disabled on-premises
- Trigger alerts whenever an emergence accounts sign in, use a KQL query like:
  ```kusto
  SigninLogs
  | project UserId
  | where UserId == "f66e7317-2ad4-41e9-8238-3acf413f7448"
  ```


## Groups

- Group types
  - Security groups
    - Members can be
      - users
      - devices
      - service principals
      - and other groups
    - For access control(RBAC), assigning licenses, etc
  - Microsoft 365
    - Members can only be users
    - For sharing/collaboration over M365 apps: giving members access to shared mailbox, calendar, files, teams(not channels) in MS Teams, etc
  - Distribution: for Exchange
- Membership types
  - Assigned: assigned manually
  - Dynamic User: based on users' attributes
  - Dynamic Device: based on devices' attributes

Note:

- In the Azure portal, you can see all the groups, but you can't edit some of them:

  - Groups **synced from on-premises Active Directory** can be managed only in on-premises Active Directory.
  - Other group types such as **distribution lists** and **mail-enabled security groups** are managed only in Exchange admin center or Microsoft 365 admin center.

- There is a flag determining whether a group can be assigned "Entra Roles"
- Group owners
  - Owner can be user or SP, not group
  - When an SP creates a group, it will be added as the owner automatically
  - If a group has only one user owner, this user owner can't be removed, even the group has an SP owner

### Group writeback

- Uses Entra Cloud Sync (not Connect Sync)
  - You may be syncing only certain OUs from AD to cloud, this does not affect the group writeback
- Scopes
  - Group source must be **Cloud** (not Windows Server AD), type must be **Security** (not distribution list)
  - Could be selected groups, or all eligible groups
- Target
  - You could specify a constant OU
  - Or use an expression to map to OUs dynamically
- In AD, it
  - Creates groups
  - Adds users to the groups
    - users must be existing in AD already
    - if a user was created in cloud, does not exist in AD, it will be skipped
  - The group created in AD should NOT be edited in AD, you should update it in the cloud


## Workload identities

<img src="images/azure_identity-types.svg" width="600" alt="Identity types" />

### App registrations vs. Service principals

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

Microsoft maintains two directories internally to publish applications:

![Microsoft directories for applications](images/azure_ad-application-vs-service-principal.png)

- Microsoft services directory - for Microsoft Apps
- App gallery directory - for pre-integrated third party apps


### Service principals

In general, there are three types of service principals:

- **Legacy**
- **Application**
- **Managed Identity**

### Service principals (application)

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

### Managed identities

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

#### System-assigned (SAMI)

A resource can have only one system-assigned managed identity, if the resource is deleted, so is the managed identity

```sh
# assign a system-assigned managed identity to a VM
az vm identity assign \
    --name <vm name> \
    --resource-group <resource group>
```

#### User-assigned (UAMI)

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

#### Considerations

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

### Workload identity federation

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

#### How it works

It creates a trust relationship between external IdP and a UAMI or app reg in Microsoft Entra.

![Workload identity federation](images/azure_workload-identity-federatjion-workflow.svg)

#### CLI

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

### Workload Identity Premium

- It's a standalone product, you need a license for it
  - Not included in other product plans, like Entra ID P1/P2, E5
  - Charges you $3 per workload ID per month
- One license in the tenant unlocks all the features for all the workload IDs, NO need to assign licenses to individual workload IDs
- Provides more security features for workload identities:

| Feature            | Service principal                | Managed identity | Note                        |
| ------------------ | -------------------------------- | ---------------- | --------------------------- |
| Conditional Access | Y (single-tenant app only)       | N                | eg. IP range                |
| ID Protection      | Y (single and multi-tenant apps) | N                | Detect compromised IDs      |
| Access Review      | Y                                | Y                | Review PIM role assignments |


## Application

Three types of applications:

| Type                             | App Registrations | Enterprise applications | How                                                               |
| -------------------------------- | ----------------- | ----------------------- | ----------------------------------------------------------------- |
| Gallery (SAML, Password, Linked) | Yes               | Yes                     | Add from the gallery, an app instance added to your tenant        |
| Gallery (OpenID Connect)         | **No**            | Yes                     | Sign-in/sign-up, the app will be added to Enterprise applications |
| Your own                         | Yes               | Yes                     | Add in App registrations                                          |
| On-prem                          | Yes               | Yes                     | Entra App Proxy                                                   |

- Pre-integrated applications (can be added from the gallery)
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

- User.Read.All
- Groups.Read.All
- Directory.ReadWrite.All

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
  - For application-only scopes, use "App roles" and define app roles assignable to applications.
- Application ID URI need to be globally unique, usually has the form `api://<app-id>`, eg. `api://dev.guisheng.li/demo/api1`
- You could add another application as an authorized client application to the scopes, then user won't be prompted to consent when login to the client application.
- When a client app requests the scope in its OAuth request, and the user consents (or pre-approved), Entra sends back an access token which contains the required scopes

#### Example:

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
    - User logins to Entra
    - Entra redirects to the application's login page
    - The browser extension fill in username, password and log in
  - The username and password, could be either:
    - Configured for user/group in Entra "Enterprise applications"
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

![Entra SSO options](./images/azure_ad-single-sign-on-options.png)

### SAML

The configuration process varies depending on the application.

*You can use **[Entra SAML Toolkit](https://samltoolkit.azurewebsites.net/)** application for testing*

Usual steps:

- Basic configs (the URLs will be updated later, so doesn't matter in this step)
  - Identifier (Entity ID) - must be unique across all applications in your tenant
  - Reply URL (Assertion Consumer Service URL) - where the application expects to receive the SAML response (token)
  - Sign on URL - the sign-in page URL of the app

- Configs in the app
  - Entra login URL
  - Entra identifier
  - Entra logout URL
  - Signing certificate (downloaded from Entra)

- Update URLs in Entra (get them from the app)
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


## Azure subscriptions

- Each Azure subscription is associated with a single Entra directory (tenant);
- Users, groups and applications in that directory can manage resources in the subscription;
- Subscriptions use Entra for SSO;


## Conditional access

Only available for P1/P2 license

![Conditional access](images/azure_ad-conditional-access.png)

Microsoft uses a *variety of access token formats* depending on the configuration of the API that accepts the token, here is how access tokens are issued:

![Access token issuance](images/azure_ad-access-token-issuance.png)
*Block policy has higher precedence*

Common policies:

- Require MFA for admin users
  - Excluding service accounts and service principals, they can't do MFA
- Respond to risky users and risky sign-ins
- Block unknown locations
- Require compliant devices (with info from Intune), compliance requirement could be
  - A PIN to unlock
  - Device encryption
  - Minimum OS version
  - Not jailbroken or rooted
- Require approved client applications
- Require trusted location/compliant device/hybrid joined device to register MFA or SSPR
- Enforce a user to consent to the terms of use

Best practices:

- **More granular MFA experience**: eg. only trigger MFA from an unexpected location (Free license user only have a default MFA option, can't customize conditions)
- **Test with report-only mode**: evaluate access policy effect before enabling them
  - You can also emulate a user sign-in under certain conditions with the "**What if**" tool
- **Block geographic areas**: you could define named locations, and block sign-in from them
- **Require manged devices**
- **Require approved client applications**
- **Block legacy authentication protocols**
- For a block policy, exclude at least one **emergency account**
- You could also use sign-in risk (form Identity Protection) as a condition

### MFA

A users status could be:

- Disabled
- Enabled: enrolled for MFA
- Enforced: the user completed the registration process

### Session controls

- Implemented via *Conditional Access App Control policies in Microsoft Defender for Cloud Apps*
- You can:
  - Prevent data exfiltration: download, copy, print sensitive documents
  - Protect on download
  - Prevent upload of unlabeled files
  - Monitor user sessions
  - Block custom actions: like sending sensitive content in Teams or Slack
- Continuous access evaluation (CAE)
  ![Continuous access evaluation](images/azure_ad-continuous-access-evaluation.png)
  - By default, an access token is valid for 1 hour, it can't be revoked
  - With CAE, in some cases(eg. user disabled, password change, location change, etc), IdP sends a revocation event to resource provider, which checks revocation for the user when verifying an access token

### App protection policies (APP) on devices

Rules that ensure an organization's data remains safe or contained in a managed app.

Can be configured for apps that run on devices that are:

- Enrolled in Microsoft Intune
- Enrolled in a third-party MDM solution
- Not enrolled in any MDM solution (for BYOD scenarios)

Benefits:
- Protect company data at the app level
- Don't apply when using the app in a personal context
- MDM is not required, but beneficial


### Security defaults

A tenant-wide setting, provides secure default settings until organizations are ready to manage their own identity story. You'll need to disable "Security defaults" if you want to define your own Conditional Access policy.

- Requiring all users to register MFA, and perform MFA when necessary
- Admins must perform MFA for every sign-in
- Block legacy auth:
  - Clients that don't use modern authentication (such as OAuth 2.0), like Office 2010 client, which does not support MFA
  - Mail protocols such as IMAP, SMTP, or POP3
- Protect privileged activities like access to the Azure portal


## Authentication methods

### Methods

- Passwordless
  - **Windows Hello for Business**
    - Uses PIN or biometics recognition (face, fingerpint)
    - PC with a built-in Trusted Platform Module (TPM)
    - Tied to a device
    - Typical scenarios: dedicated work PC
    - For on-prem, it needs a `KeyCredential Admins` security group and the `Windows Hello for Business Users` security groups
    - How it works:
      - Keys can be generated by hardware(TPM) or software
      - During registration, a public key is mapped to a user account
      - You use biometrics or PIN to unlock the private key
      - The private key is used to sign data that is sent to IdP
      - IdP uses public key to verify and authenticate the user
      - Both biometrics and PIN are not shared with the server
  - **FIDO2** security keys
    - FIDO stands for Fast IDentity Online, it's an open standard
    - Keys are typically USB devices, but could also use Bluetooth or NFC
    - Phishing resistant
    - You buy the key from a third party vendor
    - Typical scenarios: shared devices in a factory, plant, retail, etc
  - Microsoft Authenticator app
    - PIN and biometrics recognition on phone
    - The App could be used for passwordless sign-in, MFA and SSPR
- App password: for certain non-browser apps which don't support Entra MFA, you could use app specific password
- SSPR only
  - Security questions
  - Email address

### Management

- You can set policies to control which methods are available to which users

### Monitoring

- Registration and usage activities
- View which methods are available to each user


## Entra roles

![Role categories](images/entra_role-categories.png)

- Three broad categories:
  - Entra ID specific roles: eg. User/Groups/Application Administrator
  - Service-specific roles: eg. Exchange/Intune Administrator
  - Cross-service roles: eg. Global Admin, Security Admin
- NOT the same as Azure roles, see [Azure RBAC](./azure-rbac.markdown)
- Usually can only be assigned to users/applications, not groups (unless the groups has enabled "AD Role assignment" toggle)
- Built-in roles can only be assigned at the scope of wither the whole directory or an "Administrative Unit"
- You can create custom roles, which can be assigned to a single Entra object, eg. a user/group/device/application

```sh
# list Entra roles
az rest -u "https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions" --query "value[].{Name: displayName, ID: id}" -otable

# filter and select
az rest -u "https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions?\$filter=DisplayName eq 'Global Reader'&\$select=id" \
  --query "value[0].id" \
  -otsv
```


## License management

A license could be assigned to a user, or a group.

Group-based licensing allows you assign licenses to groups, all users in the group will get the licenses

- Can be any security group (cloud-only or synced from AD)
- When a user joins/leaves a group, the license is added/removed automatically for the user
- If a user got the same license multiple times via multiple groups, the license is only consumed once
- A *product license* could have multiple **service plans**, some of the plans could be disabled (eg. disable Yammer service in Microsoft 365)
- Available only through Azure portal
- There might be errors due to various reasons, like:
  - Not enough licenses left
  - Service plans have conflicts
  - Service not available at a user's usage location (defaults to the directory's location)
- You could force group/user license process tor resolve errors


## Custom security attribute

- Business-specific attributes (key-value pairs, like tags) that you can define and assign to Entra objects. Could be used to:
  - store information
  - query and filter Entra objects
  - enforce access control
  - as conditions in RBAC role assignment
- Only users with *Attribute Definition Administrator* role can create custom security attributes


## SCIM

SCIM (System for Cross-domain Identity Management) can sync identities from Entra and another system
  - it provides a common user schema for provisioning
  - uses REST API
  - defines two endpoints `/users` and `/groups`

![SCIM overview](images/azure_ad-scim.png)

Entra SCIM Functions:

- Automate Provisioning/deprovisioning: create/remove accounts in the right system
- Synchronize data between systems
- Provision groups: create groups in the application
- Monitor and audit
- Deploy in brownfield scenarios
- Customizable attribute mappings
- Alerts for critical events

Scenarios:

- Use HCM to manage employee lifecycle, the user's provile synced to Entra automatically
- Provision users and groups in another application


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
  - Password spray: brute force attack, using same password against multiple users

### Policies

- Sign-in risk policy
- User risk policy
- MFA registration policy
  - Enforce MFA registration for users/groups

Note:
- Microsoft suggests migrating both sign-in risk and user risk policies to Conditional Access for more conditions and controls
- Break-glass accounts should be excluded

### Investigate and remediate

- Admin should get all risk detection closed, so the affected users are no longer at risk
- To allow self-remediate, the user need to be previously registered for both MFA and SSPR


## Identity Governance

Includes features like Entitlement management and access reviews

### Identity lifecycle

![Identity lifecycle](images/entra_identity-lifecycle.png)

- Inbound provisioning from HR system (eg. Workday)
- **Lifecycle workflows** to automate tasks that run at certain key events, like sending a welcome email to the user on their first day
- Automatic assignment policies in entitlement management, based on user's attribute
- User provisioning via SCIM, LDAP, SQL


## Entitlement management

### Concepts

![Entitlement management overview](images/azure_ad-entitlement-management-overview.png)

- **Catalog**:
  - A container of resources and access packages
  - Apart from Global Administrator, and Identity Governance Administrator, you can designate other users/groups as Catalog creators.
    - Whoever creates it becomes the first catalog owner
    - The owner can add other roles and admins to the catalog
      - Catalog owner
      - Catalog reader
      - Access package manager
      - Access package assignment manager
- **Resource**:
  - Membership of cloud-created security groups, *this implies access to other roles/permissions granted to the groups*:
    - Azure roles
    - Entra roles
    - Microsoft 365 licenses
  - Membership of cloud-created Microsoft 365 Groups and Teams
  - Assignment to Entra enterprise applications
  - Membership of SharePoint Online sites/site collections
- **Access package**:
  - A bundle of all the resources with the access a user needs to work on a project or in a role
  - An package could have include a subset of resources in a catalog
- **Policy**:
  - A set of rules that defines how users get access, who can approve, and how long users have access through an assignment
  - An access package could have two policies: one for employees, and another for external users
- **Custom extension**
  - A Logic App that could be triggered for events like "Request is approved", "Assignment is granted", etc

### Scenarios

- Employees need time-limited access for a particular task
- Access requires approval of a manager
- Department wish to manage their own access policies without IT involvement
- Multiple organizations need to collaborate on a project, multiple user from one org need access to another org's resources

### Features

- You can define an access review along with an access package
- Requester could submit a custom start or end date for their access
- Users can use `https://myaccess.microsoft.com` portal to request/approve both access packages and access reviews


## Access reviews

- A feature of Microsoft Entra ID Governance
- One-time or recurring for attestation of a principal's right to access Entra resources
- The principals are
  - Users
  - or applications (service principals)
- The Entra resources include:
  - Group
  - Applications
  - Access packages
  - Privileged roles
- You can create reviews for **Guest Users Only** or **Everyone**
- Who can do the review is depending on the resource type, for example, group membership can be reviewed by:

  - Administrators
  - Group owners
    - Best reviewers in most cases
  - Selected users, delegated review capability when the review is created
    - Groups synced from on-prem AD can not have owners in Entra, you should specify reviewers while creating the review, reviewers will need to take action in on-prem AD
  - Members of the group, attesting for themselves

### Licenses

Access review is a Entra Premium P2 feature.

These users requires P2 licenses:

- Users who are assigned as reviewers
- Users who perform self-review
- Users as group owners who perform an access review
- Users as application owners who perform an access review


## Administrative Units (AU)

- To restrict administrative scope in organizations that are made up of independent divisions, eg. School of Business, School of Engineering in a University
- Membership
  - You could put users/groups/devices to a unit
  - Support dynamic membership rules
  - No nesting
- A unit is a scope for Entra role assignment
  - You only get permissions over direct members in the unit, not users in a group, you need to **add them explicitly** to the unit
  - For groups in a unit, you can change group name or membership
- Only a subset Entra roles can be assigned:
  - User administrator
  - Groups administrator
  - Password administrator
  - Authentication administrator
  - Helpdesk administrator
  - License administrator
- For a **restricted management administrative unit**, only admins with roles assigned at the unit scope can manage objects in it, not global admins.
  - Could be used to lock down some highly sensitive accounts
  - If an object is in multiple AUs, admin at any AU could manage it
- You need a P1 license to manage an AU, users in the AU do not need P1


## Logging and analytics

Entra reporting components:

- Activity
  - Sign-in logs (for human interactive sign-ins)
  - Other sign-in logs
    - NonInteractiveUserSignInLogs
    - ServicePrincipalSignInLogs
    - ManagedIdentitySignInLogs
  - Audit logs
  - Provisioning logs: eg, creating a group in ServiceNow or a user imported from Workday
- Security
  - Risky sing-ins
  - Users flagged for risk

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


## Best practices

- Give at least two accounts the **Global Administrator** role, DON'T use them daily;
- Use regular administrator roles wherever possible;
- Create a list of banned passwords (such as company name);
- Configure conditional access policies to require users to pass multiple authentication challenges;


## CLI

### `--filter` parameter

The `--filter` parameter in many `az ad` commands seems to be following the old Entra Graph API (not the newer Microsoft Graph API) ? check available filters here https://learn.microsoft.com/en-us/previous-versions/azure/ad/graph/howto/azure-ad-graph-api-supported-queries-filters-and-paging-options

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

### Group owners

Create a script to get group owners:

```sh
# get-group-owner.sh
readarray rows < $1

for row in "${rows[@]}";do
    row_array=(${row})
    gid=${row_array[0]}
    echo ${row_array[@]}
    az ad group owner list -g $gid --query "[].displayName" -otsv
done
```

Then get a list of group ids and find the owners:

```sh
az ad group list \
  --filter "startsWith(displayName, 'mygroup-')" \
  --query '[].{id:id, name:displayName}' \
  -otsv > my-groups.txt

bash get-group-owner.sh my-groups.txt
```

### Application registration and service principal(Enterprise app) owners

- A user is automatically added as an application owner when they register an application
  - Ownership for an enterprise application is assigned by default only when a user with no administrator roles (Global Administrator, Application Administrator etc) creates a new application registration.
- A good practice is to have at least two owners for an application.
- In the Portal, you could only add users as app registration and enterprise app owners
- Groups can't be owners.
- An service principal can be owner of an app registration, but not another SP (enterprise app).
- To add an service principal as owner of an app registration, you could use CLI or API, see https://github.com/Azure/azure-cli/issues/9250#issuecomment-603621148.

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
