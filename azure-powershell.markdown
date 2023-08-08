# Azure PowerShell

- [On Linux/Mac](#on-linuxmac)
- [Login](#login)
- [Account](#account)
- [Resource groups](#resource-groups)
- [VM](#vm)
  - [Creating](#creating)
  - [Management](#management)
- [Azure AD](#azure-ad)
  - [PIM](#pim)
    - [Azure resources](#azure-resources)
    - [AAD roles](#aad-roles)


## On Linux/Mac

Windows include PowerShell, on Linux or Mac, you can use PowerShell Core

```sh
# start PowerShell
sudo pwsh

# install the Az module
Install-Module Az -AllowClobber

Import-Module Az
```


## Login

The first step is always login

```powershell
Connect-AzAccount
```


## Account

```powershell
# list subscriptions
Get-AzSubscription

# select a subscription
Set-AzContext -Subscription "gary-default"

# get current subscription id
(Get-AzContext).Subscription.Id

# get current logged-in user id
(Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id
```


## Resource groups

```powershell
# get resource groups in the active subscription
Get-AzResourceGroup

# or show results in table format
Get-AzResourceGroup | Format-Table

# create a resource group
New-AzResourceGroup -Name <name> -Location <location>

# get resources
Get-AzResource -ResourceType Microsoft.Compute/virtualMachines
```


## VM

### Creating

```powershell
# create a VM
# 'Get-Credential' cmdlet will prompt you for username/password
New-AzVm -ResourceGroupName <resource-group-name>
  -Name "testvm-eus-01"
  -Credential (Get-Credential)
  -Location "East US"
  -Image UbuntuLTS
  -OpenPorts 22

# get a VM object
$vm = Get-AzVM -Name "testvm-eus-01" -ResourceGroupName my-RG

# show the object
$vm

# get a field
$vm.Location
# eastus
```

Creating three VMs

```powershell
# assign first param to a variable
param([string]$resourceGroup)

# prompt for username/password
$adminCredential = Get-Credential -Message "Enter a username and password for the VM administrator."

For ($i = 1; $i -le 3; $i++)
{
    $vmName = "ConferenceDemo" + $i
    Write-Host "Creating VM: " $vmName
    New-AzVm -ResourceGroupName $resourceGroup -Name $vmName -Credential $adminCredential -Image UbuntuLTS
}
```

Run the script by

```
./script.ps1 my-RG
```

### Management

```powershell
$vm = Get-AzVM -Name "testvm-eus-01" -ResourceGroupName my-RG

# resize vm
$vm.HardwareProfile.VmSize = "Standard_DS3_v2"
Update-AzVM -VM $vm -ResourceGroupName my-RG

# stop vm
Stop-AzVM -Name $vm.Name -ResourceGroup $vm.ResourceGroupName

# remove vm (it doesn't cleanup related resources)
Remove-AzVM -Name $vm.Name -ResourceGroup $vm.ResourceGroupName
```


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

### PIM

There are two related modules:
  - `Az.Resources`: for Azure Resource Manager roles, connects to `https://management.azure.com`
  - `AzureADPreview`: for Azure AD roles, cmdlets with different conventions:
    - `-AzureAD` connects to Azure AD graph endpoint `https://graph.windows.net`
    - `-AzureADMS` connects to Microsoft Graph endpoint `https://graph.microsoft.com`

#### Azure resources

**Get eligible role assignments or active role assignments**:

```powershell
$scope='<full-resource-id>' // FULL id required
$principal='xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

# get eligible ones
# - shows inherited permissions from upper scopes
# - shows assignment in sub scopes,
#   - if the scope is a subscription, like `/subscriptions/xxxx`, it shows assignment on children resource groups
#   - but if the scope is a management group like `/providers/Microsoft.Management/managementGroups/xxx`, it doesn't show assignements in children subscriptions
Get-AzRoleEligibilitySchedule -Scope $scope -Filter "principalId eq $principal" `
| Select-Object ScopeDisplayName,ScopeType,PrincipalDisplayName,PrincipalType,RoleDefinitionDisplayName,RoleDefinitionType,EndDateTime,Status `
| Format-Table

# Get active role assignments and who it's been eligible to (could be current user or a containing group):
Get-AzRoleAssignmentSchedule -Scope $scope -Filter "principalId eq $principal" `
| Select-Object ScopeDisplayName,ScopeType,PrincipalDisplayName,RoleDefinitionDisplayName,RoleDefinitionType,EndDateTime,AssignmentType,@{
    n='PIMRoleAssignedTo';
    e={(Get-AzRoleEligibilitySchedule -Scope $_.ScopeId -Name ($_.LinkedRoleEligibilityScheduleId -Split '/' | Select -Last 1)).PrincipalDisplayName}
}`
| Format-Table
```

Usable filters:

- `-Filter "principalId eq $principal"`
  - works for active assignments
  - **DOES NOT** work for a user if the eligible role assignments are on a group, not directly on the user
- `-Filter "asTarget()"` limit to current user/service principal, works even if the eligible assignment is via a group
- `-Filter "atScope()"` limit to specified scope, including inherited roles from ancestor scopes, excluding subscopes
- `-Filter "asTarget() and atScope()"` combined

**To activate a PIM role:**

<div style="background: #efd9fd; padding: 1em">
  <em>NOTE: </em><br />
    <ol>
      <li>You can specify ticket system/ticket number</li>
      <li>Scope could be
        <ul>
          <li>management group ("/providers/Microsoft.Management/managementGroups/mg-foo")</li>
          <li>subscription ("/subscriptions/xxxx-xxxx-xxxx-xxxx")</li>
          <li>resource group ("/subscriptions/xxxx-xxxx-xxxx-xxxx/resourceGroups/rg-foo")</li>
        </ul>
      </li>
      <li>Seems there is no easy way to "Deactivate" an assignment via script</li>
    </ol>
</div>

```powershell
$durationInHours = 1
$roleName = "Contributor"
$justification = "Discovery"
$ticketNumber = 'FOO-123'

$guid = (New-Guid).guid
$uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id
$startTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$roleId = (Get-AzRoleDefinition -Name $roleName).Id
$subscriptionId = ((Get-AzContext).Subscription).Id

$scope = "/subscriptions/${subscriptionId}"
$fullRoleDefId = "$scope/providers/Microsoft.Authorization/roleDefinitions/${roleId}"

New-AzRoleAssignmentScheduleRequest `
  -RequestType SelfActivate `
  -PrincipalId $uid `
  -Name $guid `
  -Scope $scope `
  -RoleDefinitionId $fullRoleDefId `
  -ScheduleInfoStartDateTime $startTime `
  -ExpirationDuration "PT${durationInHours}H" `
  -ExpirationType AfterDuration `
  -Justification $justification `
  -TicketNumber $ticketNumber `
  -TicketSystem JIRA
```

#### AAD roles

<div style="background: #efd9fd; padding: 1em">
  <em>NOTE: </em><br />
  If the activation requires either <br />
    <ol>
      <li>ticket system/ticket number</li>
      <li>MFA</li>
    </ol>
  Then you need to do it in the Portal
</div>

- Prepare

  ```powershell
  # need this module
  Install-Module AzureADPreview

  # !! This does not work in PowerShell Core (v7)
  # See https://github.com/PowerShell/PowerShell/issues/10473
  Connect-AzureAD

  # find all related commands
  Get-Command  -Module AzureADPreview -Noun *privileged* -verb 'get'

  # CommandType     Name                                               Version    Source
  # -----------     ----                                               -------    ------
  # Cmdlet          Get-AzureADMSPrivilegedResource                    2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleAssignment              2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleAssignmentRequest       2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleDefinition              2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADMSPrivilegedRoleSetting                 2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADPrivilegedRole                          2.0.2.149  AzureADPreview
  # Cmdlet          Get-AzureADPrivilegedRoleAssignment                2.0.2.149  AzureADPreview
  ```

- Get definitions

  ```powershell
  $tenantId = (Get-AzContext).Tenant.Id
  $uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id

  # get all AAD roles
  Get-AzureADMSPrivilegedRoleDefinition `
    -ProviderId aadRoles `
    -ResourceId $tenantId

  # get role assignments for the specified user
  Get-AzureADMSPrivilegedRoleAssignment `
    -ProviderId "aadRoles" `
    -ResourceId $tenantId `
    -Filter "subjectId eq '$uid'"
  ```

- Activate a role assignment

  ```powershell
  $durationInHours = 2
  $roleDefName = "Application Administrator"
  $reason = "Business Justification for the role assignment"
  $tenantId = (Get-AzContext).Tenant.Id
  $uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id

  $start = Get-Date
  $end = $start.AddHours($durationInHours)
  $roleDefId = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId -Filter "DisplayName eq '$roleDefName'").Id

  $schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
  $schedule.Type = "Once"
  $schedule.StartDateTime = $start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
  $schedule.endDateTime = $end.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

  Open-AzureADMSPrivilegedRoleAssignmentRequest `
    -ProviderId 'aadRoles' `
    -Type 'UserAdd' `
    -AssignmentState 'Active' `
    -ResourceId $tenantId `
    -RoleDefinitionId $roleDefId `
    -SubjectId $uid `
    -Schedule $schedule `
    -Reason $reason
  ```
