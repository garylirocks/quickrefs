# Microsoft Graph API

- [Overview](#overview)
- [Web experience](#web-experience)
- [REST](#rest)
- [PowerShell SDK](#powershell-sdk)
  - [Find Command](#find-command)
  - [Send an email](#send-an-email)
- [Other PowerShell modules](#other-powershell-modules)


## Overview

A unified REST API for all Microsoft Cloud services, including Azure AD, Office, Teams, Outlook, etc.

Could be accessed via REST endpoints or various SDKs.

## Web experience

- Microsoft Graph Explorer: https://developer.microsoft.com/en-us/graph/graph-explorer
- Managing Apps permissions: https://myapps.microsoft.com/


## REST

You could get an access token and call the REST endpoints directly

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

## PowerShell SDK

Install

```sh
Install-Module Microsoft.Graph

Get-Module Microsoft.Graph -ListAvailable
#     Directory: /home/gary/.local/share/powershell/Modules

# ModuleType Version    PreRelease Name                                PSEdition ExportedCommands
# ---------- -------    ---------- ----                                --------- ----------------
# Manifest   1.18.0                Microsoft.Graph                     Core,Desk
```

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
Get-MgGroup | Where-Object {$_.DisplayName -Like 'Ret*'}

# It's better to use "-Filter", it's more efficient
#   because the filtering happens on the server side
Get-MgGroup -Filter "startsWith(DisplayName, 'Ret')"
```

Get members of a group

```powershell
Get-MgGroupMember -GroupId $groupId | ForEach-Object { @{UserId=$_.Id} } | Get-MgUser -Property "DisplayName,Mail"

# Id DisplayName     Mail                          UserPrincipalName UserType
# -- -----------     ----                          ----------------- --------
#    Gary Li         gary@24g85s.onmicrosoft.com
#    Patti Fernandez PattiF@24g85s.onmicrosoft.com
#    Lee Gu          LeeG@24g85s.onmicrosoft.com
#    Miriam Graham   MiriamG@24g85s.onmicrosoft.cΓÇª
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


## Other PowerShell modules

Apart from the PowerShell SDK, there are other modules that work with AAD:

Commands in the `Az.Resources` module:

```powershell
Get-Command -Module Az.Resources -Noun AzAD*

# CommandType     Name                                               Version    Source
# -----------     ----                                               -------    ------
# ...
# Alias           Set-AzADServicePrincipal                           5.6.0      Az.Resources
# Alias           Set-AzADUser                                       5.6.0      Az.Resources
# Function        Get-AzADGroup                                      5.6.0      Az.Resources
# ...
```

Other `AzureAD*` modules

```powershell
Find-Module AzureAD*

# Version              Name                                Repository           Description
# -------              ----                                ----------           -----------
# 2.0.2.140            AzureAD                             PSGallery            Azure Active Directory V2 General Availability Module.…
# 2.0.2.149            AzureADPreview                      PSGallery            Azure Active Directory V2 Preview Module. …
# 2.1.1.0              AzureADHybridAuthenticationManagem… PSGallery            The Azure AD Hybrid Authentication Management module enables hybrid identity organizations (th…
# ...
```