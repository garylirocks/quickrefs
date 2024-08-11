# Microsoft Graph API

- [Overview](#overview)
- [REST](#rest)
  - [Web experience](#web-experience)
  - [Query paramters](#query-paramters)
  - [PowerShell `Invoke-RestMethod`](#powershell-invoke-restmethod)
  - [CLI](#cli)
- [PowerShell module](#powershell-module)
  - [Install](#install)
  - [Find Command](#find-command)
  - [Authentication](#authentication)
  - [Common operations](#common-operations)
  - [Send an email](#send-an-email)
  - [Limitations](#limitations)
  - [`Microsoft.Graph.Entra` module](#microsoftgraphentra-module)
- [Permission notes](#permission-notes)
- [Misc](#misc)


## Overview

A unified REST API for all Microsoft Cloud services, including Azure AD, Office, Teams, Outlook, etc.

Could be accessed via REST endpoints or various SDKs.


## REST

Endpoint base URL is `https://graph.microsoft.com/v1.0`

Some entities (such as `/groups`) work with
  - Delegated (work or school account) permissions
  - Application permissions

But does **NOT** support **delegated (personal account)** permission, so it doesn't work in Graph Explorer for personal account

### Web experience

- Microsoft Graph Explorer: https://developer.microsoft.com/en-us/graph/graph-explorer
- Managing Apps permissions: https://myapps.microsoft.com/
  - You can view permissions granted by yourself or tenant admin
  - You can revoke permissions granted by yourself

### Query paramters

- Use OData query parameters to help customize the response, NOT all parameters are supported for each entity type, you need check the docs:
  - `$count`
  - `$expand`
  - `$filter`
  - `$orderby`
  - `$search`
  - `$select`
  - `$skip`
  - `$top`

- Some parameter operations are only supported if you request has header `ConsistencyLevel = eventual`

- `$select`: NOT all properties are returned by default, you could use `$select` to specify the required properties explicitly

  ```
  # "department" and "city" are not returned by default
  ~/users?$select=id,displayName,department,city
  ```

- `$filter` on primitive properties

  ```
  # value in a list
  ~/users?$filter=city in ('San Diego', 'Cairo')
  ```

- `$filter` on collection properties

  ```
  # syntax
  $filter=collection/any(property:property/subProperty eq 'value-to-match')

  # filter groups based on type, `i` is the iterator symbol, could be any letter
  ~/groups?$filter=groupTypes/any(i:i eq 'Unified')

  # filter on length of a collection property
  ~/users?$filter=assignedLicenses/$count eq 0
  ```

- `$expand` a complex property

  ```
  # use `$expand` to get the owners of groups
  # you can sue `($select)` to limit the fields returned for the property
  # `$filter` is not supported on the expanded property
  ~/groups?$select=id,displayName,owners,assignedLicenses,foobar&$expand=owners($select=displayName)
  ```


### PowerShell `Invoke-RestMethod`

You could get an access token and call the REST endpoints directly, *Microsoft uses a variety of access token formats depending on the configuration of the API that accepts the token*


```powershell
Connect-AzAccount

$accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
$headers = @{
  'Content-Type' = 'application/json'
  'Authorization' = 'Bearer ' + $accessToken
}

$resp = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/me" -Headers $headers

$resp.givenName
# Gary
```

The `$` sign needs to be escaped with a **backstick** if you use parameters like `$filter`

```powershell
Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users?`$filter=displayName eq 'Alex Wilber'" -Headers $headers
```

### CLI

You need to specify the scope as `ms-graph` to get a correct access toke:

```sh
az account get-access-token --resource-type ms-graph
az rest -u "https://graph.microsoft.com/v1.0/users\?\$filter=displayName eq 'Alex Wilber'"
```

But seems like you can't add more permissions to AZ CLI service principal, tried the following, but failed:

```sh
# Azure CLI global app ID
azCliAppId="04b07795-8ddb-461a-bbee-02f9e1bf7b46"
# Microsoft Graph app ID
msGraphAppId="00000003-0000-0000-c000-000000000000"

# register a service principal in your tenant for Azure CLI
az ad sp create --id $azCliAppId

# grant delegated permission to AZ CLI
az ad app permission grant \
  --id $azCliAppId \
  --api $msGraphAppId \
  --scope "RoleEligibilitySchedule.Read.Directory"

az account get-access-token --scope "https://graph.microsoft.com/RoleEligibilitySchedule.Read.Directory" --query accessToken
# AADSTS65002: Consent between first party application '04b07795-8ddb-461a-bbee-02f9e1bf7b46' and first party resource '00000003-0000-0000-c000-000000000000' must be configured via preauthorization - applications owned and operated by Microsoft must get approval from the API owner before requesting tokens for that API.
```


## PowerShell module

### Install

```sh
Install-Module Microsoft.Graph

Get-Module Microsoft.Graph -ListAvailable
#     Directory: /home/gary/.local/share/powershell/Modules

# ModuleType Version    PreRelease Name                                PSEdition ExportedCommands
# ---------- -------    ---------- ----                                --------- ----------------
# Manifest   1.18.0                Microsoft.Graph                     Core,Desk
```

You might end up with multiple versions of the module installed, to uninstall sub-modules of a specific version:

```pwsh
Get-Module Microsoft.graph* -ListAvailable `
  | ? { $_.version -eq '1.18.0' } `
  | % { Uninstall-Module $_.name -RequiredVersion 1.18.0 }
```

### Find Command

Find "Get" command related to "principal"

```powershell
Get-Command -Module Microsoft.Graph.* -Noun *principal* -Verb Get

# CommandType     Name                                               Version    Source
# -----------     ----                                               -------    ------
# Function        Get-MgServicePrincipal                             1.18.0     Microsoft.Graph.Applications
# Function        Get-MgServicePrincipalAppRoleAssignedTo            1.18.0     Microsoft.Graph.Applications
# Function        Get-MgServicePrincipalAppRoleAssignment            1.18.0     Microsoft.Graph.Applications
# Function        Get-MgServicePrincipalById                         1.18.0     Microsoft.Graph.Applications
# Function        Get-MgServicePrincipalClaimMappingPolicy           1.18.0     Microsoft.Graph.Applications
# ...
```

### Authentication

Always use `Connect-MgGraph` to authenticate first
  - it works with user, app, and managed identity
  - could authenticate with interactive login, certificate, password. See https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph?view=graph-powershell-1.0
  - After login, the scopes given to this session would be a combination of the scopes you consented to and all the admin-consented scopes
  - If you need any new scopes, you can use the `-Scopes` parameter (without the parameter, all the already consented scopes are returned)

```powershell
# interactive login with user, requesting new scopes
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"

# show current context scopes
(Get-MgContext).Scopes
# ...
# Group.Read.All
# openid
# profile
# User.Read
# User.Read.All
# email
```

Login with a service principal, all the granted permissions to the app are included

  - Use secret

    ```powershell
    $TenantId = "<tenant-id>"
    $User = "<username>"
    $PWord = ConvertTo-SecureString -String "<pass>" -AsPlainText -Force

    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $Credential

    (Get-MgContext).Scopes
    ```

  - Use access token (if you already logged in to the service principal with `Connect-AzAccount`)

    ```powershell
    $TenantId = "<tenant-id>"
    $User = "<username>"
    $PWord = ConvertTo-SecureString -String "<pass>" -AsPlainText -Force

    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
    Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $Credential

    # get the access token, need to be converted to secure format
    $accessToken = (Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com").Token
    $accessTokenSecure = ConvertTo-SecureString -String "$accessToken" -AsPlainText -Force

    # login with the access token
    Connect-MgGraph -AccessToken $accessTokenSecure
    (Get-MgContext).scopes
    ```

### Common operations

User

```powershell
# use filters
Get-MgUser -Filter "DisplayName eq 'Alex Wilber'"
```

Group

```powershell
# It's better to use "-Filter", it's more efficient
#   because the filtering happens on the server side
Get-MgGroup -Filter "startsWith(DisplayName, 'Ret')"

# to filter on local
Get-MgGroup | Where-Object {$_.DisplayName -Like 'Ret*'}
```

Get members of a group

```powershell
Get-MgGroupMember -GroupId $groupId | ForEach-Object { @{UserId=$_.Id} } `
                | Get-MgUser -Property "DisplayName,Mail"

# Id DisplayName     Mail                          UserPrincipalName UserType
# -- -----------     ----                          ----------------- --------
#    Gary Li         gary@24g85s.onmicrosoft.com
#    Patti Fernandez PattiF@24g85s.onmicrosoft.com
#    Lee Gu          LeeG@24g85s.onmicrosoft.com
#    Miriam Graham   MiriamG@24g85s.onmicrosoft.com
#    ...
```

Organization

```powershell
# service plans
Get-MgOrganization | Select-Object -expand AssignedPlans

# AssignedDateTime    CapabilityStatus Service                       ServicePlanId
# ----------------    ---------------- -------                       -------------
# 11/28/2022 11:52:22 Enabled          To-Do                         3fb82609-8c27-4f7b-bd51-30634711ee67
# 11/28/2022 11:52:20 Enabled          MicrosoftOffice               531ee2f8-b1cb-453b-9c21-d2180d014ca5
# 11/28/2022 11:52:25 Enabled          OfficeForms                   e212cbc7-0961-4c40-9825-01117710dcb1
# 11/28/2022 11:52:23 Enabled          PowerBI                       70d33638-9c74-4d01-bfd3-562de28bd4ba
# ...
```

### Send an email

```powershell
$message = @{
  "subject" = "Test email"
  "body"    = @{
    "content" = "Hello from Microsoft Graph PowerShell"
  }
  "toRecipients" = @(
    @{
      "emailAddress" = @{
        "address" = "AlexW@24g85s.onmicrosoft.com"
      }
    }
   )
}

Connect-MgGraph -Scopes "Mail.Send"
Send-MgUserMail -UserId "gary@24g85s.onmicrosoft.com" -Message $message
```

### Limitations

- This module is auto-generated off the REST API, so some of the command names are really long, and you may need to call multiple commands to do something.
- Commands does not support pipeline, eg `Get-MgGroup | GetMgGroupMember` does not work


### `Microsoft.Graph.Entra` module

Also based on the same Graph REST API, but has
- tailored commands for certain scenarios, more user-friendly
- supports pipeline, eg. `Get-EntraGroup --SearchString "PIM-test-reader" | Get-EntraGroupOwner -Property "displayName"` (*only return user owners, not any app owners*)
- could be used together with the `Microsoft.Graph` module

```powershell
Install-Module Microsoft.Graph.Entra -AllowPrerelease
# there is also a Beta version `Microsoft.Graph.Entra.Beta`

# list available objects
Get-Command -module Microsoft.Graph.Entra | Select-Object -Unique Noun | Sort-Object Noun
# Noun
# ----
# Entra
# EntraApplication
# EntraApplicationOwner
# EntraApplicationPassword
# EntraApplicationPasswordCredential
# ...
# EntraGroup
# EntraGroupMember
# EntraGroupOwner
# ...
# EntraServicePrincipal
# ...
# EntraUser
# EntraUserManager
# EntraUserMembership
# EntraUserOwnedObject
# EntraUserPassword
# ...
```

Usage

Note: *Some entities do not support delegated permissions for personal account, so you many need to create a **service principal**, grant permissions to it, and then use it on your personal account*

```powershell
# you could login using the same command, specifying the scopes
Connect-MgGraph -Scopes "User.Read.All","Group.Read.All"

# show current context scopes
(Get-MgContext).Scopes

# Use `-Debug` to show all the raw REST queries
Get-EntraUser -SearchString "gary" -Debug
```


## Permission notes

- `AccessReview.ReadWrite.Membership` supposed to be able to create access reviews for group memberships, but seems not work (at least for an SP), `AccessReview.ReadWrite.All` works
- `Group.Create` permission allows an SP to create a group, and adds itself as an owner, then the SP can manage this group, but not other groups, this means the SP does not need the broader `Group.ReadWrite.All` permission

## Misc

- `*-AzureADMS*` commands in the `AzureADPreview` module connects to `https://graph.microsoft.com` as well, but the module does not work in PowerShell Core (v7)
