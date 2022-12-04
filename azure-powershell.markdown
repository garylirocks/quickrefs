# Azure PowerShell

- [On Linux/Mac](#on-linuxmac)
- [Account](#account)
- [Resource groups](#resource-groups)
- [VM](#vm)
- [Azure AD](#azure-ad)
  - [PIM](#pim)


## On Linux/Mac

Windows include PowerShell, on Linux or Mac, you can use PowerShell Core

```sh
# start PowerShell
sudo pwsh

# install the Az module
Install-Module Az -AllowClobber

Import-Module Az
```


## Account

```powershell
# login
Connect-AzAccount

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

# stop vm
Stop-AzVM -Name $vm.Name -ResourceGroup $vm.ResourceGroupName

# remove vm (it doesn't cleanup related resources)
Remove-AzVM -Name $vm.Name -ResourceGroup $vm.ResourceGroupName
```

PowerShell script example, creating three VMs

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

Prepare

```powershell
# need this module
Install-Module AzureADPreview

# !! This does not work in PowerShell Core (v7)
# See https://github.com/PowerShell/PowerShell/issues/10473
Connect-AzureAD

# find all related commands
Get-Command -Module AzureADPreview "*privileged*"
```

Get definitions

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

Activate a role assignment

<div style="background: #efd9fd">
<em>NOTE: </em><br />
If the activation requires either <br />
  <ol>
    <li>ticket system/ticket number</li>
    <li>MFA</li>
  </ol>
Then you need to do it in the Portal
</div>


```powershell
$durationInHours = 2
$roleDefName = "Application Administrator"
$reason = "Business Justification for the role assignment"

$start = Get-Date
$end = $start.AddHours($durationInHours)
$roleDefId = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadRoles -ResourceId $tenantId -Filter "DisplayName eq '$roleDefName'").Id

$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$schedule.Type = "Once"
$schedule.StartDateTime = $start.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$schedule.endDateTime = $end.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

$tenantId = (Get-AzContext).Tenant.Id
$uid = (Get-AzADUser -UserPrincipalName (Get-AzContext).Account).Id

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
