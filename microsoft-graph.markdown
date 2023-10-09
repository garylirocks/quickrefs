# Microsoft Graph API

- [Overview](#overview)
- [Web experience](#web-experience)
- [REST](#rest)
  - [CLI](#cli)
- [PowerShell module](#powershell-module)
  - [Install](#install)
  - [Find Command](#find-command)
  - [Common operations](#common-operations)
  - [Send an email](#send-an-email)
  - [Entra roles in PIM](#entra-roles-in-pim)
- [Misc](#misc)


## Overview

A unified REST API for all Microsoft Cloud services, including Azure AD, Office, Teams, Outlook, etc.

Could be accessed via REST endpoints or various SDKs.

## Web experience

- Microsoft Graph Explorer: https://developer.microsoft.com/en-us/graph/graph-explorer
- Managing Apps permissions: https://myapps.microsoft.com/
  - You can view permissions granted by yourself or tenant admin
  - You can revoke permissions granted by yourself


## REST

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

### Common operations

Connect

```powershell
# login with specified scopes
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

### Entra roles in PIM

Connect, you need to specify the correct scope, since the Microsoft Graph API is protected, this would require admin or user consent granted to the client app (Microsoft Graph PowerShell)

See this page for all related permissions: https://learn.microsoft.com/en-us/graph/permissions-reference#role-management-permissions, be mindful about `*.All` and `*.Directory` permissions

- `RoleManagement.Read.All` this is for all supported RBAC providers (Cloud PC, device management/Intune, AAD directory, AAD entitlement management, Exchange Online), see [here](https://learn.microsoft.com/en-us/graph/api/resources/rolemanagement?view=graph-rest-beta&preserve-view=true)
- `RoleManagement.Read.Directory`: just for AAD role management

Login and get my principal ID

```powershell
Connect-MgGraph -Scopes "RoleAssignmentSchedule.ReadWrite.Directory"

$myUpn=(Get-MgContext).Account
$myPrincipalId=(Get-MgUser -Filter "UserPrincipalName eq '$myUpn'").Id
```

Self activate an eligible assignment

```powershell
$params = @{
  "PrincipalId" = $myPrincipalId
  "RoleDefinitionId" = (Get-MgDirectoryRole -Filter "DisplayName eq 'Application Administrator'").RoleTemplateId
  "Justification" = "Activate assignment"
  "DirectoryScopeId" = "/"
  "Action" = "SelfActivate"
  "ScheduleInfo" = @{
    "StartDateTime" = Get-Date
    "Expiration" = @{
      "Type" = "AfterDuration"
      "Duration" = "PT1H"
    }
  }
}

New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest `
  -BodyParameter $params |
  Format-List Id, Status, Action, AppScopeId, DirectoryScopeId, RoleDefinitionID, IsValidationOnly, Justification, PrincipalId, CompletedDateTime, CreatedDateTime, TargetScheduleID
```

List active assignments

```powershell
# show active assignments
Get-MgRoleManagementDirectoryRoleAssignmentSchedule -Filter "principalId eq '$myPrincipalId'" `
  | Select DirectoryScopeId,
            AssignmentType,
            @{
              name='Role';
              expression={
                (Get-MgDirectoryRole -Filter "RoleTemplateId eq '$($_.RoleDefinitionId)'").DisplayName
              }
            }
```


## Misc

- `*-AzureADMS*` commands in the `AzureADPreview` module connects to `https://graph.microsoft.com` as well, but the module does not work in PowerShell Core (v7)
