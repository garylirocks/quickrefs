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
- [Hybrid identity](#hybrid-identity)
  - [Concepts](#concepts)
  - [Entra Connect Sync](#entra-connect-sync)
  - [Entra Cloud Sync](#entra-cloud-sync)
  - [Hybrid authentication](#hybrid-authentication)
    - [Password hash synchronization (PHS) (recommended)](#password-hash-synchronization-phs-recommended)
    - [Pass-through authentication (PTA)](#pass-through-authentication-pta)
    - [Federated authentication](#federated-authentication)
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
  - [Concepts](#concepts-1)
  - [Scenarios](#scenarios)
  - [Features](#features)
- [Access reviews](#access-reviews)
  - [Licenses](#licenses)
- [Administrative Units (AU)](#administrative-units-au)
- [Logging and analytics](#logging-and-analytics)
- [Best practices](#best-practices-2)
- [CLI](#cli)
  - [`--filter` parameter](#--filter-parameter)
  - [Group owners](#group-owners)


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


## Hybrid identity

### Concepts

- Identity provisioning
  - **HR-driven provisioning**: from HR system (eg. Workday, Oracle, SAP) to Entra ID
  - **App provisioning**: create users and roles in Cloud apps
  - **Directory provisioning**: from on-prem AD to Entra ID
  - **Inter-directory provisioning**: sync user from on-prem AD to Entra ID
- Authentication methods
  - Cloud authentication (recommended)
    - **Password hash synchronization** (PHS)
    - **Pass-through synchronization** (PTA)
  - Non-cloud auth
    - **Federation** (AD FS)
- **Seamless SSO**: automatically signs in users from their network-connected corporate desktops, so they can access cloud apps without sign-in again.
  - Works with password hash sync and pass-through authentication
    - Does not work with ADFS
  - The computer is AD-joined, no need to be Entra-joined
  - Works on Windows 7 and above, Mac
  - It **isn't** used on Windows 10 Entra-joined devices or Entra hybrid joined devices. SSO on Entra-joined, Entra hybrid joined, and Entra registered devices works based on the Primary Refresh Token (PRT)
  - How it works:
    - During setup, Entra gets an computer account in AD
    - Entra will receive Kerberos tickets
- **Password writeback**: changes made in Entra are written back to on-prem AD, eg. password updated by SSPR
- **Device writeback**: sync Entra registered device to on-prem AD. Used to enable device-based conditional access for ADFS

### Entra Connect Sync

Entra does not replace Active Directory, they can be used together, **Entra Connect** is a software you download and run on your on-prem host, it can synchronize identities between on-prem AD and Entra:

![Entra Connect](images/azure_azure-ad-connect.png)

- AD is the source of truth (most of the time)
- An Entra instance can only sync from one Entra Connect
- But one AD can be linked to multiple Entra Connect, so sync to multiple Entra instances
  - eg. sync one AD to both Azure commercial cloud and Azure US Gov cloud
- Entra Connect can sync to only a verified domain(eg. `contoso.com`, not just `contoso`) in Entra
- You're able to specify the attribute in AD that should be used as UPN to sign in to Entra
- You can filter what objects are synced based on domain or OU in AD
- Requires a SQL Server database to store identity data. By default, a SQL Server 2019 Express LocalDB (a light version of SQL Server Express) is installed.

**Installation**

- You need to provide two accounts/passwords:
  - Entra account: at least with "**Hybrid Identity Administrator**" role
    - Creates another Entra account "On-Premises Directory Synchronization Service Account": used to write information to Entra ID
  - AD DS enterprise administrator
    - Creates "AD DS Connector account" (with name like `ADSyncMSAxxxxx`): read/write info to AD
- Other accounts
  - "ADSync service account": run the sync service and access the SQL Server database

**Configuration**

After installation, you can run the software to configure sign-on method, whether to enable SSO, device hybrid join, etc

### Entra Cloud Sync

- Recommended over Entra Connect Sync
- Need to download and install a lightweight provisioning agent on-prem
- All the management is done in Azure Portal
- Future proof, no need to update
- Could be used along with Connect Sync, as long as scoping filters in each is mutually exclusive

### Hybrid authentication

- PHS and PTA works with seamless SSO, federated auth does not
- This only applies to hybrid users (users synced from on-prem), users created in Entra always use Entra authentication

#### Password hash synchronization (PHS) (recommended)

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

#### Pass-through authentication (PTA)

![Pass through synchronization](images/azure_ad-pass-through-auth.png)

- Authentication Agent
  - Handles the authentication, so if it's down, hybrid users won't be able to sign in to cloud apps
  - High availability:
    - One Authentication Agent is running on the Entra Connect server
    - You should deploy two extra Agents on other servers
  - Networking:
    - The agents need access to Internet (port 80 and 443) and on-prem AD domain controllers
    - No need for inbound connection to the agent
- Why choose this: To enforce on-prem user account states, password policies and sign in hours at the time of sign-in
- You can still optionally enable the "Password synchronization" feature

#### Federated authentication

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
- Use Entra Connect to configure hybrid Entra join,
  - It adds a Service Connection Point (SCP) in your AD
- Your AD-joined device also registers itself with Entra, the device would get an Entra primary refresh token (PRT)

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
- "**Default user role permissions**" can be accessed in the Portal at "Users" -> "User settings"
- All users are granted a set of default permissions, based on:
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
- User can register for these methods in the "My Account" portal
- There's a separate setting for "Password reset"
  - For users, you control whether it is enabled, and what methods are available
  - "Password Reset" is always enabled for administrators, and are required to pass 2 auth methods

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

Get a list of group ids:

```sh
az ad group list \
  --filter "startsWith(displayName, 'mygroup-')" \
  --query '[].{id:id, name:displayName}' \
  -otsv > my-groups.txt
```

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

Find the owners:

```sh
bash get-group-owner.sh my-groups.txt
```
