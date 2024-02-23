# Azure PowerShell

- [On Linux/Mac](#on-linuxmac)
- [Login](#login)
- [Account](#account)
- [Resource groups](#resource-groups)
- [VM](#vm)
  - [Creating](#creating)
  - [Management](#management)
- [Azure AD](#azure-ad)


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

You can also login using a service principal (with password/certificate/federated workload credential) , managed identity

For example, to login using service principal and secret:

```powershell
$TenantId = "<tenant-id>"
$User = "<username>"
$PWord = ConvertTo-SecureString -String "<pass>" -AsPlainText -Force

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $Credential
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
