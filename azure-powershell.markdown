# Azure PowerShell


## Azure AD

```powershell
# install module
Install-Module AzureADPreview

# Login with basic auth
$AzureAdCred = Get-Credential
Connect-AzureAD -Credential $AzureAdCred

# If you need MFA, don't pass in `-Credential` option
Connect-AzureAD
```


## Account

```powershell
# login
Connect-AzAccount

# get current subscription id
(Get-AzContext).Subscription.Id

# get current logged-in user id
(Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id
```

## Azure AD PIM

```powershell
# find all related commands
Get-Command -Module AzureADPreview "*privileged*"

# get AAD PIM roles
Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId

# get role assignments for the specified user
Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" `
  -ResourceId $tenantId -Filter "subjectId eq '$uid'"
```
